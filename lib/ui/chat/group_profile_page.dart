import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart'; // 务必确保已创建此文件
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/button/variant.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

    // 🔥 照妖镜：看看控制台输出了什么？
    asyncDetail.when(
      loading: () => debugPrint("状态: Loading (应该显示骨架屏)"),
      error: (err, stack) => debugPrint("状态: Error -> $err"),
      data: (data) => debugPrint("状态: Data -> 成员数: ${data.members.length}, ID: ${data.id}"),
    );

    return BaseScaffold(
      title: "Group Info",
      // 1. 设置灰色背景，让白色卡片更突出，且视觉上充满全屏
      backgroundColor: context.bgSecondary,
      body: asyncDetail.when(
        // 2. 加载状态显示骨架屏
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

  // --- 真实内容构建 ---
  Widget _buildContent(BuildContext context, WidgetRef ref, ConversationDetail detail) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), // 保证内容少时也能弹性滚动
      child: Column(
        children: [
          // 顶部留一点间距，模仿 iOS Group Style
          SizedBox(height: 12.h),

          _buildGroupHeader(context, detail),

          SizedBox(height: 12.h),

          _buildMemberGrid(context, detail),

          SizedBox(height: 30.h),

          _buildFooterButtons(context, ref),

          // 底部留白，防止按钮贴底
          SizedBox(height: 50.h),
        ],
      ),
    );
  }

  // --- 骨架屏构建 (1:1 还原布局) ---
  Widget _buildSkeleton(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(), // 加载时禁止乱滑
      child: Column(
        children: [
          SizedBox(height: 12.h),

          // 1. 头部骨架
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
                      Skeleton.react(width: 150.w, height: 20.h, borderRadius: BorderRadius.circular(4.r)),
                      SizedBox(height: 8.h),
                      Skeleton.react(width: 100.w, height: 14.h, borderRadius: BorderRadius.circular(4.r)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // 2. 成员网格骨架
          Container(
            color: context.bgPrimary,
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton.react(width: 80.w, height: 16.h, borderRadius: BorderRadius.circular(4.r)),
                SizedBox(height: 16.h),
                // 模拟两行成员
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 16.h,
                    crossAxisSpacing: 16.w,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: 10, // 假装有10个人
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        Skeleton.react(width: 48.r, height: 48.r, borderRadius: BorderRadius.circular(24.r)),
                        SizedBox(height: 8.h),
                        Skeleton.react(width: 40.w, height: 10.h, borderRadius: BorderRadius.circular(2.r)),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 30.h),

          // 3. 按钮骨架
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Skeleton.react(width: double.infinity, height: 48.h, borderRadius: BorderRadius.circular(8.r)),
          )
        ],
      ),
    );
  }

  // --- 组件：群头部信息 ---
  Widget _buildGroupHeader(BuildContext context, ConversationDetail detail) {
    return Container(
      color: context.bgPrimary,
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      child: Row(
        children: [
          // 群头像
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
            alignment: Alignment.center,
            child: detail.avatar == null
                ? Icon(Icons.groups, size: 30.r, color: context.textBrandPrimary900)
                : null,
          ),
          SizedBox(width: 16.w),
          // 群名和 ID
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
          // 编辑按钮
          IconButton(
            icon: Icon(Icons.edit, size: 20.r, color: context.textSecondary700),
            onPressed: () {
              RadixToast.info("Edit Group Name (Coming Soon)");
            },
          ),
        ],
      ),
    );
  }

  // --- 组件：成员网格 ---
  Widget _buildMemberGrid(BuildContext context, ConversationDetail detail) {
    final members = detail.members;
    final displayCount = members.length;

    return Container(
      color: context.bgPrimary,
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Members (${members.length})",
            style: TextStyle(fontSize: 14.sp, color: context.textSecondary700, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 12.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, // 一行 5 个
              mainAxisSpacing: 16.h,
              crossAxisSpacing: 16.w,
              childAspectRatio: 0.75, // 控制高度，留出名字的空间
            ),
            itemCount: displayCount + 1, // +1 是为了显示“邀请按钮”
            itemBuilder: (context, index) {
              // 最后一个位置显示加号
              if (index == displayCount) {
                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        RadixToast.info("Invite Member (Coming Soon)");
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
                  ],
                );
              }

              final member = members[index];
              return Column(
                children: [
                  CircleAvatar(
                    radius: 24.r,
                    backgroundColor: context.bgSecondary,
                    backgroundImage: member.avatar != null ? NetworkImage(member.avatar!) : null,
                    child: member.avatar == null ? Text(member.nickname[0].toUpperCase()) : null,
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

  // --- 组件：底部按钮 ---
  Widget _buildFooterButtons(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Button(
        // 如果你的 ButtonVariant 枚举里没有 error，请改回 destructive
        variant: ButtonVariant.error,
        width: double.infinity,
        onPressed: () {
          RadixToast.error("Leave Group (Api Pending)");
        },
        child: const Text("Delete and Leave"),
      ),
    );
  }
}