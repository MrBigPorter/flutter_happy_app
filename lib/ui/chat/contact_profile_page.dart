import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/store/user_store.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart'; // 确保引入了 ChatUser
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../chat/providers/contact_provider.dart';
import '../chat/providers/conversation_provider.dart';
import '../toast/radix_toast.dart';

class ContactProfilePage extends ConsumerWidget {
  final String userId;
  final ChatUser? cachedUser; // 接收群聊/列表传过来的预览数据

  const ContactProfilePage({
    super.key,
    required this.userId,
    this.cachedUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 获取自己 ID
    final myId = ref.watch(userProvider.select((s) => s?.id));
    final isMe = (myId == userId);

    // 2. 优先读通讯录 (数据最新，且确认为好友)
    final contactList = ref.watch(contactListProvider).valueOrNull ?? [];
    final contactUser = contactList.where((u) => u.id == userId).firstOrNull;


    // 3. 数据优先级：通讯录 > 传参预览
    // 如果都不存在，说明既不是好友，也没预览数据，那就显示 Not found
    final displayUser = contactUser ?? cachedUser;

    if (displayUser == null) {
      return const BaseScaffold(
        title: "",
        body: Center(child: Text("User not found")),
      );
    }

    final isLoadingChat = ref.watch(createDirectChatControllerProvider).isLoading;

    return BaseScaffold(
      title: "", // 微信风格：标题栏留空，让背景色通顶
      backgroundColor: context.bgSecondary,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // 区域 1：头部个人信息卡片
            _buildUserInfoHeader(context, displayUser),

            SizedBox(height: 12.h),

            // 区域 2：功能菜单列表
            _buildActionMenu(context),

            SizedBox(height: 30.h),

            // 区域 3：底部操作按钮 (如果是自己则不显示)
            if (!isMe)
              _buildBottomButtons(context, ref, displayUser.id, isLoadingChat),

            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }

  // --- 微信风格头部卡片 ---
  Widget _buildUserInfoHeader(BuildContext context, ChatUser user) {
    return Container(
      color: context.bgPrimary,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hero 动画：tag 必须和上一个页面里头像的 tag 一致
          Hero(
            tag: 'avatar_${user.id}',
            child: Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: context.bgSecondary,
                image: user.avatar != null
                    ? DecorationImage(
                  image: CachedNetworkImageProvider(user.avatar!),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: user.avatar == null
                  ? Center(
                child: Text(
                  user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : "?",
                  style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: context.textSecondary700),
                ),
              )
                  : null,
            ),
          ),
          SizedBox(width: 20.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 昵称
                Text(
                  user.nickname,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary900,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                // ID (可点击复制)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: user.id));
                    RadixToast.success("ID copied");
                  },
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          "ID: ${user.id}",
                          style: TextStyle(fontSize: 14.sp, color: context.textSecondary700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(Icons.copy, size: 12.sp, color: context.textSecondary700),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),
                Text("Region: Earth", style: TextStyle(fontSize: 14.sp, color: context.textSecondary700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 功能菜单 ---
  Widget _buildActionMenu(BuildContext context) {
    return Column(
      children: [
        _MenuItem(title: "Set Remark and Tag", onTap: () {}),
        SizedBox(height: 12.h),
        _MenuItem(title: "Moments", onTap: () {}),
        _MenuItem(title: "More Info", isLast: true, onTap: () {}),
      ],
    );
  }

  // --- 底部按钮 ---
  // 既然不做陌生人，那么能进来的基本都是为了发消息，移除了 "Add Friend" 逻辑
  Widget _buildBottomButtons(BuildContext context, WidgetRef ref, String targetId, bool isLoading) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          // 主按钮：发消息
          Button(
            width: double.infinity,
            loading: isLoading,
            onPressed: () async {
              // 调用 Controller 创建或获取 Direct 会话
              final conversation = await ref
                  .read(createDirectChatControllerProvider.notifier)
                  .createDirectChat(targetId);

              if (conversation != null && context.mounted) {
                // 跳转聊天页
                context.push('/chat/room/${conversation.conversationId}');
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 20.sp),
                SizedBox(width: 8.w),
                const Text("Send Message"),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // 次要按钮：音视频通话
          InkWell(
            onTap: () => RadixToast.info("Call feature pending"),
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              width: double.infinity,
              height: 48.h, // 高度与 Button 保持一致
              decoration: BoxDecoration(
                color: context.bgPrimary,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: context.borderPrimary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_outlined, size: 22.sp, color: context.textPrimary900),
                  SizedBox(width: 8.w),
                  Text(
                    "Voice or Video Call",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final bool isLast;

  const _MenuItem({required this.title, this.onTap, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.bgPrimary,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          decoration: BoxDecoration(
            border: isLast ? null : Border(bottom: BorderSide(color: context.borderPrimary, width: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16.sp, color: context.textPrimary900),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14.sp, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}