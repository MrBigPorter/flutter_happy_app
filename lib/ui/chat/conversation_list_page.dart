import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/ui/chat/components/user_search_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';

import '../../components/network_status_bar.dart';
import 'components/conversation_item.dart';
import 'components/create_group_dialog.dart';



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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: isLoggedIn ? const [_AddMenuButton()] : null, // 提取菜单按钮
      ),
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
        icon: const Icon(Icons.add_circle_outline),
        offset: Offset(0, 45.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        onSelected: (value) {
          if (value == 'group') {
            // 建群
           appRouter.push('/chat/group/select/member');
          } else if (value == 'friend') {
            //  核心修改在这里：
            // 点击 "Add Contact" -> 弹出搜索窗口，而不是输入ID窗口
            showDialog(context: context, builder: (_) => const UserSearchDialog());
          }
        },
        itemBuilder: (context) => [
          _buildMenuItem('group', Icons.chat_bubble_outline, 'New Chat'), // 发起群聊
          const PopupMenuDivider(),
          _buildMenuItem('friend', Icons.person_add_alt_1_outlined, 'Add Contact'), // 添加朋友/搜索用户
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, IconData icon, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20.w, color: Colors.black87),
          SizedBox(width: 12.w),
          Text(text, style: TextStyle(fontSize: 14.sp)),
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
          Icon(Icons.lock_outline, size: 64.w, color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Text("Login to view messages", style: TextStyle(fontSize: 14.sp, color: Colors.grey[600])),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => context.push('/login'),
            style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h)),
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
    final list = ref.watch(conversationListProvider);
    
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48.w, color: Colors.grey[300]),
            SizedBox(height: 10.h),
            Text("No messages yet", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        // 🔥 使用抽离的 Item 组件
        return ConversationItem(item: list[index]);
      },
    );
  }
}