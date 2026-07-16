import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'package:flutter_app/core/services/socket/socket_service.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_app/core/api/lucky_api.dart';
import 'package:flutter_app/core/constants/socket_events.dart';

import '../models/conversation.dart';
import '../providers/chat_view_model.dart';
import '../repository/message_repository.dart';

class ChatEventHandler {
  final String conversationId;
  final Ref _ref;
  final SocketService _socketService;
  final String _currentUserId;

  StreamSubscription? _msgSub, _readStatusSub, _recallSub, _aiSub;
  StreamSubscription? _debounceSub;

  final _readReceiptSubject = PublishSubject<void>();
  final Set<String> _processedMsgIds = {};

  int _maxReadSeqId = 0;

  // DirectChatSettingsPage [关键修复 1] 销毁标记位，防止异步回调导致崩溃
  bool _isDisposed = false;

  ChatEventHandler(
      this.conversationId,
      this._ref,
      this._socketService,
      this._currentUserId,
      );

  void init() {
    debugPrint("💬 [ChatEventHandler] Initializing for conversation: $conversationId");
    debugPrint("💬 [ChatEventHandler] Current user ID: $_currentUserId");
    debugPrint("💬 [ChatEventHandler] Socket service available: ${_socketService != null}");
    debugPrint("💬 [ChatEventHandler] Socket connected: ${_socketService?.isConnected}");
    
    _setupSubscriptions();
    _setupReadReceiptDebounce();
    _setupJoinRoomLogic();

    Future.microtask(() => markAsRead());
    debugPrint("💬 [ChatEventHandler] Initialization completed");
  }

  void dispose() {
    debugPrint("[ChatEventHandler] Disposing: $conversationId");
    // DirectChatSettingsPage [关键修复 2] 立即设为 true，阻断后续异步执行
    _isDisposed = true;

    try {
      _socketService.socket?.off('connect');
      _socketService.socket?.emit(SocketEvents.leaveChat, {
        'conversationId': conversationId,
      });
    } catch (_) {}

    _msgSub?.cancel();
    _readStatusSub?.cancel();
    _recallSub?.cancel();
    _aiSub?.cancel();
    _debounceSub?.cancel();
    _readReceiptSubject.close();
  }

  // ===========================================================================
  // Join Room & Socket Logic
  // ===========================================================================

  void _setupJoinRoomLogic() {
    if (_isDisposed) return;
    final socket = _socketService.socket;

    socket?.on('connect', (_) {
      if (_isDisposed) return;
      debugPrint(" [WS] Socket reconnected, re-joining room: $conversationId");
      _joinRoom(triggerSync: true);
    });

    if (socket?.connected == true) {
      _joinRoom(triggerSync: false);
    }
  }

  void _joinRoom({bool triggerSync = false}) {
    if (_isDisposed) return;
    try {
      _socketService.socket?.emit(SocketEvents.joinChat, {
        'conversationId': conversationId,
      });

      if (triggerSync) {
        Future.microtask(() {
          if (_isDisposed) return;
          try {
            final notifier = _ref.read(chatViewModelProvider(conversationId).notifier);
            notifier.performIncrementalSync();
          } catch (e) {
            debugPrint(" [WS-Path] Trigger sync failed: $e");
          }
        });
      }
    } catch (e) {
      debugPrint(" [WS] Join room failed: $e");
    }
  }

  void _setupSubscriptions() {
    _msgSub = _socketService.chatMessageStream.listen(_onSocketMessage);
    _readStatusSub = _socketService.readStatusStream.listen(_onReadStatusUpdate);
    _recallSub = _socketService.recallEventStream.listen(_onMessageRecalled);
    _aiSub = _socketService.aiEventStream.listen(_onAiEvent);
  }

  // ===========================================================================
  // Event Handling
  // ===========================================================================

  void _onSocketMessage(Map<String, dynamic> data) async {
    if (_isDisposed) return;
    final msg = SocketMessage.fromJson(data);

    if (msg.conversationId != conversationId) return;

    // 允许通话结束系统消息通过 (type 99)，但跳过已读上报
    // 通话结束消息是系统消息，不需要触发已读上报
    if (msg.type == 99) {
      // 通话结束系统消息直接返回，不触发已读上报逻辑
      return;
    }

    if (msg.senderId != _currentUserId) {
      if (!_readReceiptSubject.isClosed) {
        _readReceiptSubject.add(null);
      }
      await LocalDatabaseService().clearUnreadCount(conversationId);
    }
  }

  void _onReadStatusUpdate(SocketReadEvent event) async {
    if (_isDisposed) return;
    if (event.lastReadSeqId > _maxReadSeqId) {
      _maxReadSeqId = event.lastReadSeqId;
      await LocalDatabaseService().markMessagesAsRead(conversationId, _maxReadSeqId);
    }
  }

  void _onMessageRecalled(SocketRecallEvent event) async {
    if (_isDisposed) return;
    if (event.conversationId != conversationId) return;
    final tip = event.isSelf ? "You unsent a message" : "This message was unsent";
    await LocalDatabaseService().doLocalRecall(event.messageId, tip);
    _updateListSnapshot(tip, DateTime.now().millisecondsSinceEpoch);
  }

  /// AI 回复累积 buffer（Socket `ai_token` 累积，`ai_done` 后写 DB）
  String _aiResponseBuffer = '';

  void _onAiEvent(Map<String, dynamic> payload) {
    if (_isDisposed) return;
    final type = payload['type'] as String?;
    final data = payload['data'] as Map<String, dynamic>?;
    if (type == null || data == null) return;

    switch (type) {
      case SocketEvents.aiToken:
        final token = data['content'] as String? ?? '';
        _aiResponseBuffer += token;
        debugPrint('[ChatEventHandler] AI token: "$token" (buffer=${_aiResponseBuffer.length} chars)');
        break;

      case SocketEvents.aiDone:
        debugPrint('[ChatEventHandler] AI done, saving ${_aiResponseBuffer.length} chars to DB');
        _saveAiMessage(_aiResponseBuffer);
        _aiResponseBuffer = '';
        break;

      case SocketEvents.aiTransfer:
        debugPrint('[ChatEventHandler] AI transfer requested');
        _saveAiMessage(_aiResponseBuffer);
        _aiResponseBuffer = '';
        _updateListSnapshot('Transferred to human agent', DateTime.now().millisecondsSinceEpoch);
        break;

      case SocketEvents.aiError:
        final error = data['content'] as String? ?? 'AI error';
        debugPrint('[ChatEventHandler] AI error: $error');
        _aiResponseBuffer = '';
        _updateListSnapshot('AI service error', DateTime.now().millisecondsSinceEpoch);
        break;
    }
  }

  /// 把 AI 完整回复写入本地 DB（供 ChatViewModel 的 DB 流消费）
  Future<void> _saveAiMessage(String content) async {
    if (content.isEmpty) return;
    if (_isDisposed) return;
    try {
      await LocalDatabaseService().saveAiMessage(
        conversationId: conversationId,
        content: content,
      );
    } catch (e) {
      debugPrint('[ChatEventHandler] Failed to save AI message: $e');
    }
  }

  // ===========================================================================
  // Read Receipt Logic
  // ===========================================================================

  void _setupReadReceiptDebounce() {
    _debounceSub = _readReceiptSubject
        .debounceTime(const Duration(milliseconds: 500))
        .listen((_) {
      if (_isDisposed) return;
      markAsRead();
    });
  }

  Future<void> markAsRead() async {
    if (_isDisposed) return;

    try {
      // 1. UI 乐观更新
      _ref.read(conversationListProvider.notifier).clearUnread(conversationId);

      // 2. 获取最大 SeqId
      final maxSeqId = await LocalDatabaseService().getMaxSeqId(conversationId);

      // DirectChatSettingsPage [关键修复 4] 中途拦截：查数据库可能耗时，在此期间可能已销毁
      if (_isDisposed) return;

      await LocalDatabaseService().markMessagesAsRead(conversationId, maxSeqId ?? 0);

      if (maxSeqId != null) {
        // DirectChatSettingsPage [关键修复 5] 发起 Api 前检查会话是否还存在（解决被踢后上报 403 问题）
        final conversation = await _ref.read(messageRepositoryProvider).getConversation(conversationId);
        if (conversation == null || _isDisposed) return;

        await Api.messageMarkAsReadApi(
          MessageMarkReadRequest(
            conversationId: conversationId,
            maxSeqId: maxSeqId,
          ),
        );
      }
    } catch (e) {
      // DirectChatSettingsPage [关键修复 6] 销毁期间的错误静默处理，避免日志飘红
      if (_isDisposed) return;
      debugPrint(" [MarkRead] Read report failed: $e");
    }
  }

  void _updateListSnapshot(String text, int time) {
    if (_isDisposed) return;
    try {
      _ref.read(conversationListProvider.notifier).updateLocalItem(
        conversationId: conversationId,
        lastMsgContent: text,
        lastMsgTime: time,
      );
    } catch (_) {}
  }
}