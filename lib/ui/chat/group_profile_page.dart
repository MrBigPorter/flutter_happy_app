import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/button/variant.dart';
import 'package:flutter_app/ui/chat/providers/contact_provider.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../toast/radix_toast.dart';
import 'models/conversation.dart';

class GroupProfilePage extends ConsumerWidget {
  final String conversationId;

  const GroupProfilePage({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听群详情数据
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
          return _buildContent(context, ref, detail, conversationId);
        },
      ),
    );
  }

  Widget _buildContent(
      BuildContext context,
      WidgetRef ref,
      ConversationDetail detail,
      String conversationId,
      ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          _buildGroupHeader(context, detail),
          SizedBox(height: 12.h),
          _buildMemberGrid(context, detail),
          SizedBox(height: 30.h),
          _buildFooterButtons(context, ref, conversationId),
          SizedBox(height: 50.h),
        ],
      ),
    );
  }

  // --- 1. 头部信息 ---
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
                  ? DecorationImage(
                image: NetworkImage(detail.avatar!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            alignment: Alignment.center,
            child: detail.avatar == null
                ? Icon(
              Icons.groups,
              size: 30.r,
              color: context.textBrandPrimary900,
            )
                : null,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.name,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "ID: ${detail.id.substring(0, 8)}...",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.textSecondary700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. 成员网格 (含拉人入口) ---
  Widget _buildMemberGrid(BuildContext context, ConversationDetail detail) {
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
            style: TextStyle(
              fontSize: 14.sp,
              color: context.textSecondary700,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 16.h,
              crossAxisSpacing: 16.w,
              childAspectRatio: 0.75,
            ),
            // +1 是为了显示末尾的“添加”按钮
            itemCount: displayCount + 1,
            itemBuilder: (context, index) {
              //  A. 添加按钮逻辑
              if (index == displayCount) {
                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        // 跳转到选人页面，并传递 groupId，触发“邀请模式”
                        context.push(
                          '/chat/group/select/member?groupId=${detail.id}',
                        );
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
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: context.textSecondary700,
                      ),
                    ),
                  ],
                );
              }

              //  B. 成员展示逻辑
              final member = members[index];
              final shortName = member.nickname.isNotEmpty
                  ? member.nickname[0].toUpperCase()
                  : "?";

              return Column(
                children: [
                  CircleAvatar(
                    radius: 24.r,
                    backgroundColor: context.bgSecondary,
                    backgroundImage: member.avatar != null
                        ? NetworkImage(member.avatar!)
                        : null,
                    child: member.avatar == null
                        ? Text(
                      shortName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: context.textSecondary700,
                      ),
                    )
                        : null,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    member.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: context.textSecondary700,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // --- 3. 底部按钮 (含退群逻辑) ---
  Widget _buildFooterButtons(
      BuildContext context,
      WidgetRef ref,
      String conversationId,
      ) {
    // 提示：此处不需要 watch state，因为 loading 状态由 Modal 内部托管
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Button(
        variant: ButtonVariant.error, // 红色警告按钮
        width: double.infinity,
        onPressed: () {
          RadixModal.show(
            title: "Leave Group", // 弹窗标题
            builder: (ctx, close) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  "Are you sure you want to delete and leave this group? This action cannot be undone.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp, color: context.textSecondary700),
                ),
              );
            },
            confirmText: 'Leave',
            //  使用 async 回调，Modal 会自动处理 Loading
            onConfirm: (close) async {
              // 1. 调用 API
              final success = await ref
                  .read(groupMemberActionControllerProvider.notifier)
                  .leaveGroup(groupId: conversationId);

              // 2. 成功才关闭弹窗并跳转
              if (success == true) {
                close();
                if (context.mounted) {
                  RadixToast.success("You have left the group.");
                  // 刷新列表缓存
                  ref.invalidate(conversationListProvider);
                  // 返回首页
                  context.go('/conversations');
                }
              }
              // 3. 失败则 Modal 自动恢复可点击状态，用户可重试
            },
          );
        },
        child: const Text("Delete and Leave"),
      ),
    );
  }

  // --- 5. 骨架屏 ---
  Widget _buildSkeleton(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          // 头部
          Container(
            color: context.bgPrimary,
            padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
            child: Row(
              children: [
                Skeleton.react(
                  width: 60.r,
                  height: 60.r,
                  borderRadius: BorderRadius.circular(8.r),
                ),
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
          // 网格
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
                      Skeleton.react(
                        width: 48.r,
                        height: 48.r,
                        borderRadius: BorderRadius.circular(24.r),
                      ),
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
}