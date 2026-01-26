import 'dart:async';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'contact_provider.g.dart';

@riverpod
class ContactList extends _$ContactList {
  @override
  Future<List<ChatUser>> build() async {
    return await Api.getContactsApi();
  }

  /// 搜索功能：可以手动调用来更新状态
  Future<void> search(String keyword) async {
    if (keyword.isEmpty) {
      ref.invalidateSelf(); // 关键：清空搜索时恢复原始列表
    }
    return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await Api.searchUserApi(keyword);
    });
  }

  /// 执行建群副作用
  Future<CreateGroupResponse?> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    // 这是一个副作用操作，不一定会改变当前的联系人列表状态，
    // 但我们需要捕获这个过程。
    try {
      final response = await Api.createGroupApi(name, memberIds);
      return response;
    } catch (e, st) {
      // 可以在这里处理全局错误提示
      return null;
    }
  }
}
