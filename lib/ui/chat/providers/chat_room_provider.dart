import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cross_file/cross_file.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/providers/socket_provider.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import 'package:flutter_app/utils/upload/global_upload_service.dart';
import 'package:flutter_app/core/api/lucky_api.dart';

import '../../../core/services/socket_service.dart';
import '../../../core/store/lucky_store.dart';
import '../models/conversation.dart';
import '../services/chat_action_service.dart';
import '../services/chat_sync_manager.dart';
import '../handlers/chat_event_handler.dart';


// --- Providers ---

// 确保 chatStreamProvider 只在这里定义，其他旧文件里的要删掉
final chatStreamProvider = StreamProvider.family.autoDispose<List<ChatUiModel>, String>((ref, conversationId) {
  return LocalDatabaseService().watchMessages(conversationId);
});

// 确保 chatControllerProvider 只在这里定义
final chatControllerProvider = Provider.family.autoDispose<ChatRoomController, String>((ref, conversationId) {
  final socketService = ref.read(socketServiceProvider);
  final uploadService = ref.read(uploadServiceProvider);
  final currentUserId = ref.read(luckyProvider).userInfo?.id ?? "";

  final controller = ChatRoomController(
      socketService,
      uploadService,
      conversationId,
      ref,
      currentUserId
  );

  ref.onDispose(() => controller.dispose());
  return controller;
});

class ChatRoomController with WidgetsBindingObserver {
  final String conversationId;
  final Ref _ref;

  //  类型使用我们刚改名的 ChatActionService
  final ChatActionService _sender;
  final ChatEventHandler _eventHandler;
  final ChatSyncManager _syncManager;

  ChatRoomController(
      SocketService socketService,
      GlobalUploadService uploadService,
      this.conversationId,
      this._ref,
      String currentUserId,
      ) :
  //  构造函数使用 ChatActionService
        _sender = ChatActionService(conversationId, _ref, uploadService),
        _eventHandler = ChatEventHandler(conversationId, _ref, socketService, currentUserId),
        _syncManager = ChatSyncManager(conversationId, _ref, currentUserId)
  {
    _eventHandler.init();
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    _eventHandler.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  // ===========================================================================
  // UI 调用的接口
  // ===========================================================================

  // 1. 发送 (委托给 ChatActionService)
  Future<void> sendMessage(String text) => _sender.sendText(text);
  Future<void> sendImage(XFile file) => _sender.sendImage(file);
  Future<void> sendVideo(XFile file) => _sender.sendVideo(file);
  Future<void> sendVoiceMessage(String path, int duration) => _sender.sendVoiceMessage(path, duration);
  Future<void> resendMessage(String msgId) => _sender.resend(msgId);

  // 2. 加载 (委托给 SyncManager)
  bool get hasMore => _syncManager.hasMore;
  Future<void> loadMore() => _syncManager.loadMore();
  Future<void> refresh() => _syncManager.refresh(markAsRead);

  // 3. 状态 (委托给 EventHandler)
  void markAsRead() => _eventHandler.markAsRead();

  // 4. 其他操作
  Future<void> recallMessage(String messageId) async {
    try {
      final res = await Api.messageRecallApi(MessageRecallRequest(conversationId: conversationId, messageId: messageId));
      await LocalDatabaseService().doLocalRecall(messageId, res.tip);
    } catch (_) {}
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await LocalDatabaseService().deleteMessage(messageId);
      await Api.messageDeleteApi(MessageDeleteRequest(messageId: messageId, conversationId: conversationId));
    } catch (_) {}
  }

  //  静态方法也要用 ChatActionService
  static String? getPathFromCache(String msgId) => ChatActionService.getPathFromCache(msgId);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      markAsRead();
    }
  }
}