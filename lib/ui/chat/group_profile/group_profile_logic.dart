part of 'group_profile_page.dart';

class _GroupProfileLogic {

  // ======================================================
  // 1. 头像修改逻辑 (新增)
  // ======================================================
  static Future<void> handleAvatarTap(
      BuildContext context, WidgetRef ref, ConversationDetail detail) async {

    final picker = ImagePicker();
    // 1. 选择图片
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image == null) return;

    // 2. 显示上传 Loading 进度
    RadixToast.showLoading(
        message: "Uploading avatar..."
    );

    try {
      // 3. 上传图片
      String url = await GlobalUploadService().uploadFile(
          file: XFile(image.path),
          module: UploadModule.chat,
          onProgress: (percent) {
          }
      );


     //4. 调用 Notifier 更新群信息
      final notifier = ref.read(chatGroupProvider(detail.id).notifier);
       await notifier.updateInfo(avatar: url);

      // 临时提示 (等你接好上传接口后删掉这行)
      RadixToast.success("Avatar selected! (Upload logic needed)");

    } catch (e) {
      RadixToast.error("Failed to update avatar");
      debugPrint("Avatar update error: $e");
    } finally {
      RadixToast.hide();
    }
  }

  // ======================================================
  // 2. 成员管理菜单 (处理点击成员)
  // ======================================================
  static void handleMemberTap(
      BuildContext context,
      WidgetRef ref,
      ConversationDetail detail,
      ChatMember target,
      String myUserId,
      ) {
    // 点击自己 -> 跳转个人资料 (或者不做操作)
    if (target.userId == myUserId) {
      appRouter.push('/contact/profile/${target.userId}');
      return;
    }

    final me = detail.members.findMember(myUserId);
    if (me == null) return;

    // 权限检查：只有管理层或者等级比对方高才能操作
    // 如果没有管理权限，点击别人可能是为了看资料
    if (!me.canManage(target)) {
      appRouter.push('/contact/profile/${target.userId}');
      return;
    }

    final notifier = ref.read(chatGroupProvider(detail.id).notifier);
    final isMeOwner = me.isOwner;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.bgPrimary,
      isScrollControlled: true, // 允许弹窗高度自适应
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部拖拽条
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 8.h, bottom: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),

            // 标题栏
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Column(
                children: [
                  Text("Manage Member",
                      style: TextStyle(fontSize: 12.sp, color: context.textSecondary700)),
                  SizedBox(height: 4.h),
                  Text(target.nickname,
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary900
                      )),
                ],
              ),
            ),
            Divider(height: 1, color: context.borderPrimary),

            // 选项 1: 查看资料
            ListTile(
              leading: Icon(Icons.person_outline, color: context.textPrimary900),
              title: Text("View Profile", style: TextStyle(color: context.textPrimary900)),
              onTap: () {
                Navigator.pop(ctx);
                // context.push('/user/profile/${target.userId}');
                RadixToast.info("View profile: ${target.nickname}");
              },
            ),

            // 选项 2: 禁言/解禁
            ListTile(
              leading: Icon(
                  target.isMuted ? Icons.mic : Icons.mic_off_outlined,
                  color: target.isMuted ? Colors.green : Colors.orange
              ),
              title: Text(
                  target.isMuted ? "Unmute Member" : "Mute (10 Minutes)",
                  style: TextStyle(color: context.textPrimary900)),
              onTap: () {
                Navigator.pop(ctx);
                if (target.isMuted) {
                  notifier.muteMember(target.userId, 0); // 0 = 解禁
                  RadixToast.success("Member unmuted");
                } else {
                  notifier.muteMember(target.userId, 600); // 600秒 = 10分钟
                  RadixToast.warning("Member muted for 10 min");
                }
              },
            ),

            // 选项 3: 升降管理员 (仅群主可见)
            if (isMeOwner)
              ListTile(
                leading: const Icon(Icons.security_outlined, color: Colors.blue),
                title: Text(
                  target.isAdmin ? "Dismiss as Admin" : "Make Admin",
                  style: TextStyle(color: context.textPrimary900),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  notifier.setAdmin(target.userId, !target.isAdmin);
                  RadixToast.success(target.isAdmin ? "Admin dismissed" : "Promoted to Admin");
                },
              ),

            // 分割线 (将危险操作隔开)
            Divider(height: 1, color: context.borderPrimary),

            // 选项 4: 踢人 (危险操作)
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
                    child: Text(
                      "Are you sure you want to remove ${target.nickname} from the group?",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.textSecondary700),
                    ),
                  ),
                  confirmText: "Remove",
                  onConfirm: (close) {
                    close();
                    notifier.kickMember(target.userId);
                    RadixToast.success("Member removed");
                  },
                );
              },
            ),

            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  // ======================================================
  // 3. 编辑弹窗 (修改群名/公告)
  // ======================================================
  static void showEditDialog(BuildContext context, String title,
      String initialValue, Function(String) onConfirm) {
    final controller = TextEditingController(text: initialValue);

    RadixModal.show(
      title: "Edit $title",
      builder: (ctx, close) => Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: title == "Group Name" ? 30 : 200, // 增加字数限制体验更好
                maxLines: title == "Announcement" ? 3 : 1,
                decoration: InputDecoration(
                  hintText: "Enter new $title",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: context.borderPrimary)
                  ),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: context.textBrandPrimary900)
                  ),
                  filled: true,
                  fillColor: context.bgSecondary,
                  contentPadding: EdgeInsets.all(12.r),
                ),
              ),
            ],
          ),
        ),
      ),
      confirmText: 'Save',
      onConfirm: (close) {
        final text = controller.text.trim();
        if (text.isNotEmpty && text != initialValue) {
          onConfirm(text);
          close();
          RadixToast.success("$title updated");
        } else {
          close(); // 没改动直接关闭
        }
      },
    );
  }

  // ======================================================
  // 4. 退群/解散处理
  // ======================================================
  static void handleLeaveOrDisband(BuildContext context, WidgetRef ref,
      ConversationDetail detail, bool isOwner) {

    final bool isDisband = isOwner;

    RadixModal.show(
      title: isDisband ? "Disband Group" : "Leave Group",
      builder: (ctx, close) => Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isDisband
                  ? "Are you sure you want to disband this group? This action cannot be undone and all members will be removed."
                  : "Are you sure you want to leave? You will no longer receive messages from this group.",
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary700, height: 1.5),
            ),
          ],
        ),
      ),
      confirmText: isDisband ? 'Disband' : 'Leave',
      onConfirm: (close) async {
        close();

        // 显示 Loading 防止重复点击
        RadixToast.showLoading(message:isDisband ? "Disbanding..." : "Leaving...");

        try {
          final notifier = ref.read(chatGroupProvider(detail.id).notifier);
          bool success = isDisband ? await notifier.disbandGroup() : await notifier.leaveGroup();

          RadixToast.hide();

          if (success && context.mounted) {
            RadixToast.success(isDisband ? "Group disbanded" : "Left group");
            // 退回会话列表页
            context.go('/conversations');
          } else {
            RadixToast.error("Operation failed");
          }
        } catch (e) {
          RadixToast.hide();
          RadixToast.error("An error occurred");
        }
      },
    );
  }
}