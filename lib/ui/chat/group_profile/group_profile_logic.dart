part of 'group_profile_page.dart';

class _GroupProfileLogic {

  // ======================================================
  // 1. 头像修改逻辑
  // ======================================================
  static Future<void> handleAvatarTap(
      BuildContext context, WidgetRef ref, ConversationDetail detail) async {

    final picker = ImagePicker();
    // 1. 选择图片
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image == null) return;

    // 2. 显示上传 Loading
    RadixToast.showLoading(
        message: "Uploading avatar..."
    );

    try {
      // 3. 上传图片 (使用全局上传服务)
      String url = await GlobalUploadService().uploadFile(
          file: XFile(image.path),
          module: UploadModule.chat,
          onProgress: (percent) {
            // 可选：更新进度条
          }
      );

      // 4. 调用 Notifier 更新群信息
      final notifier = ref.read(chatGroupProvider(detail.id).notifier);
      await notifier.updateInfo(avatar: url);

      RadixToast.success("Group avatar updated");

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

    // 内部通用跳转方法：携带预览数据，实现秒开效果
    void jumpToProfile() {
      final previewUser = ChatUser(
        id: target.userId,
        nickname: target.nickname,
        avatar: target.avatar,
        phone: null, // 预览数据暂无电话
        status: RelationshipStatus.stranger, // 默认陌生人，进入详情页后会自动刷新状态
      );
      

      appRouter.push(
          '/contact/profile/${target.userId}',
          extra: previewUser // 关键：传递 extra 实现 Hero 动画
      );
    }

    // A. 点击自己 -> 跳转个人资料
    if (target.userId == myUserId) {
      // 这里的路径取决于你是否区分“我的资料页”和“联系人资料页”
      // 如果是用同一个页面，直接调用 jumpToProfile 即可
      jumpToProfile();
      return;
    }

    final me = detail.members.findMember(myUserId);
    // B. 数据异常兜底
    if (me == null) {
      jumpToProfile();
      return;
    }

    // C. 权限检查：如果我不能管理他（我是成员，或者是同级管理员），则直接查看资料
    if (!me.canManage(target)) {
      jumpToProfile();
      return;
    }

    // D. 我有权限管理他 -> 弹出管理菜单
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

            // 标题栏 (显示被操作人信息)
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

            // 选项 1: 查看资料 (新增跳转入口)
            ListTile(
              leading: Icon(Icons.person_outline, color: context.textPrimary900),
              title: Text("View Profile", style: TextStyle(color: context.textPrimary900)),
              onTap: () {
                Navigator.pop(ctx); // 先关弹窗
                jumpToProfile();    // 再跳转
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
                maxLength: title == "Group Name" ? 30 : 200,
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

        // 显示 Loading
        RadixToast.showLoading(message: isDisband ? "Disbanding..." : "Leaving...");

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