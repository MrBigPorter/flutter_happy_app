import 'dart:async';
import 'package:flutter/widgets.dart'; // 包含 debugPrint
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
    debugPrint("🔵 [ChatEventHandler] 初始化: $conversationId");

    _setupSubscriptions();
    _setupReadReceiptDebounce();

    _setupJoinRoomLogic();
  }

  void dispose() {
    debugPrint("🔴 [ChatEventHandler] 销毁: $conversationId");

    // 移除 connect 监听，防止内存泄漏
    try {
      _socketService.socket?.off('connect');
      // 可选：离开房间
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
  // 🚪 进房逻辑 (核心修复)
  // ===========================================================================

  void _setupJoinRoomLogic() {
    final socket = _socketService.socket;

    // 1. 监听底层重连：只要连上，立马进房
    socket?.on('connect', (_) {
      debugPrint("✅ [WS] Socket 重连成功，重新进房: $conversationId");
      _joinRoom();
    });

    // 2. 如果当前已经连着，直接进
    if (socket!.connected) {
      debugPrint(" [WS] Socket 已连接，立即进房: $conversationId");
      _joinRoom();
    } else {
      debugPrint("⏳ [WS] Socket 未连接，等待连接...");
    }
  }

  void _joinRoom() {
    try {
      // ️ 注意：根据你的 socket_events.dart，这里必须用 'join_chat'
      _socketService.socket?.emit(SocketEvents.joinChat, {
        'roomId': conversationId,
      });
      //  修复：使用 microtask 将“对其他 Provider 的修改”推迟到下一帧执行
      Future.microtask(() {
        debugPrint(" [WS-Path] 准备触发对账，当前会话: $conversationId");
        //  架构点：进房成功后，立即让 ViewModel 跑一次增量同步
        // 这样即使是在页面没刷新的情况下断线重连，也会自动补齐缺口
        // 检查 provider 是否还在监听，防止内存泄露
        try {
          final notifier = _ref.read(
            chatViewModelProvider(conversationId).notifier,
          );
          debugPrint(" [WS-Path] 成功获取 Notifier，开始执行 performIncrementalSync");
          notifier.performIncrementalSync();
        } catch (e) {
          debugPrint(" [WS-Path] 触发同步失败: $e");
        }
      });
    } catch (e) {
      debugPrint(" [WS] 进房失败: $e");
    }
  }

  // ===========================================================================
  //  Socket 监听
  // ===========================================================================

  void _setupSubscriptions() {
    _msgSub = _socketService.chatMessageStream.listen(_onSocketMessage);
    _readStatusSub = _socketService.readStatusStream.listen(
      _onReadStatusUpdate,
    );
    _recallSub = _socketService.recallEventStream.listen(_onMessageRecalled);
  }

  // ===========================================================================
  //  事件处理
  // ===========================================================================

  void _onSocketMessage(Map<String, dynamic> data) async {
    final msg = SocketMessage.fromJson(data);

    // 过滤掉非本房间、已处理、或者自己发的消息
    if (msg.conversationId != conversationId ||
        _processedMsgIds.contains(msg.id) ||
        msg.sender?.id == _currentUserId)
      return;

    _processedMsgIds.add(msg.id);
    if (_processedMsgIds.length > 100)
      _processedMsgIds.remove(_processedMsgIds.first);

    // 如果当前页面在前台，准备发送已读回执
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _readReceiptSubject.add(null);
    }

    var uiMsg = ChatUiModelMapper.fromApiModel(
      ChatMessage(
        id: msg.id,
        content: msg.content,
        type: msg.type,
        seqId: msg.seqId,
        createdAt: msg.createdAt,
        isSelf: false,
        meta: msg.meta,
      ),
      conversationId,
      _currentUserId,
    );

    // 保护本地微缩图
    final localMsg = await LocalDatabaseService().getMessageById(uiMsg.id);
    if (localMsg?.previewBytes != null && localMsg!.previewBytes!.isNotEmpty) {
      uiMsg = uiMsg.copyWith(previewBytes: localMsg.previewBytes);
    }

    await LocalDatabaseService().saveMessage(uiMsg);
  }

  void _onReadStatusUpdate(SocketReadEvent event) async {
    if (event.conversationId != conversationId ||
        event.readerId == _currentUserId)
      return;

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
    final tip = event.isSelf
        ? "You unsent a message"
        : "This message was unsent";
    await LocalDatabaseService().doLocalRecall(event.messageId, tip);
    _updateListSnapshot(tip, DateTime.now().millisecondsSinceEpoch);
  }

  // ===========================================================================
  // 🛠️ 已读回执逻辑
  // ===========================================================================

  void _setupReadReceiptDebounce() {
    _readReceiptSubject.debounceTime(const Duration(milliseconds: 500)).listen((
      _,
    ) {
      markAsRead();
    });
  }

  void markAsRead() {
    // 只有在前台才发已读，省流量
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed)
      return;

    try {
      _ref.read(conversationListProvider.notifier).clearUnread(conversationId);
    } catch (_) {}

    Api.messageMarkAsReadApi(
      MessageMarkReadRequest(conversationId: conversationId),
    );
  }

  void _updateListSnapshot(String text, int time) {
    try {
      _ref
          .read(conversationListProvider.notifier)
          .updateLocalItem(
            conversationId: conversationId,
            lastMsgContent: text,
            lastMsgTime: time,
          );
    } catch (_) {}
  }
}
