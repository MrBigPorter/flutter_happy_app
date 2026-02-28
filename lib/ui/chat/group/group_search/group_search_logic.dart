part of 'group_search_page.dart';

class _GroupSearchLogic {
  /// Executes the search action based on the controller's input
  static void handleSearch({
    required BuildContext context,
    required WidgetRef ref,
    required TextEditingController controller,
    required VoidCallback onSearchStateChanged, // Callback to update the UI's _hasSearched status
  }){
    final keyword = controller.text.trim();

    // Basic input validation
    if (keyword.isEmpty) {
      RadixToast.warning("Please enter a keyword");
      return;
    }

    // Dismiss the keyboard
    FocusScope.of(context).unfocus();

    // Trigger state update to display search results section
    onSearchStateChanged();

    // Dispatch search action to the provider
    ref.read(groupSearchControllerProvider.notifier).search(keyword);
  }

  /// Clears the content of the search text controller
  static void handleClear(TextEditingController controller) {
    controller.clear();
  }

  /// Navigation logic for tapping a search result item
  static void handleResultTap(BuildContext context, GroupSearchResult group) {
    // Navigate to the group profile page using the shared app router
    appRouter.push('/chat/group/profile/${group.id}');
  }
}