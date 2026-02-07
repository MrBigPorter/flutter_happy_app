import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
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

class ConversationListPage extends ConsumerWidget {
  const ConversationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider.select((s) => s.isAuthenticated));

    // [双保险]：进入列表页立即清理选中状态
    final currentActive = ref.read(activeConversationIdProvider);
    if (currentActive != null) {
      Future.microtask(() {
        ref.read(activeConversationIdProvider.notifier).state = null;
      });
    }

    return BaseScaffold(
      title: 'Chats',
      actions: [
        const _AddMenuButton(),
      ],
      body: Column(
        children: [
          // A. 网络状态条
          const NetworkStatusBar(),

          // B. 会话列表
          Expanded(
            child: isLoggedIn ? const _ConversationListView() : const _GuestView(),
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
            case 'contacts':
              appRouter.push('/chat/contacts');
              break;
            case 'group':
              appRouter.push('/chat/group/select/member');
              break;
            case 'friend':
              showDialog(context: context, builder: (_) => const UserSearchDialog());
              break;
          }
        },
        itemBuilder: (context) => [
          _buildMenuItem(context, 'group', Icons.chat_bubble_outline, 'New Chat'),
          PopupMenuDivider(color: context.borderPrimary),
          _buildMenuItem(context, 'friend', Icons.person_add_alt_1_outlined, 'Add Contact'),
          PopupMenuDivider(color: context.borderPrimary),
          _buildMenuItem(context, 'contacts', Icons.contacts, 'Contacts'),
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
// 组件 3: 已登录列表视图 (🔥🔥🔥 核心修改处)
// ------------------------------------------------------
class _ConversationListView extends ConsumerStatefulWidget {
  const _ConversationListView();

  @override
  ConsumerState<_ConversationListView> createState() => _ConversationListViewState();
}

class _ConversationListViewState extends ConsumerState<_ConversationListView> {
  @override
  void initState() {
    super.initState();
    // 🔥🔥🔥 核心修复：初始化时主动刷新一次数据 🔥🔥🔥
    // 解决新安装 App 数据库为空时，界面一片白且不发网络请求的问题
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationListProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversationState = ref.watch(conversationListProvider);

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
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 48.w, color: context.textPrimary900),
                SizedBox(height: 10.h),
                Text("No messages yet", style: TextStyle(color: context.textSecondary700, fontSize: 14.sp)),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => Divider(height: 1, indent: 72, color: context.bgPrimary),
          itemBuilder: (context, index) {
            return ConversationItem(item: list[index]);
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