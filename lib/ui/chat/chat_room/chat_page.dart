import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/store/user_store.dart';
import 'package:flutter_app/ui/modal/dialog/radix_modal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/services/customer_service/customer_service_helper.dart';
import 'package:flutter_app/core/store/ai_chat/ai_chat_view_model.dart';
import 'package:flutter_app/core/store/ai_chat/ai_chat_state.dart';
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
  final _aiTextController = TextEditingController();

  /// 入口上下文（从 CustomerServiceHelper 暂存）
  String? _entryPoint;
  Map<String, dynamic>? _entryMetadata;

  /// 是否已自动发送上下文消息（防重复）
  bool _autoSentContext = false;

  /// 是否已转人工（由 AiChatViewModel.onTransfer 设为 true）
  bool _transferredToHuman = false;

  @override
  void initState() {
    super.initState();
    // 消费入口上下文
    _entryPoint = CustomerServiceHelper.pendingEntryPoint;
    _entryMetadata = CustomerServiceHelper.pendingMetadata;
    CustomerServiceHelper.pendingEntryPoint = null;
    CustomerServiceHelper.pendingMetadata = null;

    initLogic();
  }

  @override
  void dispose() {
    _aiTextController.dispose();
    disposeLogic();
    try {
      ref.read(activeConversationIdProvider.notifier).state = null;
    } catch (_) {}
    super.dispose();
  }

  /// 转人工 — 由 AiChatViewModel.onTransfer 触发
  void _onTransferToHuman() {
    if (!mounted) return;
    setState(() => _transferredToHuman = true);
  }

  /// 根据入口上下文构造 AI 初始消息
  String _buildContextMessage(String entryPoint, Map<String, dynamic>? metadata) {
    switch (entryPoint) {
      case 'order_detail':
        final orderId = metadata?['orderId'] ?? '';
        return 'Check my order $orderId status';
      case 'deposit':
        final depositId = metadata?['depositId'] ?? '';
        return 'Check my deposit $depositId status';
      case 'profile':
        return 'Check my profile';
      default:
        return 'Hello';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── 通过 Conversation.type 决定 AI 还是 IM 模式 ──
    // 所有客服对话（support/ai）默认走 AI，群聊/私聊走 IM。
    // 详情还没加载时乐观默认 AI（新对话大概率是客服）。
    final groupAsync = ref.watch(chatGroupProvider(widget.conversationId));
    final basicAsync = ref.watch(chatDetailProvider(widget.conversationId));
    final detail = groupAsync.valueOrNull ?? basicAsync.valueOrNull;

    final bool useAiMode;
    if (_transferredToHuman) {
      useAiMode = false;
    } else if (detail != null) {
      useAiMode = detail.type == ConversationType.support ||
                  detail.type == ConversationType.ai;
    } else {
      useAiMode = widget.conversationId == kAiConversationId;
    }

    // ── AI 模式：不走 Socket，走 SSE ──
    if (useAiMode) {
      // 把 onTransfer 回调传递给 AiChatViewModel
      final aiProvider = aiChatViewModelProvider(widget.conversationId);
      final aiState = ref.watch(aiProvider);
      final aiNotifier = ref.read(aiProvider.notifier)
        ..onTransfer = _onTransferToHuman;
      final bool isGroup = detail?.type == ConversationType.group;

      // 首次进入且有入口上下文 → 自动发给 AI 处理
      if (!_autoSentContext && _entryPoint != null && aiState.messages.isEmpty) {
        _autoSentContext = true;
        final contextMsg = _buildContextMessage(_entryPoint!, _entryMetadata);
        Future.microtask(() => aiNotifier.sendMessage(contextMsg));
      }

      debugPrint('[ChatPage] AI build: messages=${aiState.messages.length}');

      // 思考气泡：SSE 活跃、未收到 token、有状态文字时在列表底部显示
      final bool showThinking = aiState.isReceiving &&
          aiState.currentStreamContent.isEmpty &&
          aiState.statusText.isNotEmpty;

      return WillPopScope(
        onWillPop: onWillPop,
        child: Scaffold(
          backgroundColor: context.bgPrimary,
          resizeToAvoidBottomInset: true,
          appBar: _buildAppBar(context, detail, isGroup, ref,
            conversationId: widget.conversationId,
          ),
          body: Column(
            children: [
	              // 消息列表
	              Expanded(
	                child: aiState.messages.isEmpty && !showThinking
	                    ? Center(
	                        child: Text("No messages yet",
	                          style: TextStyle(color: Colors.grey[400], fontSize: 15),
	                        ),
	                      )
	                    : ListView.builder(
	                        reverse: true,
	                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
	                        itemCount: aiState.messages.length + (showThinking ? 1 : 0),
	                        itemBuilder: (context, index) {
	                          if (showThinking && index == 0) {
	                            return _buildAiThinkingBubble(context, aiState.statusText);
	                          }
	                          final msgIndex = showThinking ? index - 1 : index;
	                          final msg = aiState.messages[msgIndex];
	                          return ChatBubble(
	                            key: ValueKey(msg.id),
	                            isGroup: false,
	                            message: msg,
	                          );
	                        },
	                      ),
	              ),
              // 错误提示（AI 出错时显示）
              if (aiState.error != null)
                _buildAiErrorBar(context, aiState.error!, aiNotifier.retry),
              // 输入栏 — 使用与 IM 相同的 ModernChatInputBar
              ModernChatInputBar(
                conversationId: widget.conversationId,
                onSend: (text) => aiNotifier.sendMessage(text),
                onSendVoice: (_, __) {},
                onSendImage: (_) {},
                onSendVideo: (_) {},
                onAddPressed: () {},
                onTextFieldTap: () {},
              ),
            ],
          ),
        ),
      );
    }

    // ── IM 模式：走 Socket ──
    ref.watch(chatControllerProvider(widget.conversationId));

    // Synchronize the active conversation ID for signaling or notification filtering
    Future.microtask(() {
      if (mounted) ref.read(activeConversationIdProvider.notifier).state = widget.conversationId;
    });

    // Data Source and View Models
    final chatState = ref.watch(chatViewModelProvider(widget.conversationId));
    final messages = chatState.messages;
    final actionService = ref.read(chatActionServiceProvider(widget.conversationId));

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
        // Pass the isSyncing state and settings callback to the AppBar
        appBar: _buildAppBar(
            context,
            detail,
            isGroup,
            ref,
            conversationId: widget.conversationId,
            // Show AppBar spinner whenever syncing, even when messages are visible.
            // This is WeChat/Telegram style: content shows instantly, spinner signals background sync.
            isSyncing: chatState.isInitializing,
            onSettingsTap: () {
              if (detail != null) {
                goToSettingsAndHandleSearch(detail, isGroup);
              }
            }
        ),
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
                  // Empty state: Only display this when initialization is completely done
                  if (messages.isEmpty && !chatState.isInitializing) {
                    return Center(
                      child: GestureDetector(
                        onTap: () {
                          final notifier = ref.read(chatViewModelProvider(widget.conversationId).notifier);
                          notifier.performIncrementalSync();
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                            SizedBox(height: 12),
                            Text(
                              "No messages yet",
                              style: TextStyle(color: Colors.grey[400], fontSize: 15),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Tap to retry",
                              style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          closePanel();
                        },
                        child: ScrollAwarePreloader(
                          items: messages,
                          itemAverageHeight: 300.0,
                          preloadWindow: 30,
                          predictWidth: 240.0,
                          // ScrollablePositionedList replaces standard ListView
                          child: ScrollablePositionedList.builder(
                            itemScrollController: itemScrollController,
                            itemPositionsListener: itemPositionsListener,
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

                      // Scroll-to-bottom FAB (visible when not at bottom)
                      if (!isAtBottom)
                        Positioned(
                          right: 8.w,
                          bottom: 8.h,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isAtBottom ? 0.0 : 1.0,
                            child: FloatingActionButton.small(
                              heroTag: 'scroll_to_bottom',
                              backgroundColor: context.bgPrimary,
                              elevation: 3,
                              onPressed: scrollToBottom,
                              child: Icon(
                                Icons.arrow_downward,
                                color: context.textBrandPrimary900,
                              ),
                            ),
                          ),
                        ),
                    ],
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