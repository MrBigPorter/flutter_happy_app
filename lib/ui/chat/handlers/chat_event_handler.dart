import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'package:flutter_app/core/services/socket_service.dart';
import 'package:flutter_app/core/providers/socket_provider.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_app/core/api/lucky_api.dart';

import '../models/conversation.dart';

class ChatEventHandler {
  final String conversationId;
  final Ref _ref;
  final SocketService _socketService;
  final String _currentUserId;

  StreamSubscription? _msgSub, _readStatusSub, _recallSub;
  final _readReceiptSubject = PublishSubject<void>();
  final Set<String> _processedMsgIds = {};

  int _maxReadSeqId = 0;

  ChatEventHandler(this.conversationId, this._ref, this._socketService, this._currentUserId);

  void init() {
    _setupSubscriptions();
    _setupReadReceiptDebounce();
  }

  void dispose() {
    _msgSub?.cancel();
    _readStatusSub?.cancel();
    _recallSub?.cancel();
    _readReceiptSubject.close();
  }

  // ===========================================================================
  // 📡 Socket 监听
  // ===========================================================================

  void _setupSubscriptions() {
    // 监听新消息
    _msgSub = _socketService.chatMessageStream.listen(_onSocketMessage);
    // 监听对方已读状态
    _readStatusSub = _socketService.readStatusStream.listen(_onReadStatusUpdate);
    // 监听撤回
    _recallSub = _socketService.recallEventStream.listen(_onMessageRecalled);
  }

  // ===========================================================================
  // 📥 事件处理
  // ===========================================================================

  void _onSocketMessage(Map<String, dynamic> data) async {
    final msg = SocketMessage.fromJson(data);

    // 过滤掉非本房间、已处理、或者自己发的消息
    if (msg.conversationId != conversationId ||
        _processedMsgIds.contains(msg.id) ||
        msg.sender?.id == _currentUserId) return;

    _processedMsgIds.add(msg.id);
    if (_processedMsgIds.length > 100) _processedMsgIds.remove(_processedMsgIds.first);

    // 如果当前页面在前台，准备发送已读回执
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _readReceiptSubject.add(null);
    }

    var uiMsg = ChatUiModel.fromApiModel(
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

    // 保护：如果本地已经有微缩图 (比如是同步端)，保留它
    final localMsg = await LocalDatabaseService().getMessageById(uiMsg.id);
    if (localMsg?.previewBytes != null && localMsg!.previewBytes!.isNotEmpty) {
      uiMsg = uiMsg.copyWith(previewBytes: localMsg.previewBytes);
    }

    await LocalDatabaseService().saveMessage(uiMsg);
  }

  void _onReadStatusUpdate(SocketReadEvent event) async {
    if (event.conversationId != conversationId || event.readerId == _currentUserId) return;

    if (event.lastReadSeqId > _maxReadSeqId) {
      _maxReadSeqId = event.lastReadSeqId;
      await LocalDatabaseService().markMessagesAsRead(conversationId, _maxReadSeqId);
    }
  }

  void _onMessageRecalled(SocketRecallEvent event) async {
    if (event.conversationId != conversationId) return;

    final tip = event.isSelf ? "You unsent a message" : "This message was unsent";
    await LocalDatabaseService().doLocalRecall(event.messageId, tip);
    _updateListSnapshot(tip, DateTime.now().millisecondsSinceEpoch);
  }

  // ===========================================================================
  // 🛠️ 已读回执逻辑
  // ===========================================================================

  void _setupReadReceiptDebounce() {
    _readReceiptSubject.debounceTime(const Duration(milliseconds: 500)).listen((_) {
      markAsRead();
    });
  }

  void markAsRead() {
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return;

    try {
      _ref.read(conversationListProvider.notifier).clearUnread(conversationId);
    } catch (_) {}

    Api.messageMarkAsReadApi(MessageMarkReadRequest(conversationId: conversationId));
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