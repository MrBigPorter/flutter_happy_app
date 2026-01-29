import 'package:cached_network_image/cached_network_image.dart';
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

import '../../utils/image_url.dart';
import '../toast/radix_toast.dart';
import 'models/conversation.dart';

class GroupProfilePage extends ConsumerWidget {
  final String conversationId;

  const GroupProfilePage({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(chatDetailProvider(conversationId));
    

    return BaseScaffold(
      // 微信风格：标题通常显示 "Chat Info" 或 "Group Chat(N)"
      title: asyncDetail.valueOrNull != null
          ? "Group Chat (${asyncDetail.value!.memberCount})"
          : "Group Info",
      backgroundColor: context.bgSecondary, // 灰色背景
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
          // 1. 微信风格：成员网格直接置顶 (背景为白色)
          Container(
            color: context.bgPrimary, // 白色背景
            padding: EdgeInsets.only(top: 12.h, bottom: 20.h),
            child: _buildMemberGrid(context, detail),
          ),

          SizedBox(height: 12.h), // 灰色间隔

          // 2. 菜单区域 (群名、ID)
          _buildMenuSection(context, detail),

          SizedBox(height: 30.h),

          // 3. 底部按钮
          _buildFooterButtons(context, ref, conversationId),
          SizedBox(height: 50.h),
        ],
      ),
    );
  }

  // --- 1. 成员网格 (保持原有逻辑，去除外层 Container 的多余 padding) ---
  Widget _buildMemberGrid(BuildContext context, ConversationDetail detail) {
    final members = detail.members ?? [];
    final displayCount = members.length;

    // 微信逻辑：
    // 如果成员很多，通常只显示前 15-20 个，后面加个 "查看更多"
    // 这里暂时不做限制，直接全部展示

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 0.7, // 调整比例适配头像+名字
        ),
        // +1 是添加按钮
        itemCount: displayCount + 1,
        itemBuilder: (context, index) {
          // A. 添加按钮 (+)
          if (index == displayCount) {
            return Column(
              children: [
                InkWell(
                  onTap: () {
                    context.push('/chat/group/select/member?groupId=${detail.id}');
                  },
                  child: Container(
                    width: 48.r,
                    height: 48.r,
                    decoration: BoxDecoration(
                      border: Border.all(color: context.borderPrimary),
                      borderRadius: BorderRadius.circular(4.r), // 微信是微圆角
                    ),
                    child: Icon(Icons.add, color: context.textSecondary700),
                  ),
                ),
                // 占位，保持对齐
                SizedBox(height: 4.h),
              ],
            );
          }

          // B. 成员头像
          final member = members[index];
          final shortName = member.nickname.isNotEmpty
              ? member.nickname[0].toUpperCase()
              : "?";

          return Column(
            children: [
              // 头像
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.r), // 微信风格头像圆角较小
                  color: context.borderPrimary,
                  image: member.avatar != null
                      ? DecorationImage(
                    image: CachedNetworkImageProvider(
                      ImageUrl.build(
                        context,
                        member.avatar!,
                        logicalWidth: 48, // 容器宽 48
                      ),
                    ),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                alignment: Alignment.center,
                child: member.avatar == null
                    ? Text(shortName, style: TextStyle(color: context.textSecondary700))
                    : null,
              ),
              SizedBox(height: 6.h),
              // 昵称
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
    );
  }

  // --- 2. 菜单区域 (仿微信 Group Name, QR Code, etc) ---
  Widget _buildMenuSection(BuildContext context, ConversationDetail detail) {
    return Column(
      children: [
        _buildMenuItem(
          context,
          label: "Group Name",
          value: detail.name,
          onTap: () {
            // TODO: 跳转修改群名
            RadixToast.info("Edit Group Name");
          },
        ),
        _buildMenuItem(
          context,
          label: "Group ID",
          // ID 通常截取一下显示
          value: detail.id.substring(0, 8).toUpperCase(),
          showArrow: false, // ID 不可修改，不显示箭头
          isLast: true, // 最后一项去掉分割线
        ),
        // 这里可以继续加 "My Alias in Group", "Mute Notifications" 等
      ],
    );
  }

  // 通用菜单项组件
  Widget _buildMenuItem(
      BuildContext context, {
        required String label,
        required String value,
        VoidCallback? onTap,
        bool showArrow = true,
        bool isLast = false,
      }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: context.bgPrimary, // 白色背景
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                color: context.textPrimary900,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: context.textSecondary700,
                ),
              ),
            ),
            if (showArrow) ...[
              SizedBox(width: 8.w),
              Icon(Icons.arrow_forward_ios, size: 14.sp, color: Colors.grey[400]),
            ],
          ],
        ),
      ),
    );
  }

  // --- 3. 底部按钮 (保持不变) ---
  Widget _buildFooterButtons(BuildContext context, WidgetRef ref, String conversationId) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Button(
        variant: ButtonVariant.error, // 红色按钮
        width: double.infinity,
        // 样式微调：微信的退群按钮通常是白底红字 (Outline) 或 红底白字，这里保持原来的
        child: const Text("Delete and Leave"),
        onPressed: () {
          RadixModal.show(
            title: "Leave Group",
            builder: (ctx, close) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                "Delete and leave this group?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: context.textSecondary700),
              ),
            ),
            confirmText: 'Leave',
            onConfirm: (close) async {
              final success = await ref
                  .read(groupMemberActionControllerProvider.notifier)
                  .leaveGroup(groupId: conversationId);
              if (success == true) {
                close();
                if (context.mounted) {
                  RadixToast.success("Left group");
                  ref.invalidate(conversationListProvider);
                  context.go('/conversations');
                }
              }
            },
          );
        },
      ),
    );
  }

  // --- 4. 骨架屏 (适配新布局) ---
  Widget _buildSkeleton(BuildContext context) {
    return Column(
      children: [
        Container(
          color: context.bgPrimary,
          padding: EdgeInsets.all(16.w),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
            ),
            itemCount: 10,
            itemBuilder: (_, __) => Skeleton.react(
                width: 48.r, height: 48.r, borderRadius: BorderRadius.circular(4.r)
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Container(color: context.bgPrimary, height: 50.h, width: double.infinity),
        SizedBox(height: 1.h),
        Container(color: context.bgPrimary, height: 50.h, width: double.infinity),
      ],
    );
  }
}