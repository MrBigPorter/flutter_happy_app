part of 'group_profile_page.dart';

// ======================================================
// Section 1: Member Grid (Optimized Sorting)
// ======================================================
class _MemberGrid extends ConsumerWidget {
  final ConversationDetail detail;
  final String myUserId;
  final List<ChatMember> members;

  const _MemberGrid({
    required this.detail,
    required this.myUserId,
    required this.members,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Sorting logic for UI display
    // Weights: Owner (3) > Admin (2) > Member (1)
    final sortedMembers = [...members];
    sortedMembers.sort((a, b) {
      int getScore(ChatMember m) {
        if (m.role == GroupRole.owner) return 3;
        if (m.role == GroupRole.admin) return 2;
        return 1;
      }
      return getScore(b) - getScore(a);
    });

    // Invitation button visibility logic
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
          // A. Invitation Button (Always at the end of the list)
          if (showAddBtn && index == sortedMembers.length) {
            return _AddButton(detail: detail);
          }

          // B. Member Avatar Item
          final member = sortedMembers[index];
          final isMe = member.userId == myUserId;

          return InkWell(
            borderRadius: BorderRadius.circular(8.r),
            onTap: () {
              _GroupProfileLogic.handleMemberTap(
                context,
                ref,
                detail,
                member,
                myUserId,
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar Stack with Role Badges and Mute Status
                SizedBox(
                  width: 48.r,
                  height: 48.r,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Base Avatar
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
                                context,
                                member.avatar!,
                                logicalWidth: 48,
                              ),
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
                            fontWeight: FontWeight.bold,
                          ),
                        )
                            : null,
                      ),

                      // Mute Overlay
                      if (member.isMuted)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.mic_off,
                              size: 20.r,
                              color: Colors.white,
                            ),
                          ),
                        ),

                      // Role Badges (Owner/Admin)
                      if (member.isOwner)
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: _RoleBadge(
                            color: Colors.orange,
                            icon: Icons.star,
                          ),
                        )
                      else if (member.isAdmin)
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: _RoleBadge(
                            color: Colors.blue,
                            icon: Icons.security,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 6.h),
                // Nickname display with conditional styling
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
// Section 2: Menu Section (Info Editing and Admin Switches)
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
        // 1. Management Entrances (Admin only)
        if (canEdit) ...[
          Container(
            margin: EdgeInsets.only(bottom: 12.h),
            color: context.bgPrimary,
            child: Column(
              children: [
                // Join Requests with unread badge
                Consumer(
                  builder: (context, ref, _) {
                    return _MenuItem(
                      label: "Join Requests",
                      showArrow: true,
                      trailing: detail.pendingRequestCount > 0
                          ? Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: context.utilityError200,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          detail.pendingRequestCount > 99
                              ? '99+'
                              : '${detail.pendingRequestCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                          : null,
                      onTap: () {
                        context.push('/chat/group/requests/${detail.id}');
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],

        // 2. Group Metadata Management
        _MenuItem(
          label: "Group Avatar",
          showArrow: canEdit,
          trailing: detail.avatar != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: CachedNetworkImage(
              imageUrl: UrlResolver.resolveImage(
                context,
                detail.avatar!,
                logicalWidth: 40,
              ),
              width: 32.r,
              height: 32.r,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.grey[200]),
            ),
          )
              : Text(
            "Tap to set",
            style: TextStyle(color: context.textBrandPrimary900),
          ),
          onTap: canEdit
              ? () => _GroupProfileLogic.handleAvatarTap(context, ref, detail)
              : null,
        ),

        _MenuItem(
          label: "Group Name",
          value: detail.name,
          showArrow: canEdit,
          onTap: canEdit
              ? () => _GroupProfileLogic.showEditDialog(
            context,
            "Group Name",
            detail.name,
                (val) {
              notifier.updateInfo(name: val);
            },
          )
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
            context,
            "Announcement",
            detail.announcement ?? "",
                (val) {
              notifier.updateInfo(announcement: val);
            },
          )
              : null,
        ),

        _MenuItem(
          label: "Group ID",
          value: detail.id.substring(0, 8).toUpperCase(),
          showArrow: false,
          onTap: () {
            Clipboard.setData(ClipboardData(text: detail.id));
            RadixToast.info("Group ID copied");
          },
        ),

        _MenuItem(
          label: "Group QR Code",
          trailing: Icon(Icons.qr_code, size: 20.r, color: context.textSecondary700),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupQrPage(
                  groupId: detail.id,
                  groupName: detail.name,
                  groupAvatar: detail.avatar,
                ),
              ),
            );
          },
        ),

        SizedBox(height: 12.h),

        // 3. Administrative Toggle Controls
        if (canEdit)
          Container(
            color: context.bgPrimary,
            child: Column(
              children: [
                // Toggle for join approval requirements
                SwitchListTile(
                  title: Text(
                    "Join Need Approval",
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  value: detail.joinNeedApproval,
                  activeColor: Colors.green,
                  onChanged: (val) {
                    notifier.updateInfo(joinNeedApproval: val);
                  },
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Divider(height: 1, color: context.borderPrimary),
                ),
                // Toggle for muting all regular members
                SwitchListTile(
                  title: Text(
                    "Mute All Members",
                    style: TextStyle(fontSize: 16.sp),
                  ),
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
// Section 3: Bottom Action Buttons
// ======================================================
class _FooterButtons extends ConsumerWidget {
  final ConversationDetail detail;
  final String myUserId;

  const _FooterButtons({required this.detail, required this.myUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = detail.members.findMember(myUserId);
    final isMember = me != null;
    final isOwner = me?.isOwner ?? false;
    final isPending = detail.applicationStatus == 'PENDING';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          // Public View: Join or Apply buttons
          if (!isMember) ...[
            if (isPending)
              Button(
                width: double.infinity,
                variant: ButtonVariant.secondary,
                disabled: true,
                trailing: Icon(
                  Icons.hourglass_top,
                  size: 16.r,
                  color: context.textSecondary700,
                ),
                onPressed: () {},
                child: Text(
                  "Application Pending",
                  style: TextStyle(color: context.textSecondary700),
                ),
              )
            else
              Button(
                width: double.infinity,
                variant: ButtonVariant.primary,
                onPressed: () {
                  _GroupProfileLogic.handleJoinTap(context, ref, detail);
                },
                child: Text(
                  detail.joinNeedApproval ? "Apply to Join" : "Join Group",
                  style: TextStyle(color: context.textWhite),
                ),
              ),
          ],

          // Member View: Send Message and Leave/Disband buttons
          if (isMember) ...[
            Button(
              width: double.infinity,
              variant: ButtonVariant.primary,
              onPressed: () {
                appRouter.push('/chat/room/${detail.id}');
              },
              child: const Text(
                "Send Message",
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 12.h),
            Button(
              width: double.infinity,
              variant: ButtonVariant.error,
              onPressed: () {
                _GroupProfileLogic.handleLeaveOrDisband(
                  context,
                  ref,
                  detail,
                  isOwner,
                );
              },
              child: Text(
                isOwner ? "Disband Group" : "Leave Group",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ======================================================
// Supporting Sub-widgets
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
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 10.r, color: Colors.white),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showArrow;

  const _MenuItem({
    required this.label,
    this.value,
    this.trailing,
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
            Text(
              label,
              style: TextStyle(fontSize: 16.sp, color: context.textPrimary900),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: trailing ??
                    Text(
                      value ?? "",
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: context.textSecondary700,
                      ),
                    ),
              ),
            ),
            if (showArrow) ...[
              SizedBox(width: 8.w),
              Icon(
                Icons.arrow_forward_ios,
                size: 14.sp,
                color: Colors.grey[400],
              ),
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
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          color: context.bgPrimary,
          height: 50.h,
          width: double.infinity,
        ),
      ],
    );
  }
}

// ======================================================
// Component: Public Profile Header (Strangers Only)
// ======================================================
class _PublicGroupHeader extends StatelessWidget {
  final ConversationDetail detail;

  const _PublicGroupHeader({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.bgPrimary,
      padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 20.w),
      child: Column(
        children: [
          Container(
            width: 80.r,
            height: 80.r,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              color: context.bgSecondary,
              image: detail.avatar != null
                  ? DecorationImage(
                image: CachedNetworkImageProvider(
                  UrlResolver.resolveImage(
                    context,
                    detail.avatar!,
                    logicalWidth: 80,
                  ),
                ),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            alignment: Alignment.center,
            child: detail.avatar == null
                ? Text(
              detail.name.isNotEmpty ? detail.name[0].toUpperCase() : "?",
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            )
                : null,
          ),
          SizedBox(height: 16.h),
          Text(
            detail.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: context.textPrimary900,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "ID: ${detail.id.substring(0, 8).toUpperCase()}  |  ${detail.memberCount} Members",
            style: TextStyle(fontSize: 14.sp, color: context.textSecondary700),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// Component: Announcement Card (Strangers Only)
// ======================================================
class _AnnouncementCard extends StatelessWidget {
  final ConversationDetail detail;

  const _AnnouncementCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    if (detail.announcement == null || detail.announcement!.isEmpty) {
      return const SizedBox();
    }
    return Container(
      width: double.infinity,
      color: context.bgPrimary,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Announcement",
            style: TextStyle(fontSize: 13.sp, color: context.textSecondary700),
          ),
          SizedBox(height: 8.h),
          Text(
            detail.announcement!,
            style: TextStyle(fontSize: 15.sp, color: context.textPrimary900),
          ),
        ],
      ),
    );
  }
}