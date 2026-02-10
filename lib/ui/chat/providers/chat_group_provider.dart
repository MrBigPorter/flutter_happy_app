import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/chat_group_api.dart';
import '../../../core/api/lucky_api.dart';
import '../models/conversation.dart';
part 'chat_group_provider.g.dart';

@riverpod
class ChatGroup extends _$ChatGroup {

  @override
  Future<ConversationDetail> build(String conversationId) async {
    // 直接调用获取详情的接口 (这个接口里包含了 members)
    return await Api.chatDetailApi(conversationId);
  }

  // =================================================
  // 动作 1：踢人 (更新 members 字段)
  // =================================================
  Future<void> kickMember(String targetUserId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ChatGroupApi.kickMember(conversationId, targetUserId);

      // 从当前状态拿到旧对象
      final currentDetail = state.value!;

      // 过滤成员列表
      final newMembers = currentDetail.members.where((m) => m.userId != targetUserId).toList();

      //  使用 copyWith 更新 members 字段
      return currentDetail.copyWith(members: newMembers);
    });
  }

  // =================================================
  //  动作 2：禁言 (更新 members 字段)
  // =================================================
  Future<void> muteMember(String targetUserId, int duration) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final res = await ChatGroupApi.muteMember(conversationId, targetUserId, duration);

      final currentDetail = state.value!;

      final newMembers = [
        for (final m in currentDetail.members)
          if (m.userId == targetUserId)
            m.copyWith(mutedUntil: res.mutedUntil) // 更新单人禁言状态
          else
            m
      ];

      return currentDetail.copyWith(members: newMembers);
    });
  }

  // =================================================
  //  动作 3：改群名/公告 (更新 name 字段) [NEW]
  // =================================================
  Future<void> updateInfo({String? name, String? announcement}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final res = await ChatGroupApi.updateGroupInfo(
        conversationId: conversationId,
        name: name,
        announcement: announcement,
      );

      final currentDetail = state.value!;

      // 同时更新 name 和 announcement
      return currentDetail.copyWith(
        name: res.name,
        // 如果你的 ConversationDetail 还有 announcement 字段，也要更新
        // announcement: res.announcement
      );
    });
  }

  // =================================================
  //  动作 4：解散群 (特殊处理)
  // =================================================
  Future<bool> disbandGroup() async {
    // 解散群通常意味着这个页面要关闭了，或者状态清空
    // 这里我们只负责调用 API，返回成功失败，UI 层决定跳转
    state = const AsyncValue.loading();
    try {
      await ChatGroupApi.disbandGroup(conversationId);
      // 成功后可能不需要更新状态了，因为页面都要退出了
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}