import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/api/lucky_api.dart';
import '../models/chat_ui_model.dart';
import '../models/conversation.dart'; // 引入 Request/Response 模型
import '../services/database/local_database_service.dart';

// 1. 状态类
class ChatListState {
  final List<ChatUiModel> messages;
  final bool isLoadingMore;
  final bool isInitializing;
  final bool hasMore;

  ChatListState({
    this.messages = const [],
    this.isLoadingMore = false,
    this.isInitializing = false,
    this.hasMore = true,
  });

  ChatListState copyWith({
    List<ChatUiModel>? messages,
    bool? isLoadingMore,
    bool? isInitializing,
    bool? hasMore,
  }) {
    return ChatListState(
      messages: messages ?? this.messages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isInitializing: isInitializing ?? this.isInitializing,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class ChatViewModel extends StateNotifier<ChatListState> {
  final String conversationId;
  final LocalDatabaseService _dbService = LocalDatabaseService();

  StreamSubscription? _subscription;
  int _currentLimit = 50;

  ChatViewModel(this.conversationId) : super(ChatListState()) {
    _init();
  }

  void _init() {
    // 1. 监听本地 DB (保证有缓存立马显示)
    _subscribeToStream();
    // 2. 升级：执行增量同步逻辑，而不是简单的拉取最新
    performIncrementalSync();
  }

  void _subscribeToStream() {
    _subscription?.cancel();
    _subscription = _dbService.watchMessages(conversationId, limit: _currentLimit).listen((msgs) {
      if (mounted) {
        state = state.copyWith(messages: msgs);
      }
    });
  }

  // ============================================================
  //  核心：增量同步算法 (空洞检测 + 递归补齐)
  // ============================================================

  Future<void> performIncrementalSync() async {
    if (!mounted) return;

    // 如果已经在初始化中，直接返回，防止重复请求 API
    if(state.isInitializing) return;

    state = state.copyWith(isInitializing: true);


    try {
      // 1. 查账：获取本地最后一条“正式报纸”的编号
      final localMaxSeqId = await _dbService.getMaxSeqId(conversationId);

      // 2. 问询：拉取服务器最新的第一页
      final response = await Api.chatMessagesApi(
        MessageHistoryRequest(
          conversationId: conversationId,
          pageSize: 20, // 增量对账不需要一次拉50条，20条足够衔接
          cursor: null,
        ),
      );

      if (!mounted) return;

      if (response.list.isNotEmpty) {
        // 3. 对比：服务器最顶端的编号
        final serverMaxSeqId = response.list.first.seqId ?? 0;

        // 4. 决策：是否存在空洞？
        if (localMaxSeqId != null && serverMaxSeqId > localMaxSeqId) {
          // 情况 A：发现空洞！
          debugPrint(" [Sync] 发现消息空洞: 本地 $localMaxSeqId, 服务器 $serverMaxSeqId");

          final oldestInThisPage = response.list.last.seqId ?? 0;

          if (oldestInThisPage <= localMaxSeqId) {
            // A-1: 缝合成功。这一页已经覆盖了本地缺失的所有消息
            await _saveApiMessages(response.list);
          } else {
            // A-2: 鸿沟太大。这一页拉完还没追上本地记录，需要递归向后挖
            debugPrint(" [Sync] 空洞过大，启动递归补齐机制...");
            await _recursiveSyncGap(localMaxSeqId, oldestInThisPage);
            // 补齐中间的后，再存顶部的这一页
            await _saveApiMessages(response.list);
          }
        } else {
          // 情况 B：无空洞或本地为空（冷启动/重装），直接存入
          await _saveApiMessages(response.list);
        }
      }

      // 如果数据不足一页，标记没有更多历史
      if (response.list.length < 20) {
        state = state.copyWith(hasMore: false);
      }
    } catch (e) {
      debugPrint(" [Sync] 增量同步失败: $e");
    } finally {
      if (mounted) state = state.copyWith(isInitializing: false);
    }
  }

  /// 辅助：递归向后追溯，直到衔接到 targetSeqId 为止
  Future<void> _recursiveSyncGap(int targetSeqId, int currentCursor) async {
    debugPrint("  [Sync] 正在抓取 cursor 之前的消息: $currentCursor");
    final response = await Api.chatMessagesApi(
      MessageHistoryRequest(
        conversationId: conversationId,
        pageSize: 50,
        cursor: currentCursor,
      ),
    );

    if (response.list.isEmpty) return;

    await _saveApiMessages(response.list);

    final oldestSeq = response.list.last.seqId ?? 0;
    // 如果这页的最老一条还是比本地大，说明还没追上，继续递归
    if (oldestSeq > targetSeqId) {
      await _recursiveSyncGap(targetSeqId, oldestSeq);
    } else {
      debugPrint(" [Sync] 鸿沟已完全缝合！");
    }
  }

  /// 内部工具：将 API 消息转换为 UI 模型并入库
  Future<void> _saveApiMessages(List<ChatMessage> apiMsgs) async {
    final uiMsgs = apiMsgs.map((m) => ChatUiModelMapper.fromApiModel(m, conversationId)).toList();
    await _dbService.saveMessages(uiMsgs);
  }

  // ============================================================
  //  上拉加载更多 (保持原有的历史拉取逻辑)
  // ============================================================

  Future<void> loadMore() async {
    if (state.messages.length < 20) {
      state = state.copyWith(hasMore: false);
      return;
    }

    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    // 1. 先尝试扩大本地窗口
    _currentLimit += 50;
    _subscribeToStream();

    await Future.delayed(const Duration(milliseconds: 100));
    final newLength = state.messages.length;

    // 2. 如果本地存货不够，去服务器掏
    if (newLength < _currentLimit) {
      await _fetchHistoryFromApi();
    } else {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> _fetchHistoryFromApi() async {
    try {
      if (state.messages.isEmpty) {
        state = state.copyWith(isLoadingMore: false);
        return;
      }

      final oldestMsg = state.messages.last;
      final cursor = oldestMsg.seqId;

      if (cursor == null) {
        state = state.copyWith(isLoadingMore: false);
        return;
      }

      final response = await Api.chatMessagesApi(
        MessageHistoryRequest(
          conversationId: conversationId,
          pageSize: 50,
          cursor: cursor,
        ),
      );

      if (response.list.isEmpty) {
        state = state.copyWith(hasMore: false, isLoadingMore: false);
      } else {
        await _saveApiMessages(response.list);
        if (response.list.length < 50) {
          state = state.copyWith(hasMore: false, isLoadingMore: false);
        } else {
          state = state.copyWith(isLoadingMore: false);
        }
      }
    } catch (e) {
      debugPrint(" 拉取历史失败: $e");
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final chatViewModelProvider = StateNotifierProvider.family.autoDispose<ChatViewModel, ChatListState, String>(
      (ref, conversationId) {
    return ChatViewModel(conversationId);
  },
);