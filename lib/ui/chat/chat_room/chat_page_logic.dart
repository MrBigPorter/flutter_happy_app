part of 'chat_page.dart';

mixin ChatPageLogic on ConsumerState<ChatPage> {
  final ScrollController scrollController = ScrollController();
  bool isPanelOpen = false;

  void disposeLogic() {
    scrollController.dispose();
  }

  // --- Interaction Logic ---

  void togglePanel() {
    if (isPanelOpen) {
      setState(() => isPanelOpen = false);
      FocusScope.of(context).requestFocus();
    } else {
      FocusScope.of(context).unfocus();
      // Brief delay to ensure the keyboard is dismissed before expanding the panel
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => isPanelOpen = true);
      });
    }
  }

  void closePanel() {
    if (isPanelOpen) {
      setState(() => isPanelOpen = false);
    }
  }

  Future<bool> onWillPop() async {
    // Intercept back button if the action panel is open
    if (isPanelOpen) {
      setState(() => isPanelOpen = false);
      return false;
    }
    return true;
  }

  // --- Permission Checks ---

  ({bool canSend, String reason}) checkPermission(
      ConversationDetail? detail,
      bool isGroup,
      ) {
    if (!isGroup || detail == null) return (canSend: true, reason: "");

    final myId = ref.read(userProvider.select((s) => s?.id));
    final me = detail.members.cast<ChatMember?>().firstWhere(
          (m) => m?.userId == myId,
      orElse: () => null,
    );

    if (me != null) {
      if (me.isMuted) return (canSend: false, reason: "You are muted");
      if (detail.isMuteAll && !me.isManagement) {
        return (canSend: false, reason: "All members are muted.");
      }
    }
    return (canSend: true, reason: "");
  }

  // ======================================================
  // Message Actions: Long Press Menu & Forwarding
  // ======================================================

  void onMessageLongPress(BuildContext context, ChatUiModel message) {
    HapticFeedback.mediumImpact(); // Haptic feedback for tactile response

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChatActionSheet(
        actions: [
          // 1. Forward Message
          ActionItem(
            label: "Forward",
            icon: Icons.forward,
            onTap: () {
              Navigator.pop(ctx);
              _handleForward(message);
            },
          ),

          // 2. Copy (Text messages only)
          if (message.type == MessageType.text)
            ActionItem(
              label: "Copy",
              icon: Icons.copy,
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(ctx);
                RadixToast.success("Copied");
              },
            ),

          // 3. Recall (Allowed for own messages within 2-minute window)
          if (message.isMe && message.canRecall)
            ActionItem(
              label: "Recall",
              icon: Icons.undo,
              isDestructive: true,
              onTap: () {
                Navigator.pop(ctx);
                ref.read(chatControllerProvider(widget.conversationId)).recallMessage(message.id);
              },
            ),

          // 4. Delete (Local deletion)
          ActionItem(
            label: "Delete",
            icon: Icons.delete_outline,
            isDestructive: true,
            onTap: () {
              Navigator.pop(ctx);
              ref.read(chatControllerProvider(widget.conversationId)).deleteMessage(message.id);
            },
          ),
        ],
      ),
    );
  }

  // Forwarding workflow: Select target -> Confirm -> Execute
  void _handleForward(ChatUiModel message) async {
    // 1. Navigate to contact/group selector
    final targets = await context.push<List<SelectionEntity>>(
      '/contact/selector',
      extra: ContactSelectionArgs(
        title: "Forward To",
        mode: SelectionMode.single,
        confirmText: "Send",
      ),
    );

    if (targets == null || targets.isEmpty) return;

    // Format target names for the confirmation dialog
    final names = targets.map((t) => t.name).join(", ");
    final displayName = names.length > 30 ? "${names.substring(0, 30)}..." : names;
    final countText = targets.length > 1 ? "(${targets.length})" : "";

    // 2. Secondary confirmation modal
    if (!mounted) return;
    RadixModal.show(
      title: "Confirm Forward",
      builder: (_, __) => Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Forward message to:", style: TextStyle(color: Colors.grey[600])),
            SizedBox(height: 8.h),
            Text(
              "$displayName $countText",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      confirmText: "Send",
      onConfirm: (close) async {
        close();

        // 3. Execute forwarding via Action Service
        try {
          RadixToast.showLoading(message: "Sending...");

          final targetIds = targets.map((t) => t.id).toList();
          await ref.read(chatActionServiceProvider(widget.conversationId)).forwardMessage(message.id, targetIds);

          RadixToast.success("Sent");
        } catch (e) {
          RadixToast.error("Failed to forward");
        } finally {
          RadixToast.hide();
        }
      },
    );
  }

  // --- Sending Logic ---

  void handleSendText(String text) {
    ref.read(chatActionServiceProvider(widget.conversationId)).sendText(text);
  }

  void handlePickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      ref.read(chatActionServiceProvider(widget.conversationId)).sendImage(image);
    }
  }

  void handleTakePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      ref.read(chatActionServiceProvider(widget.conversationId)).sendImage(image);
    }
  }

  void handlePickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      ref.read(chatActionServiceProvider(widget.conversationId)).sendVideo(video);
    }
  }

  void handleTakeFile() {
    ref.read(chatActionServiceProvider(widget.conversationId)).sendFile();
  }

  void handleTakeLocation() async {
    closePanel();
    try {
      final pos = await LocationService.getCurrentPosition();
      if (pos != null) {
        final String address = await LocationService.getAddress(
          pos.latitude,
          pos.longitude,
        );
        String title = "Current Location";

        ref.read(chatActionServiceProvider(widget.conversationId)).sendLocation(
          latitude: pos.latitude,
          longitude: pos.longitude,
          address: address,
          title: title,
        );
      }
    } catch (e) {
      debugPrint("[ChatPageLogic] Location error: $e");
    }
  }

  void showAnnouncementDialog(BuildContext context, String text) {
    RadixModal.show(
        title: 'Announcement',
        confirmText: 'Got it',
        builder: (ctx, close) => SingleChildScrollView(
          child: Text(text, style: TextStyle(fontSize: 15.sp, height: 1.5)),
        )
    );
  }
}