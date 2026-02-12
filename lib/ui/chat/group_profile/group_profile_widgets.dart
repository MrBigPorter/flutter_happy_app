part of 'group_profile_page.dart';

// ======================================================
// 区域 1: 成员网格
// ======================================================
class _MemberGrid extends ConsumerWidget {
  final ConversationDetail detail;
  final String myUserId;

  const _MemberGrid({required this.detail, required this.myUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = detail.members;
    final bool showAddBtn = true; // 或者是 detail.canInvite(myUserId)
    final itemCount = members.length + (showAddBtn ? 1 : 0);

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
          // A. 邀请按钮
          if (showAddBtn && index == members.length) {
            return _AddButton(detail: detail);
          }

          // B. 成员头像
          final member = members[index];
          final isMe = member.userId == myUserId;

          return InkWell(
            borderRadius: BorderRadius.circular(8.r),
            onTap: () {
              // 调用逻辑文件中的静态方法
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
// 区域 2: 菜单部分
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
        _MenuItem(
          label: "Group ID",
          value: detail.id.substring(0, 8).toUpperCase(),
          showArrow: false,
        ),
        SizedBox(height: 12.h),
        if (canEdit)
          Container(
            color: context.bgPrimary,
            child: SwitchListTile(
              title:
              Text("Mute All Members", style: TextStyle(fontSize: 16.sp)),
              value: detail.isMuteAll,
              activeColor: Colors.green,
              onChanged: (val) {
                notifier.updateInfo(isMuteAll: val);
              },
            ),
          ),
      ],
    );
  }
}

// ======================================================
// 区域 3: 底部按钮
// ======================================================
class _FooterButtons extends ConsumerWidget {
  final ConversationDetail detail;
  final String myUserId;

  const _FooterButtons({required this.detail, required this.myUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = detail.members.findMember(myUserId);
    final isOwner = me?.isOwner ?? false;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Button(
        variant: ButtonVariant.error,
        width: double.infinity,
        child: Text(isOwner ? "Disband Group" : "Delete and Leave"),
        onPressed: () {
          _GroupProfileLogic.handleLeaveOrDisband(
              context, ref, detail, isOwner);
        },
      ),
    );
  }
}

// ======================================================
// 辅助小组件
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
  final String value;
  final VoidCallback? onTap;
  final bool showArrow;

  const _MenuItem({
    required this.label,
    required this.value,
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
            Text(label,
                style:
                TextStyle(fontSize: 16.sp, color: context.textPrimary900)),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 15.sp, color: context.textSecondary700),
              ),
            ),
            if (showArrow) ...[
              SizedBox(width: 8.w),
              Icon(Icons.arrow_forward_ios,
                  size: 14.sp, color: Colors.grey[400]),
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
              mainAxisSpacing: 12.h,
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