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

class ChatEventHandler {
  final String conversationId;
  final Ref _ref;
  final SocketService _socketService;
  final String _currentUserId;

  StreamSubscription? _msgSub, _readStatusSub, _recallSub;
  StreamSubscription? _debounceSub; // New variable to manage debounce subscription

  // Optimization 1: Use BehaviorSubject or PublishSubject for debouncing
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
    debugPrint(" [ChatEventHandler] Disposed: $conversationId");

    try {
      _socketService.socket?.off('connect');
      // Leave room
      _socketService.socket?.emit(SocketEvents.leaveChat, {
        'conversationId': conversationId,
      });
    } catch (_) {}

    _msgSub?.cancel();
    _readStatusSub?.cancel();
    _recallSub?.cancel();
    _debounceSub?.cancel();
    _readReceiptSubject.close();
  }

  // ===========================================================================
  // Join Room Logic
  // ===========================================================================

  void _setupJoinRoomLogic() {
    final socket = _socketService.socket;

    socket?.on('connect', (_) {
      debugPrint(" [WS] Socket reconnected, re-joining room: $conversationId");
      _joinRoom(triggerSync: true);
    });

    if (socket?.connected == true) {
      _joinRoom(triggerSync: false);
    }
  }

  void _joinRoom({bool triggerSync = false}) {
    try {
      _socketService.socket?.emit(SocketEvents.joinChat, {
        'conversationId': conversationId,
      });

      // Only call ViewModel when synchronization is explicitly requested (e.g., reconnection)
      if (triggerSync) {
        Future.microtask(() {
          try {
            final notifier = _ref.read(
              chatViewModelProvider(conversationId).notifier,
            );
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

  // ===========================================================================
  // Socket Listeners
  // ===========================================================================

  void _setupSubscriptions() {
    _msgSub = _socketService.chatMessageStream.listen(_onSocketMessage);
    _readStatusSub = _socketService.readStatusStream.listen(_onReadStatusUpdate);
    _recallSub = _socketService.recallEventStream.listen(_onMessageRecalled);
  }

  // ===========================================================================
  // Event Handling
  // ===========================================================================

  void _onSocketMessage(Map<String, dynamic> data) async {
    final msg = SocketMessage.fromJson(data);

    // 1. Basic filtering (ignore messages not from this room)
    if (msg.conversationId != conversationId) return;

    // Only process read status and red dots when the message is sent by others
    if (msg.senderId != _currentUserId) {

      // 1. Tell server: I am reading, this message is read
      // (Side effect, DB stream cannot do this)
      _readReceiptSubject.add(null);

      // This step is to fix the "mindless increment" of GlobalHandler
      await LocalDatabaseService().clearUnreadCount(conversationId);
    }
  }

  void _onReadStatusUpdate(SocketReadEvent event) async {
    // [Fix 3] Allow processing own read events (multi-device sync)
    // if (event.conversationId != conversationId || event.readerId == _currentUserId) return;

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
  // Read Receipt Logic (Core Loop)
  // ===========================================================================

  void _setupReadReceiptDebounce() {
    // Debounce time: 500ms
    // This means if the other party sends 10 messages every 0.1s,
    // we only call API once after the last one.
    _debounceSub = _readReceiptSubject
        .debounceTime(const Duration(milliseconds: 500))
        .listen((_) {
      debugPrint(" [Debounce] Debounce ended, executing markAsRead");
      markAsRead();
    });
  }

  /// Mark as read (Universal Entry)
  /// Supports Cold Read (Join), Warm Read (Switch back), Hot Read (Online)
  Future<void> markAsRead() async {
    // 1. Traffic saving defense: If App is in background, do not send read receipt
    // (Logic: user is not looking at screen, counts as unread)
    //final currentState = WidgetsBinding.instance.lifecycleState;
    // 5. Core Fix: Relax checks.
    // If null (usually fresh start) or resumed (foreground), execution is allowed.
    // As long as it's not paused (background) or detached, we assume the user is watching.
    /*if (currentState != null &&
        currentState != AppLifecycleState.resumed &&
        currentState != AppLifecycleState.inactive) {
      debugPrint(" [MarkRead] App is in background ($currentState), skipping read report");
      return;
    }*/

    try {
      // 2. Optimistic Update
      // Clear local red dot first to make user feel "instant response"
      // This step updates the Conversation table in DB, triggering GlobalUnreadProvider
      _ref.read(conversationListProvider.notifier).clearUnread(conversationId);

      // 3. Audit (Get local max SeqId)
      // We tell backend: "I have read all messages before this ID"
      final maxSeqId = await LocalDatabaseService().getMaxSeqId(conversationId);

      // Must explicitly tell DB: Unread count for this conversation is zero!
      // With this line, GlobalUnreadProvider gets notified, and Tab red dot disappears.
      await LocalDatabaseService().markMessagesAsRead(conversationId, maxSeqId ?? 0);

      debugPrint(" [MarkRead] Audit result: maxSeqId=$maxSeqId"); // Added log

      if (maxSeqId != null) {
        // 4. Send API request
        await Api.messageMarkAsReadApi(
          MessageMarkReadRequest(
            conversationId: conversationId,
            maxSeqId: maxSeqId,
          ),
        );
        debugPrint(" [MarkRead] Read report successful: maxSeqId=$maxSeqId");
      }
    } catch (e) {
      debugPrint(" [MarkRead] Read report failed: $e");
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