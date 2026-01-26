import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart'; // 引入路由
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

class GroupProfilePage extends ConsumerWidget {
  final String conversationId;

  const GroupProfilePage({
    super.key,
    required this.conversationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(chatDetailProvider(conversationId));

    return BaseScaffold(
      title: "Group Info",
      backgroundColor: context.bgSecondary,
      body: asyncDetail.when(
        loading: () => _buildSkeleton(context),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (detail) {
          if (detail.type != ConversationType.group) {
            return const Center(child: Text("This is not a group."));
          }
          return _buildContent(context, ref, detail);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, ConversationDetail detail) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          _buildGroupHeader(context, detail),
          SizedBox(height: 12.h),
          _buildMemberGrid(context, detail),
          SizedBox(height: 30.h),
          _buildFooterButtons(context, ref),
          SizedBox(height: 50.h),
        ],
      ),
    );
  }

  // --- 修复点 1: 骨架屏 ---
  Widget _buildSkeleton(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          // 头部骨架
          Container(
            color: context.bgPrimary,
            padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
            child: Row(
              children: [
                Skeleton.react(width: 60.r, height: 60.r, borderRadius: BorderRadius.circular(8.r)),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton.react(width: 150.w, height: 20.h),
                      SizedBox(height: 8.h),
                      Skeleton.react(width: 100.w, height: 14.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          // 成员骨架
          Container(
            color: context.bgPrimary,
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton.react(width: 80.w, height: 16.h),
                SizedBox(height: 16.h),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 16.h,
                    crossAxisSpacing: 16.w,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: 10,
                  itemBuilder: (_, __) => Column(
                    children: [
                      Skeleton.react(width: 48.r, height: 48.r, borderRadius: BorderRadius.circular(24.r)),
                      SizedBox(height: 8.h),
                      Skeleton.react(width: 40.w, height: 10.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(BuildContext context, ConversationDetail detail) {
    return Container(
      color: context.bgPrimary,
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      child: Row(
        children: [
          Container(
            width: 60.r,
            height: 60.r,
            decoration: BoxDecoration(
              color: context.bgBrandSecondary,
              borderRadius: BorderRadius.circular(8.r),
              image: detail.avatar != null
                  ? DecorationImage(image: NetworkImage(detail.avatar!), fit: BoxFit.cover)
                  : null,
            ),
            child: detail.avatar == null
                ? Icon(Icons.groups, size: 30.r, color: context.textBrandPrimary900)
                : null,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.name,
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: context.textPrimary900),
                ),
                SizedBox(height: 4.h),
                Text(
                  "ID: ${detail.id.substring(0, 8)}...",
                  style: TextStyle(fontSize: 12.sp, color: context.textSecondary700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 修复点 2: 成员列表逻辑与布局防崩 ---
  Widget _buildMemberGrid(BuildContext context, ConversationDetail detail) {
    // 🛡️ 安全处理：防止 members 为 null
    final members = detail.members ?? [];
    final displayCount = members.length;

    return Container(
      color: context.bgPrimary,
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Members ($displayCount)",
            style: TextStyle(fontSize: 14.sp, color: context.textSecondary700, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 12.h),

          GridView.builder(
            shrinkWrap: true, // ✅ 关键：允许在 Column 中自适应高度
            physics: const NeverScrollableScrollPhysics(), // ✅ 关键：禁止内部滚动，交给外层 SingleChildScrollView
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, // 一行 5 个
              mainAxisSpacing: 16.h,
              crossAxisSpacing: 16.w,
              childAspectRatio: 0.75, // 宽高比，防止内容溢出
            ),
            // +1 是为了显示末尾的“添加”按钮
            itemCount: displayCount + 1,
            itemBuilder: (context, index) {
              // --- A. 添加按钮逻辑 ---
              if (index == displayCount) {
                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        // 🔥 逻辑实现：跳转到选人页面，把当前群ID传过去
                        // 假设选人页面支持 mode=add 参数，或者我们直接复用选人建群页面
                        // 这里演示跳转到 ContactListPage 并带上 action

                        // 方案 A: 简单弹窗提示 (如果后端没准备好)
                        // RadixToast.info("Invite API pending");

                        // 方案 B: 导航到联系人选择 (推荐)
                        // context.push('/chat/group/invite/${detail.id}');
                        // 或者临时跳到通讯录
                        context.push('/chat/contacts');
                        RadixToast.info("Please select friends to invite");
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
                    SizedBox(height: 4.h),
                    Text(
                      "Invite",
                      style: TextStyle(fontSize: 11.sp, color: context.textSecondary700),
                    )
                  ],
                );
              }

              // --- B. 成员展示 ---
              // 🛡️ 安全取值：index 保证小于 displayCount
              final member = members[index];

              // 🛡️ 名字安全截取：防止名字为空字符串导致 crash
              final shortName = member.nickname.isNotEmpty
                  ? member.nickname[0].toUpperCase()
                  : "?";

              return Column(
                children: [
                  CircleAvatar(
                    radius: 24.r,
                    backgroundColor: context.bgSecondary,
                    backgroundImage: member.avatar != null ? NetworkImage(member.avatar!) : null,
                    child: member.avatar == null
                        ? Text(shortName, style: TextStyle(fontSize: 14.sp, color: context.textSecondary700))
                        : null,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    member.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.sp, color: context.textSecondary700),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButtons(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Button(
        variant: ButtonVariant.error,
        width: double.infinity,
        onPressed: () {
          // 这里可以接入之前的 LeaveGroupController
          RadixToast.error("Leave Group API Triggered");
        },
        child: const Text("Delete and Leave"),
      ),
    );
  }
}