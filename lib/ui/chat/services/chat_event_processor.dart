import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/core/store/user_store.dart';
import 'package:flutter_app/ui/modal/base/nav_hub.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/common.dart';
import '../../../core/constants/socket_events.dart';
import '../../../core/providers/socket_provider.dart';
import '../../chat/repository/message_repository.dart';
import '../../chat/providers/conversation_provider.dart';
import '../../chat/providers/chat_group_provider.dart';
import '../models/conversation.dart'; 

// 全局 Provider，App 启动时就要 watch 它
final chatEventProcessorProvider = Provider<ChatEventProcessor>((ref) {
  return ChatEventProcessor(ref);
});

class ChatEventProcessor {
  final Ref ref;

  ChatEventProcessor(this.ref) {
    _startListening();
  }

  void _startListening() {
    final socketService = ref.read(socketServiceProvider);

    // 监听群组事件流
    socketService.groupEventStream.listen((event) async {
      debugPrint("🚀 [Processor] 收到原始事件: ${event.type} | GroupID: ${event.groupId}");
      await _handleGlobalEvent(event);
    });
  }

  Future<void> _handleGlobalEvent(SocketGroupEvent event) async {
    final myId = ref.read(userProvider)?.id;
    final groupId = event.groupId;

    if (groupId == null || myId == null) return;

    //  [Refactor] 使用强类型 Payload，不再手动解析 Map
    final payload = event.payload;
    
    print("📦 [Processor] 处理事件: ${event.type} | GroupID: $groupId | TargetID: ${payload.targetId} | Updates: ${payload.updates}");

    // ========================================================
    // 1. 极速响应层 (Optimistic UI) - 通知 Provider
    // ========================================================
    // 列表页会立即更新 Title/Avatar，或者移除被踢的群
    ref.read(conversationListProvider.notifier).handleSocketEvent(event);

    // 聊天页输入框会立即变灰，详情页成员列表会立即变化
    ref.read(chatGroupProvider(groupId).notifier).handleSocketEvent(event);


    // ========================================================
    // 2. 数据层处理 (Data Layer) - 改数据库
    // ========================================================
    final repo = ref.read(messageRepositoryProvider);

    switch (event.type) {
    // --- 毁灭性事件：删除会话 ---
      case SocketEvents.groupDisbanded:
      case SocketEvents.memberKicked:
      case SocketEvents.memberLeft:

      //  使用 payload.targetId
      // 如果是群解散，或者被踢/退群的是我自己 -> 删库
        if (event.type == SocketEvents.groupDisbanded || payload.targetId == myId) {
          await repo.deleteConversation(groupId);
          // 刷新会话列表 Provider (确保 UI 移除该项)
          ref.read(conversationListProvider.notifier).refresh();
        } else {
          // 别人走了 -> 更新群详情缓存 (人数-1)
          await _updateGroupDetailCache(groupId);
        }
        break;

    // --- 信息变更事件：更新会话 ---
      case SocketEvents.groupInfoUpdated:
      //  使用 payload.updates 取值
        await repo.updateConversationInfo(
            groupId,
            name: payload.updates['name'],
            avatar: payload.updates['avatar']
        );
        // 更新群详情缓存
        await _updateGroupDetailCache(groupId);
        // 刷新列表 Provider
        ref.read(conversationListProvider.notifier).refresh();
        break;

    // --- 权限/成员变更事件 ---
      case SocketEvents.memberMuted:
      case SocketEvents.ownerTransferred:
      case SocketEvents.memberRoleUpdated:
      case SocketEvents.memberJoined:
      // 这些事件直接重新拉取最新的群详情并缓存
        await _updateGroupDetailCache(groupId);
        break;
    }

    // ========================================================
    // 3. UI 交互层 (Interaction Layer) - 弹窗、跳转
    // ========================================================
    //  传入 payload.targetId 辅助判断
    _handleNavigationSideEffects(event, myId, payload.targetId);

    // ========================================================
    // 4. 实时状态层 (State Layer) - 兜底刷新
    // ========================================================
    ref.invalidate(chatGroupProvider(groupId));
  }

  /// 处理导航副作用 (强制退出等)
  void _handleNavigationSideEffects(SocketGroupEvent event, String myId, String? targetId) {

    final String location = appRouter.routeInformationProvider.value.uri.toString();
    final bool isViewingThisGroup = location.contains(event.groupId!);

    if (!isViewingThisGroup) return;

    final context = NavHub.key.currentContext;
    if (context == null) return;

    switch (event.type) {
      case SocketEvents.memberKicked:
      //  使用传入的 targetId
        if (targetId == myId) {
          _showExitAlert(context, "You have been removed from this group.");
        }
        break;

      case SocketEvents.groupDisbanded:
        _showExitAlert(context, "This group has been disbanded.");
        break;
    }
  }

  void _showExitAlert(BuildContext context, String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Notice"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              context.go('/conversations');
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _updateGroupDetailCache(String groupId) async {
    try {
      final repo = ref.read(messageRepositoryProvider);
      final detail = await Api.chatDetailApi(groupId);
      await repo.saveGroupDetail(detail);
    } catch (e) {
      debugPrint("Sync group detail failed: $e");
    }
  }
}