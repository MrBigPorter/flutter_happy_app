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


// 控制器 Provider：现在非常轻量，只负责会话的生命周期 (Socket 监听、红点消除)
final chatControllerProvider = Provider.family.autoDispose<ChatRoomController, String>((ref, conversationId) {
  final socketService = ref.read(socketServiceProvider);
  final currentUserId = ref.read(luckyProvider).userInfo?.id ?? "";

  final controller = ChatRoomController(
      socketService,
      conversationId,
      ref,
      currentUserId
  );

  // 页面销毁时，自动断开事件监听
  ref.onDispose(() => controller.dispose());
  return controller;
});

class ChatRoomController with WidgetsBindingObserver {
  final String conversationId;
  final Ref _ref;

  // 只保留事件处理器 (负责监听 Socket 消息入库)
  final ChatEventHandler _eventHandler;

  ChatRoomController(
      SocketService socketService,
      this.conversationId,
      this._ref,
      String currentUserId,
      ) : _eventHandler = ChatEventHandler(conversationId, _ref, socketService, currentUserId)
  {
    // 1. 初始化 Socket 监听 (收消息入库、对方已读通知等)
    _eventHandler.init();

    // 2. 监听 App 前后台切换 (回到前台自动标已读)
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    _eventHandler.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  // ===========================================================================
  // 核心功能：会话状态管理
  // ===========================================================================

  // 标记当前会话已读 (进入页面、App回到前台时调用)
  void markAsRead() {
    _eventHandler.markAsRead();
  }

  // ===========================================================================
  // 辅助功能 (撤回/删除)
  // ===========================================================================

  Future<void> recallMessage(String messageId) async {
    try {
      // 1. 调接口通知服务器
      final res = await Api.messageRecallApi(MessageRecallRequest(
          conversationId: conversationId,
          messageId: messageId
      ));
      // 2. 改本地库 (Sembast 更新后，ViewModel 会自动通知 UI 刷新)
      await LocalDatabaseService().doLocalRecall(messageId, res.tip);
    } catch (e) {
      debugPrint("Recall failed: $e");
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      // 1. 删本地 (UI 立刻消失)
      await LocalDatabaseService().deleteMessage(messageId);
      // 2. 告服务器
      await Api.messageDeleteApi(MessageDeleteRequest(
          messageId: messageId,
          conversationId: conversationId
      ));
    } catch (e) {
      debugPrint("Delete failed: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 切回前台，清除红点
      markAsRead();
    }
  }
}