import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/core/store/user_store.dart';
import 'package:flutter_app/ui/chat/repository/message_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/providers/socket_provider.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import 'package:flutter_app/core/api/lucky_api.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';

import '../../../core/services/socket/socket_service.dart';
import '../handlers/chat_event_handler.dart';

/// Controller Provider for managing Chat Room logic and lifecycle
final chatControllerProvider = Provider.family.autoDispose<ChatRoomController, String>((ref, conversationId) {
  final socketService = ref.read(socketServiceProvider);
  final currentUserId = ref.watch(userProvider.select((s) => s?.id)) ?? '';
  final repo = ref.read(messageRepositoryProvider);

  final controller = ChatRoomController(
      socketService,
      conversationId,
      ref,
      currentUserId,
      repo
  );

  // Automatic Activation: Starts the handler immediately upon provider initialization.
  // This replaces the manual init logic previously required in Page initState.
  controller.activate();

  ref.onDispose(() => controller.dispose());
  return controller;
});

class ChatRoomController with WidgetsBindingObserver {
  final String conversationId;

  /// Strong reference to the event handler to prevent garbage collection
  final ChatEventHandler _eventHandler;
  final MessageRepository _repo;

  // Internal disposal flag to prevent operations on a disposed controller
  bool _isDisposed = false;

  ChatRoomController(
      SocketService socketService,
      this.conversationId,
      Ref ref,
      String currentUserId,
      this._repo
      ) : _eventHandler = ChatEventHandler(conversationId, ref, socketService, currentUserId)
  {
    // Register lifecycle observer for foreground/background transitions
    WidgetsBinding.instance.addObserver(this);
  }

  /// Unified entry point to start background processes and initial checks
  void activate() {
    if(_isDisposed) return;
    // Initialize handler: manages socket room entry, reconnection, and sync
    _eventHandler.init();
    // Cold Read check: Validate unread status upon room entry
    checkAndMarkRead();
  }

  void dispose() {
    _isDisposed = true;
    _eventHandler.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Warm Read: Triggered when the app returns from background to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(_isDisposed) return;
    if (state == AppLifecycleState.resumed) {
      debugPrint("[ChatRoomController] App resumed; triggering read receipt check");
      checkAndMarkRead();
    }
  }

  /// Public API to manually mark messages as read
  void markAsRead() {
    if(_isDisposed) return;
    _eventHandler.markAsRead();
  }

  /// Validates local unread state before committing an expensive network API call
  Future<void> checkAndMarkRead() async {
    if(_isDisposed) return;
    try {
      // 1. Check local conversation state via Repository
      final conv = await _repo.getConversation(conversationId);
      final unread = conv?.unreadCount ?? 0;

      // Safety check after async operation
      if (_isDisposed) return;

      debugPrint("[ChatRoomController] Checking local unread count: $unread");

      // 2. Optimization: Intercept redundant API requests if unread count is zero
      if (unread > 0) {
        debugPrint("[ChatRoomController] Found $unread unread messages; reporting to server...");
        _eventHandler.markAsRead();
      } else {
        debugPrint("[ChatRoomController] Local unread is 0; intercepting redundant API request");
      }
    } catch (e) {
      if (_isDisposed) {
        debugPrint("[ChatRoomController] Ignoring mark-read error during disposal: $e");
        return;
      }
      debugPrint("[ChatRoomController] Check read failed: $e");
    }
  }

  // --- Auxiliary Messaging Features ---

  Future<void> recallMessage(String messageId) async {
    try {
      final res = await Api.messageRecallApi(MessageRecallRequest(
          conversationId: conversationId,
          messageId: messageId
      ));
      await LocalDatabaseService().doLocalRecall(messageId, res.tip);
    } catch (e) {
      debugPrint("[ChatRoomController] Recall failed: $e");
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await LocalDatabaseService().deleteMessage(messageId);
      await Api.messageDeleteApi(MessageDeleteRequest(
          messageId: messageId,
          conversationId: conversationId
      ));
    } catch (e) {
      debugPrint("[ChatRoomController] Delete failed: $e");
    }
  }
}