import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';
import 'package:flutter_app/core/api/chat_group_api.dart';

part 'group_search_provider.g.dart';

// 使用 autoDispose，但在页面存活期间保持状态
// 如果想实现“保留历史结果”，可以去掉 autoDispose 或者使用 keepAlive
@riverpod
class GroupSearchController extends _$GroupSearchController {
  @override
  FutureOr<List<GroupSearchResult>> build() {
    // 初始状态为空列表
    return [];
  }

  Future<void> search(String keyword) async {
    if (keyword.isEmpty) return;

    // 设置为加载中
    state = const AsyncLoading();

    // 执行请求并更新状态
    state = await AsyncValue.guard(() async {
      return await ChatGroupApi.searchGroups(keyword);
    });
  }
}