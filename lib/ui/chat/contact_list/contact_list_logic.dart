part of 'contact_list_page.dart';

/// Contact list logic layer extracted as a mixin
mixin ContactListLogic on ConsumerState<ContactListPage> {

  // 1. Data processing logic: Convert raw models to indexed entities for the UI
  List<ContactEntity> processData(List<ChatUser> contacts) {
    List<ContactEntity> list = contacts.map((e) {
      if (e.nickname.isEmpty) {
        return ContactEntity(user: e, tagIndex: "#");
      }

      // If the contact list is extremely large, consider pre-calculating and persisting
      // the tag in the database to avoid real-time computation overhead.
      String pinyin = PinyinHelper.getPinyinE(e.nickname);
      String tag = pinyin.substring(0, 1).toUpperCase();
      if (!RegExp("[A-Z]").hasMatch(tag)) tag = "#";

      return ContactEntity(user: e, tagIndex: tag);
    }).toList();

    SuspensionUtil.sortListBySuspensionTag(list);
    SuspensionUtil.setShowSuspensionStatus(list);
    return list;
  }

  // 2. Interaction logic: Pull-to-refresh
  Future<void> handleRefresh() async {
    try {
      // Invoke Repository to sync the latest data to the local database
      await ref.read(contactRepositoryProvider).syncContacts();
      // Invalidate the provider to trigger a UI reload after a successful sync
      ref.invalidate(contactListProvider);
    } catch (e) {
      debugPrint("[ContactListLogic] Refresh contacts failed: $e");
    }
  }

  // 3. Navigation logic
  void navigateToProfile(ChatUser user) {
    // Pass the user object as an 'extra' parameter during navigation
    appRouter.push(
      '/contact/profile/${user.id}',
      extra: user,
    );
  }

  void navigateToLocalSearch() {
    appRouter.push('/contact/local-search');
  }

  void navigateToGlobalSearch() {
    appRouter.push('/contact/search');
  }

  void navigateToNewFriends() {
    appRouter.push('/contact/new-friends');
  }

  // 4. Error state handling
  Widget _buildErrorState(Object err) {
    return Center(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 100.h),
          Center(
            child: Text(
              "Load Error: $err",
              style: const TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => ref.invalidate(contactListProvider),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}