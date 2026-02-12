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

// 控制器 Provider
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
  final MessageRepository _repo;

  // 1. 新增：销毁标记位
  bool _isDisposed = false;


  ChatRoomController(
      SocketService socketService,
      this.conversationId,
      Ref ref,
      String currentUserId,
      this._repo
      ) : _eventHandler = ChatEventHandler(conversationId, ref, socketService, currentUserId)
  {
    // 监听生命周期
    WidgetsBinding.instance.addObserver(this);
  }

  // [新增] 统一启动入口
  void activate() {
    if(_isDisposed) return;
    // 启动 Handler (它内部会自动处理 Socket 进房、重连监听、初始已读)
    _eventHandler.init();
    // 激活时检查并上报已读 (Cold Read)
    checkAndMarkRead();
  }

  void dispose() {
    _isDisposed = true;
    _eventHandler.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  // 监听前后台切换 (Warm Read)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(_isDisposed) return;
    if (state == AppLifecycleState.resumed) {
      debugPrint("DirectChatSettingsPage [Controller] 切回前台 -> 触发已读");
      checkAndMarkRead();
    }
  }


  // 暴露给外部调用的方法
  void markAsRead() {
    if(_isDisposed) return;
    _eventHandler.markAsRead();
  }

  //  使用注入的 Repo 进行检查
  Future<void> checkAndMarkRead() async {
    if(_isDisposed) return;
    try {
      // 1. 查本地状态 (调用 Repo)
      final conv = await _repo.getConversation(conversationId);
      final unread = conv?.unreadCount ?? 0;
      // 再次检查 (因为 await 期间可能发生了 dispose)
      if (_isDisposed) return;

       debugPrint("[Controller] 检查本地未读数: $unread");

      // 2. 只有当确实有未读消息时，才去调 API
      if (unread > 0) {
        debugPrint(" [Controller] 发现 $unread 条未读，执行上报...");
        _eventHandler.markAsRead();
      } else {
        // 这行日志能证明拦截生效了
        debugPrint(" [Controller] 本地未读为 0，拦截了一次多余的 API 请求");
      }
    } catch (e) {
      if (_isDisposed) {
        debugPrint("️[Controller] 忽略销毁期间的 MarkRead 错误: $e");
        return;
      }
      debugPrint("Check read failed: $e");
    }
  }

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