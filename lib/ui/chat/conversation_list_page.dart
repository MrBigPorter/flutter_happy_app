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

    //  [双保险]：进入列表页立即清理
    final currentActive = ref.read(activeConversationIdProvider);

    // 必须加判断，否则无限循环
    if (currentActive != null) {
      //  必须包在 microtask 里！
      Future.microtask(() {
        ref.read(activeConversationIdProvider.notifier).state = null;
      });
    }

    return BaseScaffold(
      title: 'Chats',
      actions: [
        const _AddMenuButton(),
      ],
      body:Column(
        children: [
          // A. 放入网络状态条 (放在最顶部)
          const NetworkStatusBar(),

          // B. 放入原来的内容 (必须用 Expanded 撑开，否则 ListView 会报错)
          Expanded(
            child: isLoggedIn ? const _ConversationListView() : const _GuestView(),
          ),
        ],
      ),
    );
  }
}

//  提取：右上角菜单按钮 (保持主文件干净)
class _AddMenuButton extends StatelessWidget {
  const _AddMenuButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: PopupMenuButton<String>(
        icon:  Icon(Icons.add_circle_outline, size: 24.w, color: context.textPrimary900),
        offset: Offset(0, 45.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        color: context.bgPrimary,
        onSelected: (value) {
          switch(value) {
            case 'contacts':
              // 打开通讯录页面
              appRouter.push('/chat/contacts');
              break;
              case 'group':
                appRouter.push('/chat/group/select/member');
              break;
              case 'friend':
                // 打开搜索用户对话框
                showDialog(context: context, builder: (_) => const UserSearchDialog());
              break;
          }
        },
        itemBuilder: (context) => [
          _buildMenuItem(context,'group', Icons.chat_bubble_outline, 'New Chat'), // 发起群聊
           PopupMenuDivider(
             color: context.borderPrimary,
           ),
          _buildMenuItem(context,'friend', Icons.person_add_alt_1_outlined, 'Add Contact'), // 添加朋友/搜索用户
          PopupMenuDivider(
            color: context.borderPrimary,
          ),
          _buildMenuItem(context,'contacts', Icons.contacts, 'Contacts'),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
      BuildContext context,
      String value,
      IconData icon,
      String text,
      ) {
    return PopupMenuItem<String>(
      value: value,
      height: 48.h, // 稍微调高一点，手指好点
      child: Row(
        children: [
          Icon(icon, color: context.textPrimary900, size: 20.r), // 图标
          SizedBox(width: 12.w),
          Text(
            text,
            style: TextStyle(
              color: context.textPrimary900,
              fontSize: 15.sp,
            ),
          ),
        ],
      ),
    );
  }
}

//  提取：未登录视图
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

//  提取：已登录列表视图
class _ConversationListView extends ConsumerWidget {
  const _ConversationListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 监听会话列表的异步状态
    final conversationState = ref.watch(conversationListProvider);

    return conversationState.when(
      //  A. 加载中：显示骨架屏
      loading: () => _buildSkeletonList(context),

      // B. 出错：显示错误提示与重试按钮
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Failed to load messages: $err"),
            TextButton(
              onPressed: () => ref.invalidate(conversationListProvider),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),

      // C. 数据就绪
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

  //  2. 构建会话列表骨架屏
  Widget _buildSkeletonList(BuildContext context) {
    return ListView.builder(
      itemCount: 10, // 默认显示 10 条占位图
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              // 头像骨架 (48x48 圆形)
              Skeleton.react(
                width: 48.r,
                height: 48.r,
                borderRadius: BorderRadius.circular(24.r),
              ),
              SizedBox(width: 12.w),
              // 中间文字骨架
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名字
                    Skeleton.react(width: 100.w, height: 16.h),
                    SizedBox(height: 8.h),
                    // 最后一条消息预览
                    Skeleton.react(width: 180.w, height: 12.h),
                  ],
                ),
              ),
              // 右侧时间与未读数骨架
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Skeleton.react(width: 40.w, height: 12.h),
                  SizedBox(height: 8.h),
                  Skeleton.react(
                    width: 16.r,
                    height: 16.r,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}