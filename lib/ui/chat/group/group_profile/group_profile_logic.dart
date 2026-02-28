part of 'group_profile_page.dart';

class _GroupProfileLogic {

  // ======================================================
  // 1. Avatar Modification Logic
  // ======================================================
  static Future<void> handleAvatarTap(
      BuildContext context, WidgetRef ref, ConversationDetail detail) async {

    final picker = ImagePicker();
    // 1. Pick image from gallery with optimized quality
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image == null) return;

    // 2. Show upload progress indicator
    RadixToast.showLoading(
        message: "Uploading avatar..."
    );

    try {
      // 3. Upload file using the global upload service
      String url = await GlobalUploadService().uploadFile(
          file: XFile(image.path),
          module: UploadModule.chat,
          onProgress: (percent) {
            // Optional: Implement progress bar update logic here
          }
      );

      // 4. Invoke Notifier to update group metadata on the backend
      final notifier = ref.read(chatGroupProvider(detail.id).notifier);
      await notifier.updateInfo(avatar: url);

      RadixToast.success("Group avatar updated");

    } catch (e) {
      RadixToast.error("Failed to update avatar");
      debugPrint("[GroupProfileLogic] Avatar update error: $e");
    } finally {
      RadixToast.hide();
    }
  }

  // ======================================================
  // 2. Member Management Menu (Member Tap Handling)
  // ======================================================
  static void handleMemberTap(
      BuildContext context,
      WidgetRef ref,
      ConversationDetail detail,
      ChatMember target,
      String myUserId,
      ) {

    // Internal navigation helper: uses preview data for immediate UI rendering
    void jumpToProfile() {
      final previewUser = ChatUser(
        id: target.userId,
        nickname: target.nickname,
        avatar: target.avatar,
        phone: null,
        status: RelationshipStatus.stranger, // Default status, refreshes inside the detail page
      );

      appRouter.push(
          '/contact/profile/${target.userId}',
          extra: previewUser // Pass extra data to support Hero animations
      );
    }

    // A. Tap on Self -> Navigate to personal profile
    if (target.userId == myUserId) {
      jumpToProfile();
      return;
    }

    final me = detail.members.findMember(myUserId);
    // B. Safety fallback for missing member data
    if (me == null) {
      jumpToProfile();
      return;
    }

    // C. Permission Check: If current user lacks management rights, default to view-only mode
    if (!me.canManage(target)) {
      jumpToProfile();
      return;
    }

    // D. User has management rights -> Display management bottom sheet
    final notifier = ref.read(chatGroupProvider(detail.id).notifier);
    final isMeOwner = me.isOwner;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.bgPrimary,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top drag handle bar
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

            // Header Section: Target Member Info
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

            // Option 1: View Profile
            ListTile(
              leading: Icon(Icons.person_outline, color: context.textPrimary900),
              title: Text("View Profile", style: TextStyle(color: context.textPrimary900)),
              onTap: () {
                Navigator.pop(ctx);
                jumpToProfile();
              },
            ),

            // Option 2: Mute/Unmute Management
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
                  notifier.muteMember(target.userId, 0); // 0 = Unmute
                  RadixToast.success("Member unmuted");
                } else {
                  notifier.muteMember(target.userId, 600); // 600 seconds = 10 minutes
                  RadixToast.warning("Member muted for 10 min");
                }
              },
            ),

            // Option 3: Admin Privilege Management (Owner Only)
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

            Divider(height: 1, color: context.borderPrimary),

            // Option 4: Removal (Destructive Action)
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
  // 3. Edit Dialog (Group Name / Announcement)
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
          close();
        }
      },
    );
  }

  // ======================================================
  // 4. Leave / Disband Workflow
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

        RadixToast.showLoading(message: isDisband ? "Disbanding..." : "Leaving...");

        try {
          final notifier = ref.read(chatGroupProvider(detail.id).notifier);
          bool success = isDisband ? await notifier.disbandGroup() : await notifier.leaveGroup();

          RadixToast.hide();

          if (success && context.mounted) {
            RadixToast.success(isDisband ? "Group disbanded" : "Left group");
            // Return to conversation list upon successful exit
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

  // ======================================================
  // 5. Join Application Management
  // ======================================================
  static void handleJoinTap(
      BuildContext context, WidgetRef ref, ConversationDetail detail) {

    // Scenario A: Approval not required -> Execute direct join
    if (!detail.joinNeedApproval) {
      _doJoinDirectly(context, ref, detail.id);
      return;
    }

    // Scenario B: Approval required -> Prompt for verification reason
    final controller = TextEditingController();
    RadixModal.show(
      title: "Apply to Join",
      builder: (ctx, close) => Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Verification is required for this group.",
                style: TextStyle(color: context.textSecondary700, fontSize: 14.sp),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 50,
                decoration: InputDecoration(
                  hintText: "Enter your reason (e.g. I'm Jack)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  contentPadding: EdgeInsets.all(12.r),
                  filled: true,
                  fillColor: context.bgSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
      confirmText: "Send",
      onConfirm: (close) async {
        final reason = controller.text.trim();
        close();
        await _doApplyWithReason(context, ref, detail.id, reason);
      },
    );
  }

  /// Private helper for direct group entry
  static Future<void> _doJoinDirectly(
      BuildContext context, WidgetRef ref, String groupId) async {
    RadixToast.showLoading(message: "Sending application...");
    try{
      final res = await ref.read(groupJoinControllerProvider.notifier)
          .apply(groupId, "");
      if (res?.status == 'ACCEPTED') {
        RadixToast.success("Joined successfully");
        // Invalidate provider to refresh page state and UI visibility
        ref.invalidate(chatGroupProvider(groupId));
      }
    }catch(e){
      RadixToast.hide();
    }
  }

  /// Private helper for submitting application with a reason
  static Future<void> _doApplyWithReason(
      BuildContext context, WidgetRef ref, String groupId, String reason) async {
    RadixToast.showLoading(message: "Sending application...");
    try {
      final res = await ref.read(groupJoinControllerProvider.notifier)
          .apply(groupId, reason);

      if (res != null) {
        RadixToast.success("Application sent");
        // Refresh detail to reflect pending status in UI
        ref.invalidate(chatGroupProvider(groupId));
      }
    } catch (e) {
      RadixToast.hide();
    }
  }
}