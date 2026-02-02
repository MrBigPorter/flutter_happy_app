import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_app/common.dart';



import '../models/conversation.dart';
import '../models/friend_request.dart';
import 'conversation_provider.dart';

part 'contact_provider.g.dart';

// ===========================================================================
// 1. 通讯录列表 (Contact List)
// ===========================================================================
@riverpod
class ContactList extends _$ContactList {
  @override
  Future<List<ChatUser>> build() async {
    return await Api.getContactsApi();
  }

  /// 静默刷新
  Future<void> refresh() async {
    state = await AsyncValue.guard(() => Api.getContactsApi());
  }
}

// ===========================================================================
// 2. 好友申请列表 (Friend Requests) -  恢复并启用
// ===========================================================================
@riverpod
class FriendRequestList extends _$FriendRequestList {
  @override
  Future<List<FriendRequest>> build() async {
    return await Api.getFriendRequestsApi();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => Api.getFriendRequestsApi());
  }
}

// ===========================================================================
// 3. 搜索用户 (User Search) -  统一改为注解写法
// ===========================================================================
@riverpod
Future<List<ChatUser>> userSearch(UserSearchRef ref, String keyword) async {
  if (keyword.trim().isEmpty) return [];
  return await Api.searchUserApi(keyword);
}

// ===========================================================================
// 4. 控制器：添加好友 (Add Friend)
// ===========================================================================
// 使用 family 使得每个用户的添加按钮状态独立 (loading 不会互串)
@riverpod
class AddFriendController extends _$AddFriendController {
  @override
  FutureOr<void> build(String userId) {
    return null;
  }

  /// 执行添加
  Future<bool> execute({String? reason}) async {
    state = const AsyncLoading();

    final newState = await AsyncValue.guard(() async {
      // userId 来自 family 参数 (this.userId)
      await Api.addFriendApi(userId, reason: reason);
    });

    state = newState;
    return !newState.hasError;
  }
}

// ===========================================================================
// 5. 控制器：处理申请 (Handle Request)
// ===========================================================================
@riverpod
class HandleRequestController extends _$HandleRequestController {
  @override
  FutureOr<void> build() => null;

  /// 执行处理 (同意/拒绝)
  Future<bool> execute({
    required String userId,
    required FriendRequestAction action,
  }) async {
    state = const AsyncLoading();

    final newState = await AsyncValue.guard(() async {
      await Api.handleFriendRequestApi(userId, action);
    });

    state = newState;

    if (!newState.hasError) {
      // 成功联动逻辑：

      // 1. 刷新好友申请列表 (NewFriendPage 列表更新)
      ref.read(friendRequestListProvider.notifier).refresh();

      // 2. 如果是同意，刷新通讯录 (增加新人)
      if (action == FriendRequestAction.accepted) {
        ref.read(contactListProvider.notifier).refresh();
      }
      return true;
    }
    return false;
  }
}

// ===========================================================================
// 6. 群组成员操作 (Group Actions) - 保持原有逻辑
// ===========================================================================
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

    // 刷新群详情
    if(newState.value == null) {
      ref.invalidate(chatDetailProvider(groupId));
    }

    return newState.value?.count;
  }

  /// 动作 B: 创建群聊
  Future<String?> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    state = const AsyncValue.loading();

    final newState = await AsyncValue.guard(() async {
      final res = await Api.createGroupApi(name, memberIds);
      return res.id; // 假设 CreateGroupResponse 有 id 字段
    });

    state = newState;

    if (newState.hasValue) {
      // 创建群后刷新会话列表
      ref.read(conversationListProvider.notifier).refresh();
      return newState.value;
    }
    return null;
  }

  /// 动作 C: 退群
  Future<bool?> leaveGroup({required String groupId}) async {
    state = const AsyncValue.loading();
    final newState = await AsyncValue.guard(() async {
      final res = await Api.groupLeaveApi(LeaveGroupRequest(groupId: groupId));
      return res.success;
    });
    state = newState;

    if(newState.hasValue && newState.value == true) {
      // 退群后，刷新列表
      ref.read(conversationListProvider.notifier).refresh();
      return true;
    }
    return null;
  }
}