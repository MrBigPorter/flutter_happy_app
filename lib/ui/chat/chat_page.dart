import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/chat/components/chat_action_sheet.dart';
import 'package:flutter_app/ui/chat/providers/chat_room_provider.dart';
import 'package:flutter_app/ui/chat/providers/chat_view_model.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_app/ui/chat/services/chat_action_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/image_url.dart';
import 'components/chat_bubble.dart';
import 'components/chat_input/modern_chat_input_bar.dart';
import 'models/chat_ui_model.dart';
import 'models/conversation.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String conversationId;
  final String title;

  const ChatPage({
    super.key,
    required this.conversationId,
    this.title = 'Group Chat',
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final ScrollController _scrollController = ScrollController();

  // 面板状态控制
  bool _isPanelOpen = false;

  @override
  void initState() {
    super.initState();
    // 1. 初始化：标记活跃会话 + 标为已读
    Future.microtask(() {
      ref.read(activeConversationIdProvider.notifier).state = widget.conversationId;
      ref.read(chatControllerProvider(widget.conversationId)).markAsRead();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // 离开页面时，清除活跃会话标记
    try {
      ref.read(activeConversationIdProvider.notifier).state = null;
    } catch (_) {}
    super.dispose();
  }

  // --- 面板控制逻辑 ---

  void _togglePanel() {
    if (_isPanelOpen) {
      // 关面板，开键盘
      setState(() => _isPanelOpen = false);
      FocusScope.of(context).requestFocus();
    } else {
      // 关键盘，开面板
      FocusScope.of(context).unfocus();
      // 延迟一点点，等键盘下去再把面板顶上来，更丝滑
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _isPanelOpen = true);
      });
    }
  }

  void _closePanel() {
    if (_isPanelOpen) {
      setState(() => _isPanelOpen = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (_isPanelOpen) {
      setState(() => _isPanelOpen = false);
      return false; // 拦截返回键
    }
    return true; // 允许返回
  }

  // --- 发送逻辑代理 ---
  // 这里可以处理一些 UI 层的操作，比如关面板
  void _handleSendText(String text) {
    ref.read(chatActionServiceProvider(widget.conversationId)).sendText(text);
  }

  void _handlePickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      ref.read(chatActionServiceProvider(widget.conversationId)).sendImage(image);
    }
  }

  void _handleTakePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      ref.read(chatActionServiceProvider(widget.conversationId)).sendImage(image);
    }
  }

  void _handlePickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      ref.read(chatActionServiceProvider(widget.conversationId)).sendVideo(video);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. 数据源
    final chatState = ref.watch(chatViewModelProvider(widget.conversationId));
    final viewModel = ref.read(chatViewModelProvider(widget.conversationId).notifier);
    final messages = chatState.messages;

    // 2. 发送服务
    final actionService = ref.read(chatActionServiceProvider(widget.conversationId));

    // 3. 详情信息
    final asyncDetail = ref.watch(chatDetailProvider(widget.conversationId));
    final bool isGroup = asyncDetail.valueOrNull?.type == ConversationType.group;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: context.bgPrimary,
        // 关键：允许键盘顶起 Body
        resizeToAvoidBottomInset: true,

        // ================= APP BAR =================
        appBar: AppBar(
          backgroundColor: context.bgPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0.5,
          shadowColor: Colors.black.withOpacity(0.1),
          titleSpacing: 0,
          leadingWidth: 40,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: context.textPrimary900, size: 22.sp),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/conversations');
              }
            },
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: Colors.grey[200],
                backgroundImage: asyncDetail.valueOrNull?.avatar != null
                    ? CachedNetworkImageProvider(
                  ImageUrl.build(context, asyncDetail.value!.avatar!, logicalWidth: 36),
                )
                    : null,
                child: asyncDetail.valueOrNull?.avatar == null
                    ? Icon(Icons.person, color: context.textSecondary700, size: 20.sp)
                    : null,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asyncDetail.valueOrNull?.name ?? widget.title,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.more_horiz, color: context.textPrimary900, size: 24.sp),
              onPressed: () {
                if (isGroup) {
                  appRouter.push('/chat/group/profile/${widget.conversationId}');
                } else {
                  appRouter.push('/chat/direct/profile/${widget.conversationId}');
                }
              },
            ),
            SizedBox(width: 8.w),
          ],
        ),

        // ================= BODY =================
        body: Column(
          children: [
            // 1. 消息列表 (占满剩余空间)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  _closePanel();
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    // P0级优化：智能分页加载
                    if (chatState.hasMore && !chatState.isLoadingMore) {
                      if (scrollInfo.metrics.extentAfter < 500) {
                        viewModel.loadMore();
                      }
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: messages.length + 1,
                    itemBuilder: (context, index) {
                      // 顶部 Loading / 到底提示
                      if (index == messages.length) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          alignment: Alignment.center,
                          child: (chatState.hasMore)
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text("—— No more history ——", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        );
                      }

                      final msg = messages[index];
                      // 简单判断已读显示 (仅供参考)
                      bool showReadStatus = msg.isMe && msg.status == MessageStatus.read && index == 0;

                      return ChatBubble(
                        key: ValueKey(msg.id),
                        isGroup: isGroup,
                        message: msg,
                        showReadStatus: showReadStatus,
                        onRetry: () => actionService.resend(msg.id),
                      );
                    },
                  ),
                ),
              ),
            ),

            // 2. 输入框 (始终在底部，会被键盘顶起)
            ModernChatInputBar(
              conversationId: widget.conversationId,
              // --- 基础回调 ---
              onSend: _handleSendText,
              onSendVoice: actionService.sendVoiceMessage,
              // --- 这些其实不需要了，因为逻辑都在 Menu 里，为了兼容旧接口先留着空 ---
              onSendImage: (file) => actionService.sendImage(file),
              onSendVideo: (file) => actionService.sendVideo(file),

              // ---  核心交互回调 ---
              onAddPressed: _togglePanel,      // 点击加号 -> 切换面板
              onTextFieldTap: _closePanel,     // 点击输入框 -> 收起面板
            ),

            // 3. 全能菜单面板 (隐藏在最下方)
            // 当 _isPanelOpen 为 true 时，它会撑开高度，把上面的 InputBar 顶上去
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutQuad,
              height: _isPanelOpen ?  280.h + MediaQuery.of(context).padding.bottom : 0,
              color:context.bgSecondary,
              // 适配 iPhone 底部横条
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ChatActionSheet(
                  actions: [
                    ActionItem(
                      label: "Photos",
                      icon: Icons.photo_library,
                      onTap: _handlePickImage,
                    ),
                    ActionItem(
                      label: "Camera",
                      icon: Icons.camera_alt,
                      onTap: _handleTakePhoto,
                    ),
                    ActionItem(
                      label: "Video",
                      icon: Icons.videocam,
                      onTap: _handlePickVideo,
                    ),
                    // 预留位置
                    ActionItem(
                      label: "File",
                      icon: Icons.folder,
                      onTap: () {
                        // TODO: File Picker
                      },
                    ),
                    ActionItem(
                      label: "Location",
                      icon: Icons.location_on,
                      onTap: () {
                        // TODO: Location
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}