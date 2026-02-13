part of 'contact_list_page.dart';

/// 抽离出的联系人页面逻辑层
mixin ContactListLogic on ConsumerState<ContactListPage> {

  // 1. 数据处理逻辑：将原始模型转换为带索引的实体
  List<ContactEntity> processData(List<ChatUser> contacts) {
    List<ContactEntity> list = contacts.map((e) {
      if (e.nickname.isEmpty) {
        return ContactEntity(user: e, tagIndex: "#");
      }

      // 这里如果联系人极多，可以考虑在持久化时预存 tag，避免实时计算
      String pinyin = PinyinHelper.getPinyinE(e.nickname);
      String tag = pinyin.substring(0, 1).toUpperCase();
      if (!RegExp("[A-Z]").hasMatch(tag)) tag = "#";

      return ContactEntity(user: e, tagIndex: tag);
    }).toList();

    SuspensionUtil.sortListBySuspensionTag(list);
    SuspensionUtil.setShowSuspensionStatus(list);
    return list;
  }

  // 2. 交互逻辑：下拉刷新
  Future<void> handleRefresh() async {
    try {
      // 调用 Repository 同步最新数据到本地数据库
      await ref.read(contactRepositoryProvider).syncContacts();
      // 成功后失效 Provider 触发重新加载
      ref.invalidate(contactListProvider);
    } catch (e) {
      debugPrint("Refresh contacts failed: $e");
    }
  }

  // 3. 路由跳转
  void navigateToProfile(ChatUser user) {
    //  这里的关键：push 的时候把 user 对象作为 extra 传过去
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

  // 4. 错误状态处理
  Widget _buildErrorState(Object err) {
    return Center(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 100.h),
          Center(child: Text("Load Error: $err", style: const TextStyle(color: Colors.red))),
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