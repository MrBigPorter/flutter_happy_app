import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/core/api/http_client.dart';
import 'package:flutter_app/core/services/ai/sse_types.dart';
import 'package:flutter_app/core/services/ai/sse_client.dart';
import 'package:flutter_app/core/services/ai/sse_client_v2.dart';
import 'package:flutter_app/core/store/ai_chat/ai_chat_state.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/repository/message_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AI 对话 ID 前缀，用于与 IM 普通对话区分
/// ChatPage 根据 conversationId 判断走 AI 还是 Socket
const kAiConversationId = 'ai_chat';
const kSessionIdPrefKey = 'ai_session_id';

/// AI 聊天 ViewModel
///
/// 管理 SSE 流生命周期 + 本地 DB 持久化。
/// SSE done 后调 MessageRepository 存本地，冷启动从本地恢复
///
/// 生活类比：收银员手中的小票本
///   SSE 流期间 = 草稿本上记（内存）
///   SSE done   = 誊到账本上（本地 DB）
///   冷启动     = 翻开账本看历史
class AiChatViewModel extends StateNotifier<AiChatState> {
  final MessageRepository _repo;
  final String _conversationId;
  SseClient? _sseClient;
  SseClientV2? _sseClientV2;
  StreamSubscription<SseEvent>? _subscription;

  /// 切换到两阶段 GET 协议（true = 新协议，false = 老 POST 协议）
  /// 稳定后设为 true，确认没问题后移除老代码
  final bool useV2Protocol;

  /// SSE client 已内置 30ms token 间隔，
  /// ViewModel 只需直接更新 state，无需额外 buffer/timer/queue

  AiChatViewModel(this._repo, this._conversationId, {this.useV2Protocol = false, this.onMessagesPersisted, this.onTransfer}) : super(AiChatState.initial());

  /// 持久化完成后的回调（用于刷新对话列表的 AI 条目预览）
  final VoidCallback? onMessagesPersisted;

  /// 转人工回调 — SSE 收到 transfer 事件后触发，ChatPage 据此切换模式
  VoidCallback? onTransfer;

  /// 初始化：从本地 DB 恢复历史消息 + 恢复 sessionId
  Future<void> init() async {
    // 1. 从 SharedPreferences 恢复 sessionId
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(kSessionIdPrefKey);
    if (saved != null && saved.isNotEmpty) {
      state = state.copyWith(sessionId: saved);
    } else {
      await prefs.setString(kSessionIdPrefKey, state.sessionId);
    }

    // 2. 从本地 DB 加载历史 AI 消息并显式排序
    final history = await _repo.getHistory(
      conversationId: _conversationId,
      limit: 100,
    );
    if (history.isNotEmpty) {
      // 显式按 createdAt 降序排列（最新在前），不依赖 DB 查询顺序
      final sorted = List<ChatUiModel>.from(history)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(messages: sorted);
    }
  }

  /// 发送消息 — 触发 SSE 流
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty || state.isReceiving) return;

    // 1. 添加用户消息到内存，同时清除旧报错
    state = state.addUserMessage(
      content: message,
      conversationId: _conversationId,
    );
    state = state.copyWith(clearError: true);
    // 让步事件循环，让 Flutter 渲染用户消息
    // 16ms ≈ 1 frame at 60fps，确保消息气泡先渲染出来
    await Future.delayed(const Duration(milliseconds: 16));

    // 2. 获取 JWT token
    final token = await Http.getToken();
    if (token == null) {
      state = state.setError('请先登录');
      return;
    }

    if (useV2Protocol) {
      await _sendMessageV2(message, token);
    } else {
      await _sendMessageV1(message, token);
    }
  }

  /// 老协议（V1）：POST /chat-stream → SSE 流
  Future<void> _sendMessageV1(String message, String token) async {
    _sseClient?.dispose();
    _sseClient = SseClient();

    _subscription?.cancel();
    _subscription = _sseClient!.events.listen(
      _onSseEvent,
      onError: (error) {
        debugPrint('[typewriter] SSE stream error: $error');
        state = state.setError('抱歉，出了点问题，请重试');
      },
      onDone: () {
        if (state.isReceiving && !state.isStreamComplete) {
          state = state.completeAiMessage();
        }
      },
      cancelOnError: false,
    );

    await _sseClient!.sendMessage(
      message: message,
      sessionId: state.sessionId,
      token: token,
    );
  }

  /// 新协议（V2）：POST /chat → 拿 streamId → GET /chat/stream/:id → SSE
  Future<void> _sendMessageV2(String message, String token) async {
    try {
      // ── 阶段 1：POST /chat 注册消息，获取 streamId ──
      final response = await Http.rawDio.post(
        '/api/v1/ai/customer/chat',
        data: {'message': message, 'sessionId': state.sessionId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // rawDio 返回原始响应，NestJS 包了一层 { code, message, data }
      final streamId = response.data?['data']?['streamId'] as String?;
      if (streamId == null || streamId.isEmpty) {
        state = state.setError('获取会话失败，请重试');
        return;
      }

      // ── 阶段 2：连 SSE 流 ──
      _sseClientV2?.dispose();
      // 条件导出：
      //   - 原生 → sse_client_io.dart（dart:io GET）
      //   - Web  → sse_client_web.dart（EventSource）
      _sseClientV2 = SseClientV2();

      _subscription?.cancel();
      _subscription = _sseClientV2!.events.listen(
        _onSseEvent,
        onError: (error) {
          debugPrint('[typewriter] SSE stream error: $error');
          state = state.setError('抱歉，出了点问题，请重试');
        },
        onDone: () {
          if (state.isReceiving && !state.isStreamComplete) {
            state = state.completeAiMessage();
          }
        },
        cancelOnError: false,
      );

      await _sseClientV2!.connect(
        streamId: streamId,
        token: token,
      );
    } on DioException catch (e) {
      debugPrint('[typewriter] POST /chat error: ${e.message}');
      final msg = e.response?.data?['error']?.toString() ?? '连接失败，请检查网络';
      state = state.setError(msg);
    } catch (e) {
      debugPrint('[typewriter] POST /chat unknown: $e');
      state = state.setError('抱歉，出了点问题，请重试');
    }
  }

  /// 处理 SSE 事件 — 直接更新 state，无 buffer/timer/queue
  void _onSseEvent(SseEvent event) {
    switch (event.type) {
      case SseEventType.token:
        if (state.currentAiMessageId.isEmpty) {
          state = state.startAiMessage(conversationId: _conversationId);
          state = state.copyWith(statusText: '');
        }
        // 直接追加到 state，SSE client 内置了 30ms 间隔，
        // 确保 Flutter 有时间渲染每个 token
        state = state.appendToken(event.data['content'] as String? ?? '');
        break;

      case SseEventType.step:
        if (state.currentAiMessageId.isEmpty) {
          // 只标记 receiving，不创建占位消息气泡
          // 等第一个 token 到了才真正创建 AI 消息
          state = state.copyWith(isReceiving: true, clearError: true);
        }
        // 展平：把 step 事件内层 data 提到顶层，与 token 格式一致
        final flatData = Map<String, dynamic>.from(event.data);
        if (flatData['data'] is Map) {
          flatData.addAll(flatData['data'] as Map<String, dynamic>);
        }
        flatData.remove('data');
        _handleStepEvent(SseEvent(type: SseEventType.step, data: flatData));
        break;

      case SseEventType.done:
        debugPrint('[typewriter] done event, completing message');
        state = state.completeAiMessage();
        _persistMessages();
        break;

      case SseEventType.transfer:
        debugPrint('[typewriter] transfer event, handing off to human');
        // 完成当前 AI 消息并持久化
        if (state.currentAiMessageId.isNotEmpty) {
          state = state.completeAiMessage();
        }
        _persistMessages();
        // 触发转人工回调（ChatPage 收到后切 Socket 模式）
        onTransfer?.call();
        break;

      case SseEventType.error:
        // 记录原始错误便于排查
        debugPrint('[typewriter] SSE error: ${event.data['content']}');
        // 前端只显示友好提示，不暴露后端技术细节
        state = state.setError('抱歉，出了点问题，请重试');
        break;
    }
  }

  /// 处理 step 事件（thinking / tool_start / tool_end）
  /// 注意：event.data 已经被 _onSseEvent 展平过，data.data 的子段已提到顶层
  void _handleStepEvent(SseEvent event) {
    final step = event.data['step'] as String? ?? '';
    final tool = event.data['tool'] as String?;
    final content = event.data['content'] as String?;

    switch (step) {
      case 'thinking':
        // 只有后端传了具体内容才显示，避免空包
        if (content != null) state = state.copyWith(statusText: content);
        break;
      case 'tool_start':
        // tool 是后端传的用户友好描述（如 "搜索订单中"），有值才显示
        if (tool != null) state = state.copyWith(statusText: tool);
        break;
      case 'tool_end':
        state = state.copyWith(statusText: '');
        break;
    }
  }

  /// SSE done 后，把本轮消息持久化到本地 DB
  Future<void> _persistMessages() async {
    // 取最新两条（messages[0] = AI 回复, messages[1] = 用户消息）
    if (state.messages.length < 2) return;

    final userMsg = state.messages[1];
    final aiMsg = state.messages[0];

    await _repo.saveBatch([userMsg, aiMsg]);
    // 持久化后刷新对话列表（更新 AI 条目的最后消息预览）
    onMessagesPersisted?.call();
  }

  /// 取消当前 SSE 流
  void cancelStream() {
    _subscription?.cancel();
    _sseClient?.cancel();
    _sseClientV2?.cancel();
    if (state.isReceiving) {
      state = state.setError('已取消');
    }
  }

  /// 清空对话
  Future<void> clearMessages() async {
    cancelStream();
    // 重置 sessionId
    final prefs = await SharedPreferences.getInstance();
    final newId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString(kSessionIdPrefKey, newId);

    // 清除本地 DB 中的 AI 消息
    await _repo.clearConversationHistory(_conversationId);

    state = AiChatState.initial().copyWith(sessionId: newId);
  }

  /// 重试最近一次失败的消息
  Future<void> retry() async {
    final lastUserMsg = state.messages.firstWhere(
      (m) => m.isMe,
      orElse: () => state.messages.first,
    );
    if (lastUserMsg.content.isEmpty) return;

    // 移除最新两条（AI 失败回复 + 用户消息 messages[0]=AI, [1]=user）
    final msgs = [...state.messages];
    if (msgs.length >= 2) {
      msgs.removeRange(0, 2);
    }
    state = state.copyWith(messages: msgs, error: null);
    await sendMessage(lastUserMsg.content);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _sseClient?.dispose();
    _sseClientV2?.dispose();
    super.dispose();
  }
}

/// Provider — conversationId 驱动
final aiChatViewModelProvider = StateNotifierProvider.family.autoDispose<
    AiChatViewModel, AiChatState, String>((ref, conversationId) {
  final repo = ref.read(messageRepositoryProvider);
  final viewModel = AiChatViewModel(
    repo,
    conversationId,
    useV2Protocol: true,
  );
  Future.microtask(() => viewModel.init());
  return viewModel;
});
