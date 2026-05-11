import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/chat/components/user_search_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';

import '../../components/network_status_bar.dart';
import '../../components/skeleton.dart';
import '../button/variant.dart';
import 'components/conversation_item.dart';

class ConversationListPage extends ConsumerStatefulWidget {
  const ConversationListPage({super.key});

  @override
  ConsumerState<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends ConsumerState<ConversationListPage> {
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _enterSearch() {
    setState(() {
      _isSearching = true;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _exitSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(authProvider.select((s) => s.isAuthenticated));
    final isSyncing = ref.watch(globalSyncStateProvider);

    // [双保险]：进入列表页立即清理选中状态
    final currentActive = ref.read(activeConversationIdProvider);
    if (currentActive != null) {
      Future.microtask(() {
        ref.read(activeConversationIdProvider.notifier).state = null;
      });
    }

    if (_isSearching) {
      return Scaffold(
        backgroundColor: context.bgPrimary,
        appBar: AppBar(
          backgroundColor: context.bgPrimary,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left, size: 30.h, color: context.fgPrimary900),
            onPressed: _exitSearch,
          ),
          title: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: _onSearchChanged,
            style: TextStyle(
              fontSize: 18.w,
              fontWeight: FontWeight.w900,
              color: context.textPrimary900,
              letterSpacing: -0.5,
            ),
            decoration: InputDecoration(
              hintText: 'Search conversations...',
              hintStyle: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: context.textPrimary900.withValues(alpha: 0.4),
                letterSpacing: -0.5,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close, color: context.fgPrimary900),
                      onPressed: _clearSearch,
                    )
                  : null,
            ),
          ),
        ),
        body: Column(
          children: [
            const NetworkStatusBar(),
            Expanded(
              child: isLoggedIn
                  ? _ConversationListView(searchQuery: _searchQuery)
                  : const _GuestView(),
            ),
          ],
        ),
      );
    }

    return BaseScaffold(
      title: isSyncing ? 'Updating...' : 'Chats',
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: context.fgPrimary900),
          onPressed: _enterSearch,
        ),
        const _AddMenuButton(),
      ],
      body: Column(
        children: [
          // A. 网络状态条
          const NetworkStatusBar(),

          // B. 会话列表
          Expanded(
            child: isLoggedIn ? _ConversationListView(searchQuery: '') : const _GuestView(),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------
// 组件 1: 右上角菜单
// ------------------------------------------------------
class _AddMenuButton extends StatelessWidget {
  const _AddMenuButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: PopupMenuButton<String>(
        icon: Icon(Icons.add_circle_outline, size: 24.w, color: context.textPrimary900),
        offset: Offset(0, 45.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        color: context.bgPrimary,
        onSelected: (value) {
          switch (value) {
            case 'create_group':
            // 创建群聊 (选人)
              context.push('/chat/group/select/member');
              break;
            case 'join_group':
            // [新增] 加入群聊 (搜索)
              context.push('/chat/group/search');
              break;
            case 'add_friend':
            // 添加好友 (搜索用户)
              showDialog(context: context, builder: (_) => const UserSearchDialog());
              break;
            case 'contacts':
            // 通讯录
              context.push('/chat/contacts');
              break;
          }
        },
        itemBuilder: (context) => [
          _buildMenuItem(context, 'create_group', Icons.chat_bubble_outline, 'New Group'),
          _buildMenuItem(context, 'join_group', Icons.group_add_outlined, 'Join Group'), // [新增]
          const PopupMenuDivider(),
          _buildMenuItem(context, 'add_friend', Icons.person_add_alt_1_outlined, 'Add Contact'),
          const PopupMenuDivider(),
          _buildMenuItem(context, 'contacts', Icons.contacts_outlined, 'Contacts'),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
      BuildContext context, String value, IconData icon, String text) {
    return PopupMenuItem<String>(
      value: value,
      height: 48.h,
      child: Row(
        children: [
          Icon(icon, color: context.textPrimary900, size: 20.r),
          SizedBox(width: 12.w),
          Text(text, style: TextStyle(color: context.textPrimary900, fontSize: 15.sp)),
        ],
      ),
    );
  }
}

// ------------------------------------------------------
// 组件 2: 未登录视图
// ------------------------------------------------------
class _GuestView extends StatelessWidget {
  const _GuestView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64.w, color: context.textBrandPrimary900),
          SizedBox(height: 16.h),
          Text("Login to view messages", style: TextStyle(fontSize: 14.sp, color: context.textPrimary900)),
          SizedBox(height: 24.h),
          Button(
            width: 150.w,
            radius: 20.r,
            variant: ButtonVariant.primary,
            onPressed: () => context.push('/login'),
            child: const Text("Go to Login"),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------
// 组件 3: 已登录列表视图 ( 核心修改处)
// ------------------------------------------------------
class _ConversationListView extends ConsumerStatefulWidget {
  final String searchQuery;

  const _ConversationListView({required this.searchQuery});

  @override
  ConsumerState<_ConversationListView> createState() => _ConversationListViewState();
}

class _ConversationListViewState extends ConsumerState<_ConversationListView> {
  @override
  void initState() {
    super.initState();
    //  核心修复：初始化时主动刷新一次数据
    // 解决新安装 App 数据库为空时，界面一片白且不发网络请求的问题
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationListProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversationState = ref.watch(conversationListProvider);
    final query = widget.searchQuery;

    // [DEBUG] Always print to verify build() is called with correct query
    debugPrint('[_ConversationListView] build() called, query="$query"');

    return conversationState.when(
      loading: () => _buildSkeletonList(context),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Failed to load messages: $err"),
            TextButton(
              onPressed: () => ref.read(conversationListProvider.notifier).refresh(),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
      data: (list) {
        // [DEBUG] Log conversation list data to check what's stored in IndexedDB
        debugPrint('[_ConversationListView] conversation list (${list.length} items):');
        for (final c in list) {
          debugPrint('  [${c.id}] type=${c.type} name="${c.name}" lastMsg="${c.lastMsgContent ?? ''}"');
        }

        // Apply local filtering by conversation name and last message content
        final filtered = query.isEmpty
            ? list
            : list.where((c) {
                final q = query.toLowerCase().trim();
                // Search by conversation display name
                if (c.name.toLowerCase().contains(q)) return true;
                // Also search by last message content for convenience
                if (c.lastMsgContent != null &&
                    c.lastMsgContent!.toLowerCase().contains(q)) return true;
                return false;
              }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  query.isEmpty ? Icons.chat_bubble_outline : Icons.search_off,
                  size: 48.w,
                  color: context.textPrimary900,
                ),
                SizedBox(height: 10.h),
                Text(
                  query.isEmpty ? "No messages yet" : "No conversations found",
                  style: TextStyle(color: context.textSecondary700, fontSize: 14.sp),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, _) => Divider(height: 1, indent: 72, color: context.bgPrimary),
          itemBuilder: (context, index) {
            return ConversationItem(item: filtered[index]);
          },
        );
      },
    );
  }

  Widget _buildSkeletonList(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              Skeleton.react(width: 48.r, height: 48.r, borderRadius: BorderRadius.circular(24.r)),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton.react(width: 100.w, height: 16.h),
                    SizedBox(height: 8.h),
                    Skeleton.react(width: 180.w, height: 12.h),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Skeleton.react(width: 40.w, height: 12.h),
                  SizedBox(height: 8.h),
                  Skeleton.react(width: 16.r, height: 16.r, borderRadius: BorderRadius.circular(8.r)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}