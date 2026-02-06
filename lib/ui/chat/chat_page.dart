import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/chat/components/chat_action_sheet.dart';
import 'package:flutter_app/ui/chat/providers/chat_room_provider.dart';
import 'package:flutter_app/ui/chat/providers/chat_view_model.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_app/ui/chat/services/chat_action_service.dart';
import 'package:flutter_app/ui/chat/services/media/location_service.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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

  // 已删除 initState！
  // 现在的启动逻辑全部由 chatControllerProvider 自动接管
  // @override void initState() { ... }

  @override
  void dispose() {
    _scrollController.dispose();
    // 离开页面时，清除活跃会话标记 (保持这个清理逻辑是安全的)
    try {
      ref.read(activeConversationIdProvider.notifier).state = null;
    } catch (_) {}
    super.dispose();
  }

  // --- 面板控制逻辑 ---

  void _togglePanel() {
    if (_isPanelOpen) {
      setState(() => _isPanelOpen = false);
      FocusScope.of(context).requestFocus();
    } else {
      FocusScope.of(context).unfocus();
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
      return false;
    }
    return true;
  }

  // --- 发送逻辑代理 ---
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

  void _handleTakeFile() async {
    ref.read(chatActionServiceProvider(widget.conversationId)).sendFile();
  }

  void _handleTakeLocation() async {
    _closePanel();
    try {
      final pos = await LocationService.getCurrentPosition();
      if (pos != null) {
        final String address = await LocationService.getAddress(pos.latitude, pos.longitude);
        String title = "Current Location";
        if (address.contains("市")) {
          title = address.split("市").last;
        }

        ref.read(chatActionServiceProvider(widget.conversationId)).sendLocation(
          latitude: pos.latitude,
          longitude: pos.longitude,
          address: address,
          title: title,
        );
      }
    } catch (e) {
      debugPrint("Location error: $e");
      final errorStr = e.toString();
      if (errorStr.contains('permanently denied')) {
        _showPermissionDialog();
      } else if (errorStr.contains('Location services are disabled')) {
        Geolocator.openLocationSettings();
      } else {
        RadixToast.info("Failed to get location.");
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Location permission is permanently denied. Please enable it in the app settings to share your location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 只要这行代码在，Controller 就会被创建并 activate()
    // 进房、Socket监听、增量同步、已读标记... 全部自动运行！
    ref.watch(chatControllerProvider(widget.conversationId));

    // 顺便在这里维护一下活跃 ID (为了列表页高亮)，这属于 UI 状态
    Future.microtask(() {
      if (mounted) {
        ref.read(activeConversationIdProvider.notifier).state = widget.conversationId;
      }
    });

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
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: context.bgPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0.5,
          shadowColor: Colors.black.withOpacity(0.1),
          titleSpacing: 0,
          leadingWidth: 40,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: context.textPrimary900, size: 22.sp),
            onPressed: () => context.canPop() ? context.pop() : context.go('/conversations'),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: Colors.grey[200],
                backgroundImage: asyncDetail.valueOrNull?.avatar != null
                    ? CachedNetworkImageProvider(
                  UrlResolver.resolveImage(context, asyncDetail.value!.avatar!, logicalWidth: 36),
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
                      style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600, color: context.textPrimary900),
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
        body: Column(
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  if (messages.isEmpty && chatState.isInitializing) {
                    return Center(child: CircularProgressIndicator(strokeWidth: 2, color: context.textBrandPrimary900));
                  }
                  if (messages.isEmpty && !chatState.isInitializing) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 48.sp, color: Colors.grey[300]),
                          SizedBox(height: 10.h),
                          Text("No messages yet", style: TextStyle(color: Colors.grey[400])),
                        ],
                      ),
                    );
                  }
                  return GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      _closePanel();
                    },
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
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
                          if (index == messages.length) {
                            if (chatState.hasMore) {
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                alignment: Alignment.center,
                                child: SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: context.textBrandPrimary900)
                                ),
                              );
                            } else {
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                alignment: Alignment.center,
                                child: Text("—— No more history ——", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                              );
                            }
                          }
                          final msg = messages[index];
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
                  );
                },
              ),
            ),
            ModernChatInputBar(
              conversationId: widget.conversationId,
              onSend: _handleSendText,
              onSendVoice: actionService.sendVoiceMessage,
              onSendImage: (file) => actionService.sendImage(file),
              onSendVideo: (file) => actionService.sendVideo(file),
              onAddPressed: _togglePanel,
              onTextFieldTap: _closePanel,
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutQuad,
              height: _isPanelOpen ? 280.h + MediaQuery.of(context).padding.bottom : 0,
              color: context.bgPrimary,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ChatActionSheet(
                  actions: [
                    ActionItem(label: "Photos", icon: Icons.photo_library, onTap: _handlePickImage),
                    ActionItem(label: "Camera", icon: Icons.camera_alt, onTap: _handleTakePhoto),
                    ActionItem(label: "Video", icon: Icons.videocam, onTap: _handlePickVideo),
                    ActionItem(label: "File", icon: Icons.folder, onTap: _handleTakeFile),
                    ActionItem(label: "Location", icon: Icons.location_on, onTap: _handleTakeLocation),
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