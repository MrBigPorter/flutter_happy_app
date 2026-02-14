import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';
import 'package:flutter_app/core/api/chat_group_api.dart';

part 'group_search_provider.g.dart';

@riverpod
class GroupSearchController extends _$GroupSearchController {
  @override
  FutureOr<List<GroupSearchResult>> build() {
    // 1. 【核心修复】保活机制
    // 防止 Provider 在异步请求完成前被意外销毁
    final link = ref.keepAlive();

    // 可选：如果超过 60 秒没人使用，再真正销毁 (防止内存泄漏)
    // timer?.cancel();
    // ref.onDispose(() => timer?.cancel());
    // final timer = Timer(const Duration(seconds: 60), () {
    //   link.close();
    // });

    // 初始返回空列表
    return [];
  }

  Future<void> search(String keyword) async {
    if (keyword.isEmpty) return;

    // 2. 设置加载中
    state = const AsyncLoading();

    try {
      // 3. 执行请求
      final result = await ChatGroupApi.searchGroups(keyword);

      state = AsyncData(result);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}