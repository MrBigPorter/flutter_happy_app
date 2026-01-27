import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/button/variant.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../toast/radix_toast.dart';
import 'models/conversation.dart';

class UserProfilePage extends ConsumerWidget {
  final String conversationId;

  const UserProfilePage({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(chatDetailProvider(conversationId));

    return BaseScaffold(
      title: "Chat Info", // 微信风格标题
      backgroundColor: context.bgSecondary, // 灰色背景
      body: asyncDetail.when(
        loading: () => _buildSkeleton(context),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (detail) {
          if (detail.type == ConversationType.group) {
            return const Center(child: Text("This is a group chat."));
          }
          return _buildContent(context, detail);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ConversationDetail detail) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // 1. 头部：单个成员+加号 (模拟微信私聊详情的"创建群聊"入口)
          Container(
            color: context.bgPrimary,
            padding: EdgeInsets.only(top: 12.h, bottom: 20.h, left: 16.w, right: 16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 对方头像
                _buildAvatarItem(context, detail.name, detail.avatar),
                SizedBox(width: 20.w),
                // 加号 (Create Group)
                _buildAddButton(context, detail),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // 2. 菜单列表
          _buildSettingsList(context, detail),

          SizedBox(height: 30.h),

          // 3. 底部危险操作 (清空/删除)
          _buildFooterButtons(context, detail),
          SizedBox(height: 50.h),
        ],
      ),
    );
  }

  // --- 1. 头像组件 (对方) ---
  Widget _buildAvatarItem(BuildContext context, String name, String? avatar) {
    return Column(
      children: [
        Container(
          width: 48.r,
          height: 48.r,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.r), // 微信方形圆角
            color: context.bgSecondary,
            image: avatar != null
                ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover)
                : null,
          ),
          child: avatar == null
              ? Icon(Icons.person, color: context.textSecondary700)
              : null,
        ),
        SizedBox(height: 6.h),
        SizedBox(
          width: 50.w, // 限制宽度防止昵称过长
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              color: context.textSecondary700,
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. 加号按钮 (建群入口) ---
  Widget _buildAddButton(BuildContext context, ConversationDetail detail) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            // 点击加号，通常是创建一个包含对方的新群
            // 逻辑：跳转选人页面，并预选中对方
            // 路由传参：preSelectedUserId
            // TODO: 需要在选人页面支持这个参数
            context.push('/chat/group/create');
          },
          child: Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              border: Border.all(color: context.borderPrimary),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Icon(Icons.add, color: context.textSecondary700),
          ),
        ),
        SizedBox(height: 6.h), // 占位保持对齐
      ],
    );
  }

  // --- 3. 菜单列表 (仿微信) ---
  Widget _buildSettingsList(BuildContext context, ConversationDetail detail) {
    return Column(
      children: [
        _buildMenuItem(
          context,
          label: "Search Chat History",
          onTap: () => RadixToast.info("Search pending"),
        ),
        SizedBox(height: 12.h), // 分割块
        _buildMenuItem(
          context,
          label: "Mute Notifications",
          isSwitch: true,
          switchValue: false, // TODO: 绑定真实状态
          onSwitchChanged: (v) => RadixToast.info("Mute API pending"),
        ),
        // 分割线逻辑：如果是连续的列表项，中间加 Divider；如果是分块的，用 SizedBox
        Container(height: 1, color: context.bgSecondary, margin: EdgeInsets.only(left: 16.w)),
        _buildMenuItem(
          context,
          label: "Pin to Top",
          isSwitch: true,
          switchValue: false, // TODO: 绑定真实状态
          onSwitchChanged: (v) => RadixToast.info("Pin API pending"),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required String label,
        VoidCallback? onTap,
        bool isSwitch = false,
        bool switchValue = false,
        ValueChanged<bool>? onSwitchChanged,
      }) {
    return InkWell(
      onTap: isSwitch ? null : onTap,
      child: Container(
        color: context.bgPrimary,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 16.sp, color: context.textPrimary900),
              ),
            ),
            if (isSwitch)
              SizedBox(
                height: 24.h,
                child: Switch(
                  value: switchValue,
                  onChanged: onSwitchChanged,
                  activeColor: context.utilityGreen500,
                ),
              )
            else
              Icon(Icons.arrow_forward_ios, size: 14.sp, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // --- 4. 底部按钮 ---
  Widget _buildFooterButtons(BuildContext context, ConversationDetail detail) {
    // 微信风格：没有 Block User，通常是 "Clear Chat History"
    // Block User 通常藏在个人资料页里，而不是聊天详情页
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Button(
        variant: ButtonVariant.ghost,
        width: double.infinity,
        onPressed: () => RadixToast.info("Clear History API pending"),
        child: Text(
          "Clear Chat History",
          style: TextStyle(color: context.utilityError500, fontSize: 16.sp),
        ),
      ),
    );
  }

  // --- 5. 骨架屏 (适配新布局) ---
  Widget _buildSkeleton(BuildContext context) {
    return Column(
      children: [
        Container(
            color: context.bgPrimary,
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Skeleton.react(width: 48.r, height: 48.r, borderRadius: BorderRadius.circular(4.r)),
                SizedBox(width: 20.w),
                Skeleton.react(width: 48.r, height: 48.r, borderRadius: BorderRadius.circular(4.r)),
              ],
            )
        ),
        SizedBox(height: 12.h),
        Container(color: context.bgPrimary, height: 50.h, width: double.infinity),
        SizedBox(height: 1.h),
        Container(color: context.bgPrimary, height: 50.h, width: double.infinity),
      ],
    );
  }
}