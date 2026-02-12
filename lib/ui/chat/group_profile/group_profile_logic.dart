part of 'group_profile_page.dart';

class _GroupProfileLogic {
  // 处理成员点击
  static void handleMemberTap(
      BuildContext context,
      WidgetRef ref,
      ConversationDetail detail,
      ChatMember target,
      String myUserId,
      ) {
    if (target.userId == myUserId) return;

    final me = detail.members.findMember(myUserId);
    if (me == null) return;

    // 权限检查
    if (!me.canManage(target)) {
      // 可以在这里加一个查看用户详情的跳转
      return;
    }

    final notifier = ref.read(chatGroupProvider(detail.id).notifier);
    final isMeOwner = me.isOwner;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.bgPrimary,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Column(
                children: [
                  Text("Manage Member",
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
                  SizedBox(height: 4.h),
                  Text(target.nickname,
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Divider(height: 1),

            // 禁言/解禁
            ListTile(
              leading: Icon(target.isMuted ? Icons.mic : Icons.mic_off,
                  color: target.isMuted ? Colors.green : Colors.orange),
              title: Text(
                  target.isMuted ? "Unmute Member" : "Mute (10 Minutes)",
                  style: TextStyle(color: context.textPrimary900)),
              onTap: () {
                Navigator.pop(ctx);
                if (target.isMuted) {
                  notifier.muteMember(target.userId, 0);
                  RadixToast.success("Member unmuted");
                } else {
                  notifier.muteMember(target.userId, 600);
                  RadixToast.warning("Member muted for 10 min");
                }
              },
            ),

            // 踢人
            ListTile(
              leading: Icon(Icons.remove_circle_outline,
                  color: context.utilityError200),
              title: Text("Remove from Group",
                  style: TextStyle(color: context.utilityError200)),
              onTap: () {
                Navigator.pop(ctx);
                RadixModal.show(
                  title: "Remove Member",
                  builder: (_, __) => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text("Remove ${target.nickname} from the group?",
                        textAlign: TextAlign.center),
                  ),
                  confirmText: "Remove",
                  onConfirm: (close) {
                    close();
                    notifier.kickMember(target.userId);
                  },
                );
              },
            ),

            // 升降管理员
            if (isMeOwner)
              ListTile(
                leading: const Icon(Icons.security, color: Colors.blue),
                title: Text(target.isAdmin ? "Dismiss as Admin" : "Make Admin"),
                onTap: () {
                  Navigator.pop(ctx);
                  notifier.setAdmin(target.userId, !target.isAdmin);
                },
              ),

            SizedBox(height: 8.h),
            Container(color: context.bgSecondary, height: 8.h),
            ListTile(
              title: const Center(child: Text("Cancel")),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  // 显示编辑弹窗
  static void showEditDialog(BuildContext context, String title,
      String initialValue, Function(String) onConfirm) {
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

  // 处理退群或解散
  static void handleLeaveOrDisband(BuildContext context, WidgetRef ref,
      ConversationDetail detail, bool isOwner) {
    RadixModal.show(
      title: isOwner ? "Disband Group" : "Leave Group",
      builder: (ctx, close) => Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          isOwner
              ? "Disband this group? All members will be removed."
              : "Are you sure you want to leave?",
          textAlign: TextAlign.center,
        ),
      ),
      confirmText: 'Confirm',
      onConfirm: (close) async {
        close();
        final notifier = ref.read(chatGroupProvider(detail.id).notifier);
        bool success =
        isOwner ? await notifier.disbandGroup() : await notifier.leaveGroup();
        if (success && context.mounted) {
          RadixToast.success(isOwner ? "Group disbanded" : "Left group");
          context.go('/conversations');
        }
      },
    );
  }
}