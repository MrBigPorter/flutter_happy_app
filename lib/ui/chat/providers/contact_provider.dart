import 'dart:async';
import 'package:flutter_app/common.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/conversation.dart';
import 'conversation_provider.dart';

part 'contact_provider.g.dart';

// --- [读] 好友列表数据源 ---
@riverpod
class ContactList extends _$ContactList {
  @override
  Future<List<ChatUser>> build() async => await Api.getContactsApi();
}

@riverpod
class AddFriendController extends _$AddFriendController {
  @override
  //  同上，显式持有 AsyncValue<void>
  AsyncValue<void> build(String userId) {
    return const AsyncData(null);
  }

  Future<bool> execute() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() => Api.addFriendApi(userId));

    if (!state.hasError) {
      ref.invalidate(contactListProvider);
      return true;
    }
    return false;
  }
}

@riverpod
class GroupMemberActionController extends _$GroupMemberActionController {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  /// 动作 A: 邀请成员
  Future<int?> inviteMember({
    required String groupId,
    required List<String> memberIds,
  }) async {
    state = const AsyncValue.loading();

    final newState = await AsyncValue.guard(
      () => Api.groupInviteApi(
        InviteToGroupRequest(groupId: groupId, memberIds: memberIds),
      ),
    );

    state = newState;
    return newState.value?.count;
  }

  /// 动作 B: 创建群聊
  Future<String?> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    state = const AsyncValue.loading();

    final newState = await AsyncValue.guard(() async {
      return await Api.createGroupApi(name, memberIds);
    });

    state = newState;
    if(newState.hasValue && newState.value != null) {
      ref.invalidate(chatDetailProvider(newState.value!.id));
      return newState.value!.id;
    }
    return null;
  }

  /// leave group
  Future<bool?> leaveGroup({required String groupId}) async {
    state = const AsyncValue.loading();
    final newState = await AsyncValue.guard(() async {
      return await Api.groupLeaveApi(LeaveGroupRequest(groupId: groupId));
    });
    state = newState;

    if(newState.hasValue && newState.value != null) {
      return newState.value?.success;
    }
    return null;
  }
}

// --- [读] 搜索结果 (保持 FutureProvider) ---
final userSearchProvider = FutureProvider.autoDispose
    .family<List<ChatUser>, String>((ref, keyword) async {
      if (keyword.isEmpty) return [];
      return Api.searchUserApi(keyword);
    });
