part of 'group_profile_page.dart';

// ======================================================
// 区域 1: 成员网格 (已优化排序)
// ======================================================
class _MemberGrid extends ConsumerWidget {
  final ConversationDetail detail;
  final String myUserId;

  const _MemberGrid({required this.detail, required this.myUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 执行排序逻辑 (UI层展示优化)
    // 权重: 群主(3) > 管理员(2) > 普通成员(1)
    final sortedMembers = [...detail.members];
    sortedMembers.sort((a, b) {
      int getScore(ChatMember m) {
        if (m.role == GroupRole.owner) return 3;
        if (m.role == GroupRole.admin) return 2;
        return 1;
      }
      return getScore(b) - getScore(a); // 降序排列
    });

    final bool showAddBtn = true;
    final itemCount = sortedMembers.length + (showAddBtn ? 1 : 0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 16.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 0.68,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // A. 邀请按钮 (始终在最后)
          if (showAddBtn && index == sortedMembers.length) {
            return _AddButton(detail: detail);
          }

          // B. 成员头像
          final member = sortedMembers[index];
          final isMe = member.userId == myUserId;

          return InkWell(
            borderRadius: BorderRadius.circular(8.r),
            onTap: () {
              _GroupProfileLogic.handleMemberTap(
                  context, ref, detail, member, myUserId);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 头像 Stack
                SizedBox(
                  width: 48.r,
                  height: 48.r,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 头像本体
                      Container(
                        width: 48.r,
                        height: 48.r,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          color: context.borderPrimary,
                          image: member.avatar != null
                              ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              UrlResolver.resolveImage(
                                  context, member.avatar!,
                                  logicalWidth: 48),
                            ),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: member.avatar == null
                            ? Text(
                          member.nickname.isNotEmpty
                              ? member.nickname[0].toUpperCase()
                              : "?",
                          style: TextStyle(
                              color: context.textSecondary700,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold),
                        )
                            : null,
                      ),

                      // 禁言遮罩
                      if (member.isMuted)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(Icons.mic_off,
                                size: 20.r, color: Colors.white),
                          ),
                        ),

                      // 身份角标
                      if (member.isOwner)
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: _RoleBadge(
                              color: Colors.orange, icon: Icons.star),
                        )
                      else if (member.isAdmin)
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: _RoleBadge(
                              color: Colors.blue, icon: Icons.security),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 6.h),
                // 昵称
                Text(
                  isMe ? "You" : member.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: member.isMuted
                        ? context.utilityError200
                        : (member.isManagement
                        ? context.textPrimary900
                        : context.textSecondary700),
                    fontWeight: member.isManagement
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ======================================================
// 区域 2: 菜单部分 (增加头像和审批开关)
// ======================================================
class _MenuSection extends ConsumerWidget {
  final ConversationDetail detail;
  final String myUserId;

  const _MenuSection({required this.detail, required this.myUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = detail.members.findMember(myUserId);
    final canEdit = me != null && me.isManagement;
    final notifier = ref.read(chatGroupProvider(detail.id).notifier);

    return Column(
      children: [
        // 1. 核心管理入口 (仅管理员可见)
        // =================================================
        if (canEdit) ...[
          Container(
            margin: EdgeInsets.only(bottom: 12.h),
            color: context.bgPrimary,
            child: Column(
              children: [
                // [NEW] 入群申请入口
                Consumer(
                  builder: (context, ref, _) {
                    final count = ref.watch(groupRequestCountProvider(detail.id));

                    return _MenuItem(
                      label: "Join Requests",
                      showArrow: true,
                      trailing: count > 0
                          ? Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: context.utilityError200, // 红色
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      )
                          : null,
                      onTap: () {
                        // 清除红点 (可选)
                        ref.read(groupRequestCountProvider(detail.id).notifier).clear();
                        // 跳转到申请列表页 (路由稍后注册)
                        context.push('/chat/group/requests/${detail.id}');
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
        // 1. 群头像 (新增)
        _MenuItem(
          label: "Group Avatar",
          showArrow: canEdit,
          // 如果有头像，显示图片；否则显示文字提示
          trailing: detail.avatar != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: CachedNetworkImage(
              imageUrl: UrlResolver.resolveImage(context, detail.avatar!, logicalWidth: 40),
              width: 32.r,
              height: 32.r,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.grey[200]),
            ),
          )
              : Text("Tap to set", style: TextStyle(color: context.textBrandPrimary900)), // 引导设置
          onTap: canEdit
              ? () => _GroupProfileLogic.handleAvatarTap(context, ref, detail)
              : null,
        ),

        // 2. 群名称
        _MenuItem(
          label: "Group Name",
          value: detail.name,
          showArrow: canEdit,
          onTap: canEdit
              ? () => _GroupProfileLogic.showEditDialog(
              context, "Group Name", detail.name, (val) {
            notifier.updateInfo(name: val);
          })
              : null,
        ),

        // 3. 群公告
        _MenuItem(
          label: "Announcement",
          value: detail.announcement?.isNotEmpty == true
              ? detail.announcement!
              : "None",
          showArrow: canEdit,
          onTap: canEdit
              ? () => _GroupProfileLogic.showEditDialog(
              context, "Announcement", detail.announcement ?? "", (val) {
            notifier.updateInfo(announcement: val);
          })
              : null,
        ),

        // 4. 群 ID (只读)
        _MenuItem(
          label: "Group ID",
          value: detail.id.substring(0, 8).toUpperCase(),
          showArrow: false,
          onTap: () {
            // 可选：点击复制 ID
             Clipboard.setData(ClipboardData(text: detail.id));
             RadixToast.info("Group ID copied");
          },
        ),

        SizedBox(height: 12.h),

        // 5. 管理开关区域
        if (canEdit)
          Container(
            color: context.bgPrimary,
            child: Column(
              children: [
                // 入群审批开关 (新增)
                SwitchListTile(
                  title: Text("Join Need Approval", style: TextStyle(fontSize: 16.sp)),
                  value: detail.joinNeedApproval,
                  activeColor: Colors.green,
                  onChanged: (val) {
                    notifier.updateInfo(joinNeedApproval: val);
                  },
                ),
                // 分割线
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Divider(height: 1, color: context.borderPrimary),
                ),
                // 全员禁言开关
                SwitchListTile(
                  title: Text("Mute All Members", style: TextStyle(fontSize: 16.sp)),
                  value: detail.isMuteAll,
                  activeColor: Colors.green,
                  onChanged: (val) {
                    notifier.updateInfo(isMuteAll: val);
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ======================================================
// 区域 3: 底部按钮 (保持不变)
// ======================================================

class _FooterButtons extends ConsumerWidget {
  final ConversationDetail detail;
  final String myUserId;

  const _FooterButtons({required this.detail, required this.myUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 判断当前用户是否已经在群里
    final me = detail.members.findMember(myUserId);
    final isMember = me != null;
    final isOwner = me?.isOwner ?? false;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          // =================================================
          // A. 陌生人视角：显示 "加入" 或 "申请"
          // =================================================
          if (!isMember)
            Button(
              // 如果需要审批，按钮文案为 "Apply"，否则为 "Join"
              width: double.infinity,
              variant: ButtonVariant.primary, // 主色调按钮
              onPressed: () {
                _GroupProfileLogic.handleJoinTap(context, ref, detail);
              },
              // 如果需要审批，按钮文案为 "Apply"，否则为 "Join"
              child: Text(detail.joinNeedApproval ? "Apply to Join" : "Join Group"),
            ),

          // =================================================
          // B. 成员视角：显示 "发消息" 和 "退群"
          // =================================================
          if (isMember) ...[
            // 1. 发消息按钮
            Button(
              width: double.infinity,
              variant: ButtonVariant.primary,
              onPressed: () {
                // 跳转到聊天页
                appRouter.push('/chat/room/${detail.id}');
              },
              child: Text("Send Message", style: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 12.h),

            // 2. 危险操作 (退群/解散)
            Button(
              width: double.infinity,
              variant: ButtonVariant.error, // 红色按钮
              // 只有非群主，或者群主决定解散时才显示
              onPressed: () {
                _GroupProfileLogic.handleLeaveOrDisband(
                    context, ref, detail, isOwner);
              },
              child: Text(isOwner ? "Disband Group" : "Leave Group",
                  style: TextStyle(color: Colors.white)
            )
            )
          ],
        ],
      ),
    );
  }
}

// ======================================================
// 辅助小组件 (保持不变)
// ======================================================

class _AddButton extends StatelessWidget {
  final ConversationDetail detail;
  const _AddButton({required this.detail});

  @override
  Widget build(BuildContext context) {
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
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.add, color: context.textSecondary700),
          ),
        ),
        SizedBox(height: 4.h),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _RoleBadge({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(2.r),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        shape: BoxShape.circle,
      ),
      child: Container(
        padding: EdgeInsets.all(3.r),
        decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))
            ]),
        child: Icon(icon, size: 10.r, color: Colors.white),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String label;
  final String? value; // 变为可选
  final Widget? trailing; // 新增：右侧自定义组件
  final VoidCallback? onTap;
  final bool showArrow;

  const _MenuItem({
    required this.label,
    this.value,
    this.trailing, // 新增
    this.onTap,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
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
              child: Align(
                alignment: Alignment.centerRight,
                child: trailing ?? // 优先显示自定义组件
                    Text(
                      value ?? "",
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15.sp, color: context.textSecondary700),
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
}

class _GroupSkeleton extends StatelessWidget {
  const _GroupSkeleton();

  @override
  Widget build(BuildContext context) {
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
              mainAxisSpacing: 12.h, // 保持与 _MemberGrid 一致
              crossAxisSpacing: 12.w,
            ),
            itemCount: 10,
            itemBuilder: (_, __) => Skeleton.react(
                width: 48.r,
                height: 48.r,
                borderRadius: BorderRadius.circular(8.r)),
          ),
        ),
        SizedBox(height: 12.h),
        Container(
            color: context.bgPrimary, height: 50.h, width: double.infinity),
      ],
    );
  }
}