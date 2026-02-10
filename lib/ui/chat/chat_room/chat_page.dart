import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/preloader/scroll_aware_preloader.dart';
import 'package:flutter_app/ui/chat/components/chat_action_sheet.dart';
import 'package:flutter_app/ui/chat/providers/chat_group_provider.dart';
import 'package:flutter_app/ui/chat/providers/chat_room_provider.dart';
import 'package:flutter_app/ui/chat/providers/chat_view_model.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_app/ui/chat/services/chat_action_service.dart';
import 'package:flutter_app/ui/chat/services/media/location_service.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import '../components/chat_bubble.dart';
import '../components/chat_input/modern_chat_input_bar.dart';
import '../models/chat_ui_model.dart';
import '../models/conversation.dart';

part 'chat_page_logic.dart';
part 'chat_page_widgets.dart';

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

//  核心：混入 Logic Mixin
class _ChatPageState extends ConsumerState<ChatPage> with ChatPageLogic {

  @override
  void dispose() {
    disposeLogic(); // 调用 Logic 里的清理
    try {
      ref.read(activeConversationIdProvider.notifier).state = null;
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 启动控制器
    ref.watch(chatControllerProvider(widget.conversationId));

    // 维护活跃 ID
    Future.microtask(() {
      if (mounted) ref.read(activeConversationIdProvider.notifier).state = widget.conversationId;
    });

    // 数据源
    final chatState = ref.watch(chatViewModelProvider(widget.conversationId));
    final viewModel = ref.read(chatViewModelProvider(widget.conversationId).notifier);
    final messages = chatState.messages;
    final actionService = ref.read(chatActionServiceProvider(widget.conversationId));

    // 详情数据
    final groupAsync = ref.watch(chatGroupProvider(widget.conversationId));
    final basicAsync = ref.watch(chatDetailProvider(widget.conversationId));
    final detail = groupAsync.valueOrNull ?? basicAsync.valueOrNull;
    final bool isGroup = detail?.type == ConversationType.group;

    // 权限检查 (调用 Logic)
    final permission = checkPermission(detail, isGroup);
    final bool canSend = permission.canSend;
    final String disableReason = permission.reason;

    // 公告检查
    final announcement = detail?.announcement;
    final hasAnnouncement = announcement != null && announcement.trim().isNotEmpty;

    return WillPopScope(
      onWillPop: onWillPop, // Logic 方法
      child: Scaffold(
        backgroundColor: context.bgPrimary,
        resizeToAvoidBottomInset: true,
        // 调用 Widget 分部的方法
        appBar: _buildAppBar(context, detail, isGroup),
        body: Column(
          children: [
            // 公告栏
            if (hasAnnouncement && isGroup)
              ChatAnnouncementBar(
                text: announcement,
                onTap: () => showAnnouncementDialog(context, announcement), // Logic 方法
              ),

            // 消息列表区
            Expanded(
              child: Builder(
                builder: (context) {
                  if (messages.isEmpty && chatState.isInitializing) {
                    return Center(child: CircularProgressIndicator(strokeWidth: 2, color: context.textBrandPrimary900));
                  }
                  if (messages.isEmpty && !chatState.isInitializing) {
                    return Center(child: Text("No messages yet", style: TextStyle(color: Colors.grey[400])));
                  }
                  return GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      closePanel(); // Logic 方法
                    },
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (chatState.hasMore && !chatState.isLoadingMore) {
                          if (scrollInfo.metrics.extentAfter < 2000) {
                            viewModel.loadMore();
                          }
                        }
                        return false;
                      },
                      child: ScrollAwarePreloader(
                        items: messages,
                        itemAverageHeight: 300.0,
                        preloadWindow: 30,
                        predictWidth: 240.0,
                        child: ListView.builder(
                          controller: scrollController, // Logic 变量
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          itemCount: messages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == messages.length) {
                              // 使用 Widget 分部的小组件
                              return _buildLoadingIndicator(context, chatState.hasMore);
                            }
                            final msg = messages[index];
                            return ChatBubble(
                              key: ValueKey(msg.id),
                              isGroup: isGroup,
                              message: msg,
                              showReadStatus: msg.isMe && msg.status == MessageStatus.read && index == 0,
                              onRetry: () => actionService.resend(msg.id),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 输入框
            if (canSend)
              ModernChatInputBar(
                conversationId: widget.conversationId,
                onSend: (text) => handleSendText(text), // Logic 方法
                onSendVoice: actionService.sendVoiceMessage,
                onSendImage: (file) => actionService.sendImage(file),
                onSendVideo: (file) => actionService.sendVideo(file),
                onAddPressed: togglePanel, // Logic 方法
                onTextFieldTap: closePanel, // Logic 方法
              )
            else
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                color: context.bgSecondary,
                alignment: Alignment.center,
                child: Text(disableReason, style: TextStyle(color: context.textSecondary700)),
              ),

            // 底部面板
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutQuad,
              height: isPanelOpen ? 280.h + MediaQuery.of(context).padding.bottom : 0, // Logic 变量
              color: context.bgPrimary,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ChatActionSheet(
                  actions: [
                    ActionItem(label: "Photos", icon: Icons.photo_library, onTap: handlePickImage),
                    ActionItem(label: "Camera", icon: Icons.camera_alt, onTap: handleTakePhoto),
                    ActionItem(label: "Video", icon: Icons.videocam, onTap: handlePickVideo),
                    ActionItem(label: "File", icon: Icons.folder, onTap: handleTakeFile),
                    ActionItem(label: "Location", icon: Icons.location_on, onTap: handleTakeLocation),
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