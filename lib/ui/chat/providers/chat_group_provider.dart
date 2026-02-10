import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_app/common.dart';
import '../../../core/api/chat_group_api.dart';
import '../models/conversation.dart';
import '../models/group_role.dart';
import 'conversation_provider.dart';

part 'chat_group_provider.g.dart';

@riverpod
class ChatGroup extends _$ChatGroup {
  @override
  Future<ConversationDetail> build(String conversationId) async {
    // Note: Socket listeners can be added here.
    // e.g., ref.listen to socket streams to trigger ref.invalidateSelf() on group updates.
    return await Api.chatDetailApi(conversationId);
  }

  // --- 1. Member Management Actions ---

  /// Removes a member from the group (Kick).
  Future<void> kickMember(String targetUserId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ChatGroupApi.kickMember(conversationId, targetUserId);
      final currentDetail = state.value!;

      // Local state update: remove the user from the member list
      final newMembers = currentDetail.members.where((m) => m.userId != targetUserId).toList();
      return currentDetail.copyWith(members: newMembers);
    });
  }

  /// Mutes a specific member for a defined duration.
  Future<void> muteMember(String targetUserId, int duration) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final res = await ChatGroupApi.muteMember(conversationId, targetUserId, duration);
      final currentDetail = state.value!;

      // Local state update: update the mutedUntil timestamp for the target user
      final newMembers = [
        for (final m in currentDetail.members)
          if (m.userId == targetUserId) m.copyWith(mutedUntil: res.mutedUntil) else m
      ];
      return currentDetail.copyWith(members: newMembers);
    });
  }

  /// Invites new members to the existing group.
  Future<bool> inviteMembers(List<String> memberIds) async {
    state = const AsyncValue.loading();
    final newState = await AsyncValue.guard(() async {
      await Api.groupInviteApi(
        InviteToGroupRequest(groupId: conversationId, memberIds: memberIds),
      );
      // Re-fetch the full group details to ensure UI synchronization after invitation
      return await Api.chatDetailApi(conversationId);
    });
    state = newState;
    return !newState.hasError;
  }

  /// Updates member privileges (Promote to Admin / Demote to Member).
  Future<void> setAdmin(String targetUserId, bool isAdmin) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final res = await ChatGroupApi.setAdmin(conversationId, targetUserId, isAdmin);

      final currentDetail = state.value!;
      // Local state update: update the role of the target member
      final newMembers = currentDetail.members.map((m) {
        if (m.userId == targetUserId) {
          return m.copyWith(role: isAdmin ? GroupRole.admin : GroupRole.member);
        }
        return m;
      }).toList();

      return currentDetail.copyWith(members: newMembers);
    });
  }

  // --- 2. Group Information Management ---

  /// Updates group metadata such as name, announcement, or global mute settings.
  Future<void> updateInfo({
    String? name,
    String? announcement,
    bool? isMuteAll,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final res = await ChatGroupApi.updateGroupInfo(
        conversationId: conversationId,
        name: name,
        announcement: announcement,
        isMuteAll: isMuteAll,
      );

      final currentDetail = state.value!;
      return currentDetail.copyWith(
        name: res.name,
        announcement: res.announcement,
        isMuteAll: res.isMuteAll ?? currentDetail.isMuteAll,
      );
    });
  }

  // --- 3. Group Lifecycle Actions ---

  /// Current user leaves the group.
  Future<bool> leaveGroup() async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final res = await ChatGroupApi.leaveGroup(conversationId);
      return res.success;
    });
    return result.value ?? false;
  }

  /// Permanently dissolves the group (Owner only).
  Future<bool> disbandGroup() async {
    state = const AsyncValue.loading();
    try {
      await ChatGroupApi.disbandGroup(conversationId);
      // Invalidate the global conversation list to reflect the removal
      ref.invalidate(conversationListProvider);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

// ===========================================================================
// Group Creation Controller (Global Action)
// ===========================================================================
@riverpod
class GroupCreateController extends _$GroupCreateController {
  @override
  FutureOr<String?> build() => null;

  /// Creates a new group and returns the new conversation ID.
  Future<String?> create({required String name, required List<String> memberIds}) async {
    state = const AsyncLoading();
    final newState = await AsyncValue.guard(() async {
      final res = await Api.createGroupApi(name, memberIds);
      return res.id;
    });
    state = newState;
    if (newState.hasValue) {
      // Refresh conversation list so the new group appears in the inbox
      ref.invalidate(conversationListProvider);
    }
    return newState.value;
  }
}