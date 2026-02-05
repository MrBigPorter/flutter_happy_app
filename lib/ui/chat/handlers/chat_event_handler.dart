import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'package:flutter_app/core/services/socket/socket_service.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_app/core/api/lucky_api.dart';
import 'package:flutter_app/core/constants/socket_events.dart';

import '../models/conversation.dart';
import '../providers/chat_view_model.dart';

class ChatEventHandler {
  final String conversationId;
  final Ref _ref;
  final SocketService _socketService;
  final String _currentUserId;

  StreamSubscription? _msgSub, _readStatusSub, _recallSub;

  //  优化 1: 使用 BehaviorSubject 或 PublishSubject 做防抖
  final _readReceiptSubject = PublishSubject<void>();
  final Set<String> _processedMsgIds = {};

  int _maxReadSeqId = 0;

  ChatEventHandler(
      this.conversationId,
      this._ref,
      this._socketService,
      this._currentUserId,
      );

  void init() {

    _setupSubscriptions();
    _setupReadReceiptDebounce();
    _setupJoinRoomLogic();

    Future.microtask(() => markAsRead());

  }

  void dispose() {
    debugPrint(" [ChatEventHandler] 销毁: $conversationId");

    try {
      _socketService.socket?.off('connect');
      // 离开房间
      _socketService.socket?.emit(SocketEvents.leaveChat, {
        'roomId': conversationId,
      });
    } catch (_) {}

    _msgSub?.cancel();
    _readStatusSub?.cancel();
    _recallSub?.cancel();
    _readReceiptSubject.close();
  }

  // ===========================================================================
  // 进房逻辑
  // ===========================================================================

  void _setupJoinRoomLogic() {
    final socket = _socketService.socket;

    socket?.on('connect', (_) {
      debugPrint(" [WS] Socket 重连成功，重新进房: $conversationId");
      _joinRoom(triggerSync: true);
    });

    if (socket?.connected == true) {
      _joinRoom(triggerSync: false);
    }
  }

  void _joinRoom({bool triggerSync = false}) {
    try {
      _socketService.socket?.emit(SocketEvents.joinChat, {
        'roomId': conversationId,
      });

      // 只有明确要求同步时（例如重连），才去调用 ViewModel
      if (triggerSync) {
        Future.microtask(() {
          try {
            final notifier = _ref.read(
              chatViewModelProvider(conversationId).notifier,
            );
            notifier.performIncrementalSync();
          } catch (e) {
            debugPrint(" [WS-Path] 触发同步失败: $e");
          }
        });
      }
    } catch (e) {
      debugPrint(" [WS] 进房失败: $e");
    }
  }

  // ===========================================================================
  //  Socket 监听
  // ===========================================================================

  void _setupSubscriptions() {
    _msgSub = _socketService.chatMessageStream.listen(_onSocketMessage);
    _readStatusSub = _socketService.readStatusStream.listen(_onReadStatusUpdate);
    _recallSub = _socketService.recallEventStream.listen(_onMessageRecalled);
  }

  // ===========================================================================
  //  事件处理
  // ===========================================================================

  void _onSocketMessage(Map<String, dynamic> data) async {
    final msg = SocketMessage.fromJson(data);

    // 1. 基础过滤
    if (msg.conversationId != conversationId ||
        _processedMsgIds.contains(msg.id)) return;

    // 2. 标记处理
    _processedMsgIds.add(msg.id);
    if (_processedMsgIds.length > 100) _processedMsgIds.remove(_processedMsgIds.first);

    // 3. 存入数据库 (UI 监听流会自动更新)
    // 先转 UI 模型
    var uiMsg = ChatUiModelMapper.fromApiModel(
      ChatMessage(
        id: msg.id,
        content: msg.content,
        type: msg.type,
        seqId: msg.seqId,
        createdAt: msg.createdAt,
        isSelf: false,
        meta: msg.meta,
        sender: msg.sender != null ? ChatSender( // 确保 sender 不为空
            id: msg.sender!.id,
            nickname: msg.sender!.nickname,
            avatar: msg.sender!.avatar
        ) : null,
      ),
      conversationId,
      _currentUserId,
    );

    await LocalDatabaseService().saveMessage(uiMsg);

    // [Hot Read 核心优化]
    // 只要收到别人的消息，且 Handler 存活，就视为“正在阅读”
    // 我们把生命周期判断下沉到 markAsRead 里，这里只负责“触发意图”
    if (msg.senderId != _currentUserId) {
      _readReceiptSubject.add(null);
    }
  }

  void _onReadStatusUpdate(SocketReadEvent event) async {
    if (event.conversationId != conversationId || event.readerId == _currentUserId) return;

    if (event.lastReadSeqId > _maxReadSeqId) {
      _maxReadSeqId = event.lastReadSeqId;
      await LocalDatabaseService().markMessagesAsRead(
        conversationId,
        _maxReadSeqId,
      );
    }
  }

  void _onMessageRecalled(SocketRecallEvent event) async {
    if (event.conversationId != conversationId) return;
    final tip = event.isSelf ? "You unsent a message" : "This message was unsent";
    await LocalDatabaseService().doLocalRecall(event.messageId, tip);
    _updateListSnapshot(tip, DateTime.now().millisecondsSinceEpoch);
  }

  // ===========================================================================
  //  已读回执逻辑 (核心闭环)
  // ===========================================================================

  void _setupReadReceiptDebounce() {
    //  防抖时间：500ms
    // 这意味着如果对方 0.1s 发一条，连发 10 条，我们只会在最后一条发完后调用一次 API
    _readReceiptSubject
        .debounceTime(const Duration(milliseconds: 500))
        .listen((_) {
      markAsRead();
    });
  }

  /// 标记已读 (全能入口)
  /// 支持 Cold Read (进房), Warm Read (切回), Hot Read (在线)
  Future<void> markAsRead() async {
    // 1. 省流防守：如果 App 在后台，不发已读
    // (逻辑：用户都没看屏幕，不能算已读)
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }

    try {
      // 2. 乐观更新 (Optimistic Update)
      // 先把本地红点消了，让用户觉得“秒回”
      // 这一步会更新数据库 Conversation 表，触发 GlobalUnreadProvider
      _ref.read(conversationListProvider.notifier).clearUnread(conversationId);

      // 3. 查账 (获取本地最大 SeqId)
      // 我们告诉后端：“这个 ID 之前的所有消息我都看过了”
      final maxSeqId = await LocalDatabaseService().getMaxSeqId(conversationId);

      if (maxSeqId != null) {
        // 4. 发送 API 请求
        await Api.messageMarkAsReadApi(
          MessageMarkReadRequest(
            conversationId: conversationId,
            maxSeqId: maxSeqId,
          ),
        );
        debugPrint(" [MarkRead] 已读上报成功: maxSeqId=$maxSeqId");
      }
    } catch (e) {
      debugPrint(" [MarkRead] 已读上报失败: $e");
    }
  }

  void _updateListSnapshot(String text, int time) {
    try {
      _ref.read(conversationListProvider.notifier).updateLocalItem(
        conversationId: conversationId,
        lastMsgContent: text,
        lastMsgTime: time,
      );
    } catch (_) {}
  }
}