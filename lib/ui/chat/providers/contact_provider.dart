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
class CreateGroupController extends _$CreateGroupController {
  @override
  //  改成同步 Notifier，初始值直接给 AsyncData(null)
  AsyncValue<CreateGroupResponse?> build() {
    return const AsyncData(null);
  }

  Future<CreateGroupResponse?> execute(String name, List<String> memberIds) async {
    // 1. 设置状态为 loading
    state = const AsyncLoading();

    // 2. 使用 AsyncValue.guard
    final result = await AsyncValue.guard(() => Api.createGroupApi(name, memberIds));
    state = result;
    if (!state.hasError) {
      // 3. 成功后，刷新会话列表
      ref.invalidate(conversationListProvider);
      return result.value;
    }
    return null;
  }
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

// --- [读] 搜索结果 (保持 FutureProvider) ---
final userSearchProvider = FutureProvider.autoDispose.family<List<ChatUser>, String>((ref, keyword) async {
  if (keyword.isEmpty) return [];
  return Api.searchUserApi(keyword);
});