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
      // 群没了，直接删库
        await repo.deleteConversation(groupId);
        ref.read(conversationListProvider.notifier).refresh(); // 刷新列表移除该项
        break;
      case SocketEvents.memberKicked:
      case SocketEvents.memberLeft:
      if (payload.targetId == myId) {
        // 我被踢了/我退了 -> 删本地会话
        await repo.deleteConversation(groupId);
        ref.read(conversationListProvider.notifier).refresh();
      } else {
        // 别人走了 -> 优化：直接在本地数据库移除该成员，不拉接口
        if (payload.targetId != null) {
          await repo.removeMemberFromGroup(groupId, payload.targetId!);
        }
      }
        break;

    // --- 信息变更事件：更新会话 ---
      case SocketEvents.groupInfoUpdated:
      //  使用 payload.updates 取值
        await repo.updateConversationInfo(
            groupId,
            name: payload.updates['name'],
            avatar: payload.updates['avatar'],
            announcement: payload.updates['announcement'],
        );
        // 更新群详情缓存
        break;

    // --- 权限/成员变更事件 ---
      case SocketEvents.memberMuted:
      case SocketEvents.ownerTransferred:
      case SocketEvents.memberRoleUpdated:
      _scheduleDetailSync(groupId);
        break;
      case SocketEvents.memberJoined:
    //  优化：如果 payload 里有 member 完整信息，直接插库
      if (payload.member != null) {
        await repo.addMemberToGroup(groupId, payload.member!);
      } else {
        // 只有 payload 数据残缺时，才迫不得已拉接口
        // 或者可以做一个防抖 (Debounce)，防止短时间大量进人狂拉接口
        _scheduleDetailSync(groupId);
      }
        break;
    }

    // ========================================================
    // 3. UI 交互层 (Interaction Layer) - 弹窗、跳转
    // ========================================================
    //  传入 payload.targetId 辅助判断
    _handleNavigationSideEffects(event, myId, payload.targetId);
  }

  // 🔄防抖同步：避免 1秒内进 10 个人请求 10 次接口
  // 简单的实现方式，也可以用 rxdart 的 debounce
  void _scheduleDetailSync(String groupId) {
    // 这里可以加一个简单的标识位或时间戳判断
    // 如果你正在聊天页内，其实 ChatGroupNotifier 已经更新了 UI。
    // 这里主要是为了保证本地数据库的数据最终一致性。

    // 策略：如果当前用户正在查看该群，且事件可能导致本地数据不一致，
    // 则延迟 2 秒拉取一次，或者不拉取（依赖用户下次进来的自动刷新）。

    debugPrint("⚠️ [Processor] 检测到复杂变更，建议稍后同步详情: $groupId");
    // 如果你非常想保证数据绝对正确，可以保留这个调用，但建议加限制：
    // await _updateGroupDetailCache(groupId);
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