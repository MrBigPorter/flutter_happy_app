import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/store/user_store.dart';
import 'package:flutter_app/ui/modal/dialog/radix_modal.dart';
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
import '../../toast/radix_toast.dart';
import '../call/call_page.dart';
import '../components/chat_bubble.dart';
import '../components/chat_input/modern_chat_input_bar.dart';
import '../models/chat_ui_model.dart';
import '../models/conversation.dart';
import '../models/selection_types.dart';

// Logic and Widget parts declaration
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

class _ChatPageState extends ConsumerState<ChatPage> with ChatPageLogic {

  @override
  void dispose() {
    disposeLogic();
    try {
      // Clear active conversation ID state on dispose
      ref.read(activeConversationIdProvider.notifier).state = null;
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize the chat controller
    ref.watch(chatControllerProvider(widget.conversationId));

    // Synchronize the active conversation ID for signaling or notification filtering
    Future.microtask(() {
      if (mounted) ref.read(activeConversationIdProvider.notifier).state = widget.conversationId;
    });

    // Data Source and View Models
    final chatState = ref.watch(chatViewModelProvider(widget.conversationId));
    final viewModel = ref.read(chatViewModelProvider(widget.conversationId).notifier);
    final messages = chatState.messages;
    final actionService = ref.read(chatActionServiceProvider(widget.conversationId));

    // Conversation Detail Fetching
    final groupAsync = ref.watch(chatGroupProvider(widget.conversationId));
    final basicAsync = ref.watch(chatDetailProvider(widget.conversationId));
    final detail = groupAsync.valueOrNull ?? basicAsync.valueOrNull;
    final bool isGroup = detail?.type == ConversationType.group;

    // Permission and Restriction Check
    final permission = checkPermission(detail, isGroup);
    final bool canSend = permission.canSend;
    final String disableReason = permission.reason;

    // Announcement Handling
    final announcement = detail?.announcement;
    final hasAnnouncement = announcement != null && announcement.trim().isNotEmpty;

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        backgroundColor: context.bgPrimary,
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(context, detail, isGroup, ref),
        body: Column(
          children: [
            // Announcement Bar (Group chats only)
            if (hasAnnouncement && isGroup)
              ChatAnnouncementBar(
                text: announcement,
                onTap: () => showAnnouncementDialog(context, announcement),
              ),

            // Message List Area
            Expanded(
              child: Builder(
                builder: (context) {
                  // Initial loading state
                  if (messages.isEmpty && chatState.isInitializing) {
                    return Center(child: CircularProgressIndicator(strokeWidth: 2, color: context.textBrandPrimary900));
                  }
                  // Empty state
                  if (messages.isEmpty && !chatState.isInitializing) {
                    return Center(child: Text("No messages yet", style: TextStyle(color: Colors.grey[400])));
                  }
                  return GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      closePanel();
                    },
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        // Pagination logic: Load more when reaching top threshold
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
                          controller: scrollController,
                          reverse: true, // Newer messages at the bottom
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          itemCount: messages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == messages.length) {
                              return _buildLoadingIndicator(context, chatState.hasMore);
                            }
                            final msg = messages[index];
                            return ChatBubble(
                              key: ValueKey(msg.id),
                              isGroup: isGroup,
                              message: msg,
                              showReadStatus: msg.isMe && msg.status == MessageStatus.read && index == 0,
                              onRetry: () => actionService.resend(msg.id),
                              // Forward long press events to the logic layer handler
                              onLongPress: (m) => onMessageLongPress(context, m),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input Section
            if (canSend)
              ModernChatInputBar(
                conversationId: widget.conversationId,
                onSend: (text) => handleSendText(text),
                onSendVoice: actionService.sendVoiceMessage,
                onSendImage: (file) => actionService.sendImage(file),
                onSendVideo: (file) => actionService.sendVideo(file),
                onAddPressed: togglePanel,
                onTextFieldTap: closePanel,
              )
            else
            // Disabled Input State (Muted or Group Restriction)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                color: context.bgSecondary,
                alignment: Alignment.center,
                child: Text(disableReason, style: TextStyle(color: context.textSecondary700)),
              ),

            // Functional Bottom Panel (Action Grid)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutQuad,
              height: isPanelOpen ? 280.h + MediaQuery.of(context).padding.bottom : 0,
              color: context.bgPrimary,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ChatActionSheet(
                  type: ActionSheetType.grid,
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