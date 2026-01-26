import 'package:flutter/material.dart';
// 建议用 go_router 的 context 写法
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart'; // 引入 go_router
import '../chat/providers/contact_provider.dart';
import '../chat/providers/conversation_provider.dart'; // 确保引用了 Controller 定义
import '../toast/radix_toast.dart';

class ContactProfilePage extends ConsumerWidget {
  final String userId;

  const ContactProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 安全地查找用户
    final contactList = ref.watch(contactListProvider).valueOrNull ?? [];

    // 使用 Cast 或 collection 方法安全查找
    final user = contactList.where((u) => u.id == userId).firstOrNull;

    // 2. 崩溃保护：如果缓存里没这个人 (比如被删了，或者刚加载还没缓存)
    if (user == null) {
      return BaseScaffold(
        title: "Contact",
        body: Center(
          child: Text("User not found", style: TextStyle(color: context.textSecondary700)),
        ),
      );
    }

    final createDirectChatState = ref.watch(createDirectChatControllerProvider);

    return BaseScaffold(
      title: "Contact",
      backgroundColor: context.bgSecondary,
      body: Column(
        children: [
          SizedBox(height: 40.h),
          // 头像
          Center(
            child: CircleAvatar(
              radius: 50.r,
              backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
              child: user.avatar == null
                  ? Text(user.nickname[0].toUpperCase(), style: TextStyle(fontSize: 30.sp))
                  : null,
            ),
          ),
          SizedBox(height: 16.h),
          // 名字
          Text(user.nickname, style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: context.textPrimary900)),
          Text("ID: ${user.id}", style: TextStyle(color: context.textSecondary700)),

          const Spacer(),

          // 核心功能：发消息
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Button(
              loading: createDirectChatState.isLoading,
              width: double.infinity,
              onPressed: () async {
                try {
                  // 调用 Controller
                  final conversation = await ref
                      .read(createDirectChatControllerProvider.notifier)
                      .createDirectChat(user.id);

                  if (conversation != null && context.mounted) {
                    //  修正点：必须加花括号 ${}
                    // 假设 conversation 对象里的字段名确实是 conversationId
                    context.go('/chat/room/${conversation.conversationId}');
                  }
                } catch (e) {
                  RadixToast.error(e.toString());
                }
              },
              child: const Text("Send Message"),
            ),
          ),
          SizedBox(height: 50.h),
        ],
      ),
    );
  }
}