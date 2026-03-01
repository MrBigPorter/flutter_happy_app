import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/chat_ui_model.dart';
import '../repository/message_repository.dart';

// 记得跑 build_runner 生成这个文件
part 'chat_search_provider.g.dart';

@riverpod
class ChatSearchController extends _$ChatSearchController {
  Timer? _debounceTimer;

  @override
  FutureOr<List<ChatUiModel>> build(String conversationId) {
    // 当离开搜索页面时，Provider 会自动销毁，顺便清理掉还没执行的定时器
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    // 初始状态：空列表，等待用户输入
    return [];
  }

  /// 执行搜索 (核心：300毫秒防抖)
  void search(String keyword) {
    // 1. 只要用户还在敲击键盘，就打断之前的读秒
    _debounceTimer?.cancel();

    // 2. 如果退格清空了输入框，直接恢复成空列表，不查库
    if (keyword.trim().isEmpty) {
      state = const AsyncData([]);
      return;
    }

    // 3. 马上让 UI 进入 Loading 转圈状态
    state = const AsyncLoading();

    // 4. 重新开始 300 毫秒倒计时
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      state = await AsyncValue.guard(() async {
        final repo = ref.read(messageRepositoryProvider);
        final results = await repo.searchMessages(conversationId, keyword);
        return results;
      });
    });
  }
}