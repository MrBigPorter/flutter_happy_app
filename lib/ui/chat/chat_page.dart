import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/chat/providers/chat_room_provider.dart';
import 'package:flutter_app/ui/chat/providers/chat_view_model.dart'; // 新的大脑
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_app/ui/chat/services/chat_action_service.dart'; // 新的手臂
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
  // 现在的分页不需要手动监听 Controller 了，NotificationListener 更准
  // 但为了防止你的 InputBar 或其他地方用到它，我们保留实例，但不监听加载更多
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // 1. 标记当前活跃会话
      ref.read(activeConversationIdProvider.notifier).state = widget.conversationId;
      ref.read(chatControllerProvider(widget.conversationId)).markAsRead();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    try {
      ref.read(activeConversationIdProvider.notifier).state = null;
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //  1. 获取新版数据源 (ViewModel)
    final chatState = ref.watch(chatViewModelProvider(widget.conversationId));
    final viewModel = ref.read(chatViewModelProvider(widget.conversationId).notifier);
    final messages = chatState.messages;

    //  2. 获取发送服务 (ActionService)
    // 所有的发送逻辑 (文字、图片、视频) 现在都由它接管
    final actionService = ref.read(chatActionServiceProvider(widget.conversationId));

    // 3. 监听详情 (保留你原来的逻辑)
    final asyncDetail = ref.watch(chatDetailProvider(widget.conversationId));
    final bool isGroup = asyncDetail.valueOrNull?.type == ConversationType.group;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.bgPrimary,

        // ==========================================
        // AppBar 区域 (完全保留你原来的样式)
        // ==========================================
        appBar: AppBar(
          backgroundColor: context.bgPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0.5,
          shadowColor: Colors.black.withOpacity(0.1),
          titleSpacing: 0,
          leadingWidth: 40,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: context.textPrimary900,
              size: 22.sp,
            ),
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
                  ImageUrl.build(
                    context,
                    asyncDetail.value!.avatar!,
                    logicalWidth: 36,
                  ),
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
                    asyncDetail.when(
                      data: (detail) => Text(
                        detail.name,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary900,
                        ),
                      ),
                      loading: () => Text(widget.title, style: TextStyle(color: context.textPrimary900)),
                      error: (_, __) => Text(widget.title, style: TextStyle(color: context.textPrimary900)),
                    ),
                    asyncDetail.maybeWhen(
                      data: (detail) => Text(
                        'Active now',
                        style: TextStyle(fontSize: 12.sp, color: context.textSecondary700),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.call, color: context.textBrandPrimary900, size: 24.sp),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.videocam, color: context.textBrandPrimary900, size: 26.sp),
              onPressed: () {},
            ),
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
            // ==========================================
            // 消息列表区域 ( 核心修改处 )
            // ==========================================
            Expanded(
              // 使用 NotificationListener 监听滑动，代替原来的 ScrollController 逻辑
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  // 阈值判断：离顶部不足 500px，且还有历史数据，且当前没在加载
                  if (chatState.hasMore && !chatState.isLoadingMore) {
                    if (scrollInfo.metrics.extentAfter < 500) {
                      viewModel.loadMore(); // 触发静默加载
                    }
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _scrollController, // 保留 controller 以防你有其他用途(如跳到底部)
                  reverse: true, // 聊天标准：底部为0
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  // +1 为了显示顶部的 Loading 提示
                  itemCount: messages.length + 1,
                  itemBuilder: (context, index) {
                    // --- 顶部 Loading (历史尽头) ---
                    if (index == messages.length) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        alignment: Alignment.center,
                        child: (chatState.hasMore)
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text("—— No more history ——", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      );
                    }

                    // --- 消息气泡 ---
                    final msg = messages[index];

                    // 简单的已读状态判断逻辑 (保留你原来的思路)
                    // 实际项目中这里可能需要根据对方已读位置精确计算
                    bool showReadStatus = false;
                    if (msg.isMe && msg.status == MessageStatus.read) {
                      // 只有最新一条展示头像
                      showReadStatus = true;
                    }

                    return ChatBubble(
                      key: ValueKey(msg.id),
                      isGroup: isGroup,
                      message: msg,
                      showReadStatus: showReadStatus,
                      onRetry: () {
                        // 重发现在走 ActionService
                        actionService.resend(msg.id);
                      },
                    );
                  },
                ),
              ),
            ),

            // ==========================================
            // 输入框区域 (回调改为调用 ActionService)
            // ==========================================
            ModernChatInputBar(
              conversationId: widget.conversationId,
              // 1. 发文本
              onSend: (text) {
                actionService.sendText(text);
              },
              // 2. 发图片
              onSendImage: (XFile file) {
                actionService.sendImage(file);
              },
              // 3. 发视频
              onSendVideo: (XFile file) {
                actionService.sendVideo(file);
              },
              // 4. 发语音
              onSendVoice: (String path, int duration) {
                actionService.sendVoiceMessage(path, duration);
              },
            ),
          ],
        ),
      ),
    );
  }
}