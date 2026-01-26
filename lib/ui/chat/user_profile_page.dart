import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart'; // 务必导入 Skeleton
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/button/variant.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../toast/radix_toast.dart';
import 'models/conversation.dart';

// 1. 改为 ConsumerStatefulWidget 以便进入时强制刷新
class UserProfilePage extends ConsumerStatefulWidget {
  final String conversationId;

  const UserProfilePage({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {

  @override
  void initState() {
    super.initState();
    // 🔥 核心：进入页面强制刷新数据，确保骨架屏出现，且数据最新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(chatDetailProvider(widget.conversationId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncDetail = ref.watch(chatDetailProvider(widget.conversationId));

    return BaseScaffold(
      title: "Contact Info",
      backgroundColor: context.bgSecondary, // 灰色背景
      body: asyncDetail.when(
        // 2. 加载中显示骨架屏
        loading: () => _buildSkeleton(context),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (detail) {
          // 容错处理
          if (detail.type == ConversationType.group) {
            return const Center(child: Text("This is a group chat."));
          }
          return _buildContent(context, detail);
        },
      ),
    );
  }

  // --- 真实内容 ---
  Widget _buildContent(BuildContext context, ConversationDetail detail) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 30.h),
          _buildUserInfo(context, detail),
          SizedBox(height: 40.h),
          _buildSettingsList(context, detail),
          SizedBox(height: 40.h),
          _buildFooterButtons(context),
          SizedBox(height: 50.h),
        ],
      ),
    );
  }

  // --- 骨架屏 (适配私聊布局) ---
  Widget _buildSkeleton(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 30.h),
          // 头像骨架
          Center(
            child: Skeleton.react(width: 100.r, height: 100.r, borderRadius: BorderRadius.circular(50.r)),
          ),
          SizedBox(height: 16.h),
          // 名字骨架
          Center(
            child: Skeleton.react(width: 150.w, height: 24.h),
          ),
          SizedBox(height: 8.h),
          // ID 骨架
          Center(
            child: Skeleton.react(width: 100.w, height: 14.h),
          ),
          SizedBox(height: 40.h),
          // 列表骨架 (模拟3行设置)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(color: context.bgPrimary, borderRadius: BorderRadius.circular(12.r)),
            child: Column(
              children: [
                _buildSkeletonRow(context),
                SizedBox(height: 20.h),
                _buildSkeletonRow(context),
                SizedBox(height: 20.h),
                _buildSkeletonRow(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonRow(BuildContext context) {
    return Row(
      children: [
        Skeleton.react(width: 30.r, height: 30.r, borderRadius: BorderRadius.circular(4.r)),
        SizedBox(width: 12.w),
        Expanded(child: Skeleton.react(width: 100.w, height: 16.h)),
        Skeleton.react(width: 20.w, height: 20.h, borderRadius: BorderRadius.circular(10.r)),
      ],
    );
  }

  // --- 下面是具体的 UI 组件 (保持原样) ---
  Widget _buildUserInfo(BuildContext context, ConversationDetail detail) {
    return Column(
      children: [
        Container(
          width: 100.r,
          height: 100.r,
          decoration: BoxDecoration(
            color: context.bgSecondary,
            shape: BoxShape.circle,
            image: detail.avatar != null
                ? DecorationImage(image: NetworkImage(detail.avatar!), fit: BoxFit.cover)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: detail.avatar == null
              ? Icon(Icons.person, size: 50.r, color: context.textSecondary700)
              : null,
        ),
        SizedBox(height: 16.h),
        Text(
          detail.name,
          style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: context.textPrimary900),
        ),
        SizedBox(height: 4.h),
        Text(
          "ID: ${detail.id.substring(0, 8)}...",
          style: TextStyle(fontSize: 14.sp, color: context.textSecondary700),
        ),
      ],
    );
  }

  Widget _buildSettingsList(BuildContext context, ConversationDetail detail) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
          color: context.bgPrimary,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
          ]
      ),
      child: Column(
        children: [
          _buildListTile(context, icon: Icons.notifications_off_outlined, title: "Mute Notifications", hasSwitch: true),
          Divider(height: 1, indent: 56.w, color: context.bgSecondary),
          _buildListTile(context, icon: Icons.push_pin_outlined, title: "Pin to Top", hasSwitch: true),
          Divider(height: 1, indent: 56.w, color: context.bgSecondary),
          _buildListTile(context, icon: Icons.search, title: "Search in Conversation"),
        ],
      ),
    );
  }

  Widget _buildListTile(BuildContext context, {
    required IconData icon,
    required String title,
    bool hasSwitch = false,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: context.bgSecondary,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, size: 20.r, color: context.textPrimary900),
      ),
      title: Text(title, style: TextStyle(fontSize: 16.sp, color: context.textPrimary900)),
      trailing: hasSwitch
          ? Switch(
        value: false,
        onChanged: (v) => RadixToast.info("Pending API"),
        activeColor: context.utilityGreen500,
      )
          : Icon(Icons.arrow_forward_ios, size: 16.r, color: context.textSecondary700),
      onTap: hasSwitch ? null : () => RadixToast.info("Coming soon"),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
    );
  }

  Widget _buildFooterButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          Button(
            variant: ButtonVariant.ghost,
            width: double.infinity,
            onPressed: () => RadixToast.info("Clear History API pending"),
            child: const Text("Clear Chat History", style: TextStyle(color: Colors.red)),
          ),
          SizedBox(height: 12.h),
          Button(
            variant: ButtonVariant.error,
            width: double.infinity,
            onPressed: () => RadixToast.error("Block User API pending"),
            child: const Text("Block User"),
          ),
        ],
      ),
    );
  }
}