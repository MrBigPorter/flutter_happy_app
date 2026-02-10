part of 'chat_page.dart';

mixin ChatPageLogic on ConsumerState<ChatPage> {
  final ScrollController scrollController = ScrollController();
  bool isPanelOpen = false;

  void disposeLogic() {
    scrollController.dispose();
  }

  // --- 交互逻辑 ---
  void togglePanel() {
    if (isPanelOpen) {
      setState(() => isPanelOpen = false);
      FocusScope.of(context).requestFocus();
    } else {
      FocusScope.of(context).unfocus();
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
    if (isPanelOpen) {
      setState(() => isPanelOpen = false);
      return false;
    }
    return true;
  }

  // --- 权限检查 ---
  ({bool canSend, String reason}) checkPermission(
    ConversationDetail? detail,
    bool isGroup,
  ) {
    if (!isGroup || detail == null) return (canSend: true, reason: "");

    final myId = ref.read(luckyProvider.select((s) => s.userInfo?.id));
    // 安全查找
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

  // --- 功能逻辑 ---
  void handleSendText(String text) {
    ref.read(chatActionServiceProvider(widget.conversationId)).sendText(text);
  }

  void handlePickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      ref
          .read(chatActionServiceProvider(widget.conversationId))
          .sendImage(image);
    }
  }

  void handleTakePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      ref
          .read(chatActionServiceProvider(widget.conversationId))
          .sendImage(image);
    }
  }

  void handlePickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      ref
          .read(chatActionServiceProvider(widget.conversationId))
          .sendVideo(video);
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

        ref
            .read(chatActionServiceProvider(widget.conversationId))
            .sendLocation(
              latitude: pos.latitude,
              longitude: pos.longitude,
              address: address,
              title: title,
            );
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  // --- 弹窗 ---
  void showAnnouncementDialog(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.campaign, color: context.textBrandPrimary900),
            SizedBox(width: 8.w),
            const Text("Announcement"),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(text, style: TextStyle(fontSize: 15.sp, height: 1.5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Got it"),
          ),
        ],
      ),
    );
  }
}
