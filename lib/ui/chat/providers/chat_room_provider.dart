import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/providers/socket_provider.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import 'package:flutter_app/core/api/lucky_api.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';

import '../../../core/services/socket/socket_service.dart';
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

  //  [核心修改] 创建即启动 (自动挡)
  // Page 一调 watch，这里就执行，Handler 就跑起来了
  // 这彻底替代了 Page initState 里的逻辑
  controller.activate();

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
    // 监听生命周期
    WidgetsBinding.instance.addObserver(this);
  }

  // [新增] 统一启动入口
  void activate() {
    debugPrint("🎬 [Controller] 会话激活: $conversationId");
    // 启动 Handler (它内部会自动处理 Socket 进房、重连监听、初始已读)
    _eventHandler.init();
  }

  void dispose() {
    debugPrint(" [Controller] 会话销毁: $conversationId");
    _eventHandler.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  // 监听前后台切换 (Warm Read)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("📱 [Controller] 切回前台 -> 触发已读");
      _eventHandler.markAsRead();
      // 注意：这里不需要调 sync，因为 Socket 如果断了会自动连，连上会触发 Handler 的 connect 事件
    }
  }

  // 暴露给外部调用的方法
  void markAsRead() => _eventHandler.markAsRead();

  // 辅助功能：撤回 & 删除
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