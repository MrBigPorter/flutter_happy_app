import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/providers/socket_provider.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import 'package:flutter_app/core/api/lucky_api.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';

import '../../../core/services/socket_service.dart';
import '../handlers/chat_event_handler.dart';

// 控制器 Provider
final chatControllerProvider = Provider.family.autoDispose<ChatRoomController, String>((ref, conversationId) {
  final socketService = ref.read(socketServiceProvider);
  final currentUserId = ref.read(luckyProvider).userInfo?.id ?? "";

  final controller = ChatRoomController(
      socketService,
      conversationId,
      ref,
      currentUserId
  );

  ref.onDispose(() => controller.dispose());
  return controller;
});

class ChatRoomController with WidgetsBindingObserver {
  final String conversationId;
  // 强引用 Handler，防止被 GC
  final ChatEventHandler _eventHandler;

  ChatRoomController(
      SocketService socketService,
      this.conversationId,
      Ref ref,
      String currentUserId,
      ) : _eventHandler = ChatEventHandler(conversationId, ref, socketService, currentUserId)
  {
    // 1. 初始化 Handler (这里面会触发进房！)
    _eventHandler.init();

    // 2. 监听生命周期
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    _eventHandler.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  // 切回前台时，自动标记已读
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _eventHandler.markAsRead();
    }
  }

  // 暴露给外部调用的方法
  void markAsRead() => _eventHandler.markAsRead();

  // 辅助功能：撤回 & 删除 (保留你原来的)
  Future<void> recallMessage(String messageId) async {
    try {
      final res = await Api.messageRecallApi(MessageRecallRequest(
          conversationId: conversationId,
          messageId: messageId
      ));
      await LocalDatabaseService().doLocalRecall(messageId, res.tip);
    } catch (e) {
      debugPrint("Recall failed: $e");
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
      debugPrint("Delete failed: $e");
    }
  }
}