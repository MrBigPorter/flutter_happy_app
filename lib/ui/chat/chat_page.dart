import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_app/ui/chat/services/chat_sync_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/image_url.dart';
import 'components/chat_bubble.dart';
import 'components/chat_input/modern_chat_input_bar.dart';
import 'models/chat_ui_model.dart';
import 'models/conversation.dart';
import 'providers/chat_room_provider.dart';

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

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // 1. Placeholder: Tell the whole app I'm viewing this room
      ref.read(activeConversationIdProvider.notifier).state = widget.conversationId;

      // 2. Refresh data (Delegate to SyncManager)
      ref.read(chatControllerProvider(widget.conversationId)).refresh();

      // 3. Clear red dot (Delegate to EventHandler)
      ref.read(chatControllerProvider(widget.conversationId)).markAsRead();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Clear active room state so red dots can reappear on list page
    try {
      ref.read(activeConversationIdProvider.notifier).state = null;
    } catch (_) {}
    super.dispose();
  }

  void _onScroll() {
    // Trigger load more when reaching the top
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 50) {
      ref.read(chatControllerProvider(widget.conversationId)).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep controller alive
    ref.watch(chatControllerProvider(widget.conversationId));

    // 1. Listen to messages stream (from Local Database)
    final asyncMessages = ref.watch(chatStreamProvider(widget.conversationId));

    // 2. Listen to detail stream (Avatar, Title)
    final asyncDetail = ref.watch(chatDetailProvider(widget.conversationId));
    final bool isGroup = asyncDetail.valueOrNull?.type == ConversationType.group;

    // Is updating silently? (Has data but fetching new ones)
    final isUpdating = asyncMessages.isLoading && asyncMessages.hasValue;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.bgPrimary,
        //  UI Polish: Messenger Style Header
        appBar: AppBar(
          backgroundColor: context.bgPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0.5,
          shadowColor: Colors.black.withValues(alpha: 0.1),
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
          // Title Row (Avatar + Name)
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
                    logicalWidth: 36, // 这里给两倍半径即可 (Radius 18 * 2)
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
                    if (isUpdating)
                      Text("Updating...", style: TextStyle(fontSize: 12.sp, color: context.textPrimary900))
                    else
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
              onPressed: (){
                if(isGroup){
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
            // Message List Area
            Expanded(
              child: asyncMessages.when(
                loading: () => asyncMessages.hasValue
                    ? _buildMessageList(asyncMessages.value!, isGroup)
                    : const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text("Error: $error")),
                data: (messages) => _buildMessageList(messages, isGroup),
              ),
            ),

            // Input Bar Area
            ModernChatInputBar(
              conversationId: widget.conversationId,
              // 1. Send Text
              onSend: (text) {
                ref.read(chatControllerProvider(widget.conversationId)).sendMessage(text);
              },
              // 2. Send Image (Delegated to ActionService)
              onSendImage: (XFile file) {
                ref.read(chatControllerProvider(widget.conversationId)).sendImage(file);
              },
              // 3.  NEW: Send Video (Delegated to ActionService)
              // (Ensure ModernChatInputBar exposes this callback)
              onSendVideo: (XFile file) {
                ref.read(chatControllerProvider(widget.conversationId)).sendVideo(file);
              },
              // 4. Send Voice
              onSendVoice: (String path, int duration) {
                ref.read(chatControllerProvider(widget.conversationId)).sendVoiceMessage(path, duration);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(List<dynamic> messages, bool isGroup) {
    if (messages.isEmpty) {
      return Center(child: Text("No messages", style: TextStyle(color: Colors.grey[400])));
    }

    // Determine the latest read message ID for the "Seen" indicator
    String? latestReadMsgId;
    for (final msg in messages) {
      if (msg is ChatUiModel && msg.isMe && msg.status == MessageStatus.read) {
        latestReadMsgId = msg.id;
        break;
      }
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        // Loading Spinner at the top (visually bottom in reverse list)
        if (index == messages.length) {
          final controller = ref.read(chatControllerProvider(widget.conversationId));
          // Use the property from SyncManager via Controller getter
          final hasMore = controller.hasMore;
          // Watch the separate loading state provider from SyncManager
          final isLoadingMore = ref.watch(chatLoadingMoreProvider(widget.conversationId));

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            alignment: Alignment.center,
            child: (hasMore && isLoadingMore)
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : (hasMore ? const SizedBox.shrink() : const Text("—— No more history ——", style: TextStyle(color: Colors.grey, fontSize: 12))),
          );
        }

        final msg = messages[index];
        final isLatestRead = (msg.id == latestReadMsgId);

        return ChatBubble(
          key: ValueKey(msg.id),
          isGroup: isGroup,
          message: msg,
          showReadStatus: isLatestRead,
          onRetry: () {
            // Call resend via ActionService
            ref.read(chatControllerProvider(widget.conversationId)).resendMessage(msg.id);
          },
        );
      },
    );
  }
}