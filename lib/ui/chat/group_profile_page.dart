import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_app/ui/chat/providers/chat_group_provider.dart';
import 'package:flutter_app/ui/chat/providers/contact_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';


import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/button/variant.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import '../modal/dialog/radix_modal.dart';
import '../toast/radix_toast.dart';
import 'models/conversation.dart';
import 'models/group_role.dart';


extension ChatPermissionUIExt on List<ChatMember> {
  ChatMember? me(String myUserId) {
    try {
      return firstWhere((m) => m.userId == myUserId);
    } catch (_) {
      return null;
    }
  }

  bool isOwner(String myUserId) => me(myUserId)?.role == GroupRole.owner;

  bool isManagement(String myUserId) {
    final role = me(myUserId)?.role;
    return role == GroupRole.owner || role == GroupRole.admin;
  }

  // 是否有权管理目标成员 (踢人/禁言)
  bool canManage(String myUserId, ChatMember target) {
    final myMember = me(myUserId);
    if (myMember == null) return false;
    if (target.userId == myUserId) return false;
    return myMember.role.canManageMembers(target.role);
  }
}

// ======================================================
// 4. 页面主体
// ======================================================
class GroupProfilePage extends ConsumerWidget {
  final String conversationId;

  const GroupProfilePage({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听全能 Provider
    final asyncDetail = ref.watch(chatGroupProvider(conversationId));
    final myUserId = ref.watch(luckyProvider.select((s) => s.userInfo?.id)) ?? '';

    return BaseScaffold(
      // 动态标题
      title: asyncDetail.valueOrNull != null
          ? "Group Chat (${asyncDetail.value!.memberCount})"
          : "Group Info",
      backgroundColor: context.bgSecondary,

      // Riverpod 标准状态处理
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

  // --- 主内容区域 ---
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

          // 2. 菜单设置项
          _buildMenuSection(context, ref, detail, myUserId),
          SizedBox(height: 30.h),

          // 3. 底部危险操作按钮
          _buildFooterButtons(context, ref, detail, myUserId),
          SizedBox(height: 50.h),
        ],
      ),
    );
  }

  // --- 区域 1: 成员网格 ---
  Widget _buildMemberGrid(
      BuildContext context,
      WidgetRef ref,
      ConversationDetail detail,
      String myUserId,
      ) {
    final members = detail.members;
    // 显示全部成员 + 1个邀请按钮
    final itemCount = members.length + 1;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 0.7,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // A. 最后一个位置：邀请按钮 (+)
          if (index == members.length) {
            return _buildAddButton(context, detail);
          }

          // B. 成员头像
          final member = members[index];

          return InkWell(
            borderRadius: BorderRadius.circular(4.r),
            onTap: () {
              // 🔥 点击触发管理菜单
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
                    // 如果被禁言，显示一个小图标
                    if (member.isMuted)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: EdgeInsets.all(2.r),
                          color: Colors.white,
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

  // --- 区域 2: 菜单设置 ---
  Widget _buildMenuSection(
      BuildContext context,
      WidgetRef ref,
      ConversationDetail detail,
      String myUserId,
      ) {
    // 只有管理层能编辑群信息
    final canEdit = detail.members.isManagement(myUserId);
    final notifier = ref.read(chatGroupProvider(detail.id).notifier);

    return Column(
      children: [
        // 群名称
        _buildMenuItem(
          context,
          label: "Group Name",
          value: detail.name,
          showArrow: canEdit,
          onTap: canEdit ? () => _showEditDialog(context, "Group Name", detail.name, (val) {
            notifier.updateInfo(name: val);
          }) : null,
        ),

        // 群公告
        _buildMenuItem(
          context,
          label: "Announcement",
          value: detail.announcement?.isNotEmpty == true ? detail.announcement! : "None",
          showArrow: canEdit,
          onTap: canEdit ? () => _showEditDialog(context, "Announcement", detail.announcement ?? "", (val) {
            notifier.updateInfo(announcement: val);
          }) : null,
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
        if (detail.members.isManagement(myUserId))
          Container(
            color: context.bgPrimary,
            child: SwitchListTile(
              title: Text("Mute All Members", style: TextStyle(fontSize: 16.sp)),
              value: detail.isMuteAll, // 确保您的 ConversationDetail 有 isMuteAll 字段
              activeColor: Colors.green,
              onChanged: (val) {
                notifier.updateInfo(isMuteAll: val);
              },
            ),
          ),
      ],
    );
  }

  // --- 区域 3: 底部按钮 ---
  Widget _buildFooterButtons(
      BuildContext context,
      WidgetRef ref,
      ConversationDetail detail,
      String myUserId,
      ) {
    // 判断我是不是群主
    final isOwner = detail.ownerId == myUserId; // 或者 detail.members.isOwner(myUserId)

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Button(
        variant: ButtonVariant.error,
        width: double.infinity,
        // 群主显示解散，成员显示退群
        child: Text(isOwner ? "Disband Group" : "Delete and Leave"),
        onPressed: () {
          RadixModal.show(
            title: isOwner ? "Disband Group" : "Leave Group",
            builder: (ctx, close) => Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                isOwner
                    ? "Are you sure you want to disband this group? All members will be removed and chat history deleted."
                    : "Are you sure you want to leave this group?",
                textAlign: TextAlign.center,
              ),
            ),
            confirmText: 'Confirm',
            onConfirm: (close) async {
              close(); // 关闭弹窗

              final notifier = ref.read(chatGroupProvider(detail.id).notifier);

              if (isOwner) {
                // 解散逻辑
                final success = await notifier.disbandGroup();
                if (success && context.mounted) {
                  RadixToast.success("Group disbanded");
                  context.go('/conversations');
                }
              } else {
                // 退群逻辑 (注意：需要在 notifier 里实现 leaveGroup)
                final success = await notifier.leaveGroup();
                if (success && context.mounted) {
                  RadixToast.success("Left group");
                  context.go('/conversations');
                }
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

  // 处理成员点击
  void _handleMemberTap(
      BuildContext context,
      WidgetRef ref,
      ConversationDetail detail,
      ChatMember target,
      String myUserId
      ) {
    // 1. 如果点击自己 -> 查看个人资料 (可选)
    if (target.userId == myUserId) return;

    // 2. 权限判断：我是否有权操作他？
    if (!detail.members.canManage(myUserId, target)) {
      // 没权限，直接 return 或者显示 View Profile
      return;
    }

    // 3. 弹出管理菜单
    final notifier = ref.read(chatGroupProvider(detail.id).notifier);
    final isOwner = detail.members.isOwner(myUserId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12.r))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Manage ${target.nickname}", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Divider(height: 1),

            // 禁言/解禁
            ListTile(
              leading: Icon(Icons.mic_off_outlined, color: Colors.orange),
              title: Text(target.isMuted ? "Unmute" : "Mute (10 Minutes)"),
              onTap: () {
                Navigator.pop(ctx);
                notifier.muteMember(target.userId, target.isMuted ? 0 : 600);
              },
            ),

            // 踢人
            ListTile(
              leading: Icon(Icons.remove_circle_outline, color: Colors.red),
              title: Text("Remove from Group", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                // 二次确认
                RadixModal.show(
                    title: "Remove Member",
                    builder: (_, __) => Text("Remove ${target.nickname} from group?"),
                    onConfirm: (close) {
                      close();
                      notifier.kickMember(target.userId);
                    }
                );
              },
            ),

            // 升降管理员 (只有群主可见)
            if (isOwner)
              ListTile(
                leading: Icon(Icons.security_outlined, color: Colors.blue),
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

  // 通用输入弹窗 (改名/公告)
  void _showEditDialog(BuildContext context, String title, String initialValue, Function(String) onConfirm) {
    final controller = TextEditingController(text: initialValue);
    RadixModal.show(
      title: "Edit $title",
      builder: (ctx, close) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter new $title",
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
      ),
      confirmText: 'Save',
      onConfirm: (close) {
        if (controller.text.isNotEmpty) {
          onConfirm(controller.text);
          close();
        }
      },
    );
  }

  // --- 辅助组件 ---

  // 邀请按钮
  Widget _buildAddButton(BuildContext context, ConversationDetail detail) {
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
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Icon(Icons.add, color: context.textSecondary700),
          ),
        ),
        SizedBox(height: 4.h),
      ],
    );
  }

  // 菜单项样式
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

  // 骨架屏
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