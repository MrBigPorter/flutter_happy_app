import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/button/variant.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import '../modal/dialog/radix_modal.dart';
import '../toast/radix_toast.dart';

// --- 核心模型与 Provider ---
import 'package:flutter_app/ui/chat/providers/chat_group_provider.dart';
import 'core/extensions/chat_permissions.dart';
import 'models/conversation.dart';
import 'models/group_role.dart';

// ======================================================
// 页面主体
// ======================================================
class GroupProfilePage extends ConsumerWidget {
  final String conversationId;

  const GroupProfilePage({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 监听全能 Provider (AsyncNotifier)
    final asyncDetail = ref.watch(chatGroupProvider(conversationId));

    // 2. 获取当前登录用户 ID
    final myUserId = ref.watch(luckyProvider.select((s) => s.userInfo?.id)) ?? '';

    return BaseScaffold(
      // 动态标题: 显示人数
      title: asyncDetail.valueOrNull != null
          ? "Group Chat (${asyncDetail.value!.memberCount})"
          : "Group Info",
      backgroundColor: context.bgSecondary,

      // Riverpod 标准状态处理 (Loading / Error / Data)
      body: asyncDetail.when(
        loading: () => _buildSkeleton(context),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (detail) {
          if (detail.type != ConversationType.group) {
            return const Center(child: Text("This is not a group."));
          }
          return _buildContent(context, ref, detail, myUserId);
        },
      ),
    );
  }

  // --- 主内容区域 (滚动视图) ---
  Widget _buildContent(
      BuildContext context,
      WidgetRef ref,
      ConversationDetail detail,
      String myUserId,
      ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // 1. 成员网格 (白色背景)
          Container(
            color: context.bgPrimary,
            padding: EdgeInsets.only(top: 12.h, bottom: 20.h),
            child: _buildMemberGrid(context, ref, detail, myUserId),
          ),
          SizedBox(height: 12.h),

          // 2. 菜单设置项 (群名、公告、开关)
          _buildMenuSection(context, ref, detail, myUserId),
          SizedBox(height: 30.h),

          // 3. 底部危险操作按钮 (退群/解散)
          _buildFooterButtons(context, ref, detail, myUserId),
          SizedBox(height: 50.h),
        ],
      ),
    );
  }

  // ======================================================
  // 区域 1: 成员网格
  // ======================================================
  Widget _buildMemberGrid(
      BuildContext context,
      WidgetRef ref,
      ConversationDetail detail,
      String myUserId,
      ) {
    final members = detail.members;
    final itemCount = members.length + 1; // +1 是邀请按钮

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 0.7, // 调整宽高比以适配头像+名字
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // A. 最后一个位置：显示邀请按钮 (+)
          if (index == members.length) {
            return _buildAddButton(context, detail);
          }

          // B. 显示成员头像
          final member = members[index];
          return InkWell(
            borderRadius: BorderRadius.circular(4.r),
            onTap: () {
              // 点击触发管理菜单 (核心交互)
              _handleMemberTap(context, ref, detail, member, myUserId);
            },
            child: Column(
              children: [
                // 头像容器
                Stack(
                  children: [
                    Container(
                      width: 48.r,
                      height: 48.r,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.r),
                        color: context.borderPrimary,
                        image: member.avatar != null
                            ? DecorationImage(
                          image: CachedNetworkImageProvider(
                            UrlResolver.resolveImage(context, member.avatar!, logicalWidth: 48),
                          ),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: member.avatar == null
                          ? Text(
                        member.nickname.isNotEmpty ? member.nickname[0] : "?",
                        style: TextStyle(color: context.textSecondary700),
                      )
                          : null,
                    ),
                    // 禁言状态图标
                    if (member.isMuted)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: EdgeInsets.all(2.r),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Icon(Icons.mic_off, size: 12.r, color: Colors.red),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 6.h),
                // 昵称
                Text(
                  member.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: member.isMuted ? Colors.red : context.textSecondary700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ======================================================
  // 区域 2: 菜单设置 (名称、公告、全员禁言)
  // ======================================================
  Widget _buildMenuSection(
      BuildContext context,
      WidgetRef ref,
      ConversationDetail detail,
      String myUserId,
      ) {
    // 架构核心：先找到"我"，再问"我"是不是管理层
    final me = detail.members.findMember(myUserId);
    final canEdit = me != null && me.isManagement; // Model 内置逻辑

    final notifier = ref.read(chatGroupProvider(detail.id).notifier);

    return Column(
      children: [
        // 群名称
        _buildMenuItem(
          context,
          label: "Group Name",
          value: detail.name,
          showArrow: canEdit,
          onTap: canEdit
              ? () => _showEditDialog(context, "Group Name", detail.name, (val) {
            notifier.updateInfo(name: val);
          })
              : null,
        ),

        // 群公告
        _buildMenuItem(
          context,
          label: "Announcement",
          value: detail.announcement?.isNotEmpty == true ? detail.announcement! : "None",
          showArrow: canEdit,
          onTap: canEdit
              ? () => _showEditDialog(context, "Announcement", detail.announcement ?? "", (val) {
            notifier.updateInfo(announcement: val);
          })
              : null,
        ),

        // 群 ID (只读)
        _buildMenuItem(
          context,
          label: "Group ID",
          value: detail.id.substring(0, 8).toUpperCase(),
          showArrow: false,
        ),

        SizedBox(height: 12.h),

        // 全员禁言开关 (仅管理层可见)
        if (canEdit)
          Container(
            color: context.bgPrimary,
            child: SwitchListTile(
              title: Text("Mute All Members", style: TextStyle(fontSize: 16.sp)),
              value: detail.isMuteAll, // 依赖 ConversationDetail 字段
              activeColor: Colors.green,
              onChanged: (val) {
                notifier.updateInfo(isMuteAll: val);
              },
            ),
          ),
      ],
    );
  }

  // ======================================================
  // 区域 3: 底部按钮 (退群/解散)
  // ======================================================
  Widget _buildFooterButtons(
      BuildContext context,
      WidgetRef ref,
      ConversationDetail detail,
      String myUserId,
      ) {
    // 架构核心：判断我是不是群主 (Model 内置逻辑)
    // 也可以直接用 detail.ownerId == myUserId
    final me = detail.members.findMember(myUserId);
    final isOwner = me?.isOwner ?? false;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Button(
        variant: ButtonVariant.error,
        width: double.infinity,
        child: Text(isOwner ? "Disband Group" : "Delete and Leave"),
        onPressed: () {
          RadixModal.show(
            title: isOwner ? "Disband Group" : "Leave Group",
            builder: (ctx, close) => Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                isOwner
                    ? "Are you sure you want to disband this group? All members will be removed."
                    : "Are you sure you want to leave this group?",
                textAlign: TextAlign.center,
              ),
            ),
            confirmText: 'Confirm',
            onConfirm: (close) async {
              close(); // 关闭弹窗

              // 统一使用 ChatGroup Notifier
              final notifier = ref.read(chatGroupProvider(detail.id).notifier);

              bool success = false;
              if (isOwner) {
                success = await notifier.disbandGroup();
              } else {
                success = await notifier.leaveGroup();
              }

              if (success && context.mounted) {
                RadixToast.success(isOwner ? "Group disbanded" : "Left group");
                context.go('/conversations');
              }
            },
          );
        },
      ),
    );
  }

  // ======================================================
  // 交互逻辑 (Action Logic)
  // ======================================================

  void _handleMemberTap(
      BuildContext context,
      WidgetRef ref,
      ConversationDetail detail,
      ChatMember target,
      String myUserId,
      ) {
    // 1. 如果点击自己 -> 不做操作 (或跳转个人资料)
    if (target.userId == myUserId) return;

    // 架构核心：使用 Extension 找到"我"
    final me = detail.members.findMember(myUserId);
    if (me == null) return;

    // 架构核心：使用 Model 判断权限 (Level Check)
    // 只有当我等级 > 对方等级时，才能操作
    if (!me.canManage(target)) {
      return;
    }

    // 2. 准备数据
    final notifier = ref.read(chatGroupProvider(detail.id).notifier);
    final isOwner = me.isOwner;

    // 3. 弹出 ActionSheet
    showModalBottomSheet(
      context: context,
      backgroundColor: context.bgPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12.r))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Manage ${target.nickname}", style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary900)),
            ),
             Divider(height: 1, color:context.borderPrimary),

            // 禁言/解禁
            ListTile(
              leading: const Icon(Icons.mic_off_outlined, color: Colors.orange),
              title: Text(target.isMuted ? "Unmute" : "Mute (10 Minutes)", style: TextStyle(color: context.textBrandPrimary900)),
              onTap: () {
                Navigator.pop(ctx);
                notifier.muteMember(target.userId, target.isMuted ? 0 : 600);
              },
            ),

            // 踢人
            ListTile(
              leading:  Icon(Icons.remove_circle_outline, color: context.utilityError200),
              title:  Text("Remove from Group", style: TextStyle(color:context.utilityError200)),
              onTap: () {
                Navigator.pop(ctx);
                RadixModal.show(
                  title: "Remove Member",
                  builder: (_, __) => Text("Remove ${target.nickname} from group?", style: TextStyle(color: context.textPrimary900),),
                  confirmText: "Remove",
                  onConfirm: (close) {
                    close();
                    notifier.kickMember(target.userId);
                  },
                );
              },
            ),

            // 升降管理员 (仅群主可见)
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.security_outlined, color: Colors.blue),
                title: Text(target.role == GroupRole.admin ? "Dismiss Admin" : "Make Admin"),
                onTap: () {
                  Navigator.pop(ctx);
                  notifier.setAdmin(target.userId, target.role != GroupRole.admin);
                },
              ),

            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  // --- 辅助方法: 编辑弹窗 ---
  void _showEditDialog(BuildContext context, String title, String initialValue, Function(String) onConfirm) {
    final controller = TextEditingController(text: initialValue);
    RadixModal.show(
      title: "Edit $title",
      builder: (ctx, close) => Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "Enter new $title",
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ),
      ),
      confirmText: 'Save',
      onConfirm: (close) {
        if (controller.text.trim().isNotEmpty) {
          onConfirm(controller.text.trim());
          close();
        }
      },
    );
  }

  // --- 辅助组件: 邀请按钮 ---
  Widget _buildAddButton(BuildContext context, ConversationDetail detail) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            // 跳转到选人页面，带上当前群组 ID 以启用"邀请模式"
            context.push('/chat/group/select/member?groupId=${detail.id}');
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
      ],
    );
  }

  // --- 辅助组件: 菜单项 ---
  Widget _buildMenuItem(
      BuildContext context, {
        required String label,
        required String value,
        VoidCallback? onTap,
        bool showArrow = true,
      }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: context.bgPrimary,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 16.sp, color: context.textPrimary900)),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15.sp, color: context.textSecondary700),
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

  // --- 骨架屏 ---
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
                width: 48.r, height: 48.r, borderRadius: BorderRadius.circular(4.r)),
          ),
        ),
        SizedBox(height: 12.h),
        Container(color: context.bgPrimary, height: 50.h, width: double.infinity),
      ],
    );
  }
}

