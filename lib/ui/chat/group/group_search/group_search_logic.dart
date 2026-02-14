
part of 'group_search_page.dart';


class _GroupSearchLogic {
  /// 处理搜索动作
  static void handleSearch({
    required BuildContext context,
    required WidgetRef ref,
    required TextEditingController controller,
    required VoidCallback onSearchStateChanged, // 回调：通知 UI 更新 _hasSearched 状态
  }){
    final keyword = controller.text.trim();

    // 输入校验
    if (keyword.isEmpty) {
      RadixToast.warning("Please enter a keyword");
      return;
    }

    // 收起键盘
    FocusScope.of(context).unfocus();

    // 更新状态，显示搜索结果
    onSearchStateChanged();

    // 触发搜索
    ref.read(groupSearchControllerProvider.notifier).search(keyword);
  }

/// 处理清除按钮
  static void handleClear(TextEditingController controller) {
    controller.clear();
  }

  // 处理搜索结果点击
  static void handleResultTap(BuildContext context, GroupSearchResult group) {
    appRouter.push('/chat/group/profile/${group.id}');
  }
}