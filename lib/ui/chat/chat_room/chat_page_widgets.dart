part of 'chat_page.dart';

// --- Component: Announcement Bar ---
class ChatAnnouncementBar extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const ChatAnnouncementBar({super.key, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.bgSecondary,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: context.borderPrimary, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.campaign,
                color: context.textBrandPrimary900,
                size: 20.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  text.replaceAll('\n', ' '),
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: context.textPrimary900,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.arrow_forward_ios,
                size: 12.sp,
                color: context.textSecondary700,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Helper: AppBar Construction Method ---
PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ConversationDetail? detail,
    bool isGroup,
    WidgetRef ref, {
      required String conversationId,
      VoidCallback? onSettingsTap,
      bool isSyncing = false, // <-- Added syncing flag for header loader
    }) {
  // 1. Retrieve current user ID
  final myUserId = ref.read(userProvider)?.id;

  // 2. Fetch TargetId directly using the Model method
  // Safe to call even if detail is null
  final targetUserId = detail?.getTargetId(myUserId);

  // 3. Title and Avatar configuration
  final displayName = detail?.getDisplayName(myUserId) ?? "Chat";
  final displayAvatar = detail?.getDisplayAvatar(myUserId);

  return AppBar(
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
      onPressed: () =>
      context.canPop() ? context.pop() : context.go('/conversations'),
    ),
    title: Row(
      children: [
        CircleAvatar(
          radius: 18.r,
          backgroundColor: Colors.grey[200],
          backgroundImage: detail?.avatar != null
              ? CachedNetworkImageProvider(
            UrlResolver.resolveImage(
              context,
              displayAvatar,
              logicalWidth: 36,
            ),
          )
              : null,
          child: detail?.avatar == null
              ? Icon(Icons.person, color: context.textSecondary700, size: 20.sp)
              : null,
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Silent Header Loader (WeChat/Telegram style)
              if (isSyncing) ...[
                SizedBox(width: 8.w),
                SizedBox(
                  width: 14.r,
                  height: 14.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.textSecondary700,
                  ),
                ),
              ]
            ],
          ),
        ),
      ],
    ),
    actions: [
      // Call buttons are hidden for group chats and customer-service
      // conversations (type SUPPORT or BUSINESS) — neither supports calls.
      if (!isGroup &&
          detail?.type != ConversationType.support &&
          detail?.type != ConversationType.business) ...[
        // 1. Video Call Button
        IconButton(
          icon: Icon(Icons.videocam, color: context.textPrimary900, size: 24.sp),
          onPressed: () {
            if (targetUserId == null) {
              // Target user not found
              return;
            }
            // Resolve full avatar URL to ensure CallPage renders correctly
            final avatarUrl = detail?.avatar != null
                ? UrlResolver.resolveImage(context, displayAvatar)
                : null;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CallPage(
                  targetId: targetUserId,
                  targetName: displayName,
                  targetAvatar: avatarUrl,
                  isVideo: true, // Enable camera
                ),
              ),
            );
          },
        ),

        // 2. Voice Call Button
        IconButton(
          icon: Icon(
            Icons.call,
            color: context.textPrimary900,
            size: 22.sp,
          ),
          onPressed: () {
            if (targetUserId == null) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CallPage(
                  targetId: targetUserId,
                  targetName: displayName,
                  targetAvatar: displayAvatar,
                  isVideo: false, // Voice-only mode
                ),
              ),
            );
          },
        ),
      ],

      // 3. Refresh / Re-Sync Button (shown when not actively syncing)
      if (!isSyncing)
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: context.textPrimary900,
            size: 22.sp,
          ),
          tooltip: 'Refresh',
          onPressed: () {
            // Read the ViewModel notifier and trigger incremental sync
            final notifier = ref.read(chatViewModelProvider(conversationId).notifier);
            notifier.performIncrementalSync();
          },
        ),

      // 4. More Actions (Profile/Settings)
      IconButton(
        icon: Icon(
          Icons.more_horiz,
          color: context.textPrimary900,
          size: 24.sp,
        ),
        onPressed: onSettingsTap, // Handled by logic layer
      ),
      SizedBox(width: 8.w),
    ],
  );
}

// ================================================================
//  AI 组件
// ================================================================

/// AI AppBar
PreferredSizeWidget _buildAiAppBar(
  BuildContext context,
  AiChatState aiState,
  AiChatViewModel notifier,
) {
  return AppBar(
    backgroundColor: context.bgPrimary,
    surfaceTintColor: Colors.transparent,
    elevation: 0.5,
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios_new, color: context.textPrimary900),
      onPressed: () => context.canPop() ? context.pop() : context.go('/conversations'),
    ),
    title: Row(
      children: [
        CircleAvatar(
          radius: 18.r,
          backgroundColor: context.bgSecondary,
          child: Icon(Icons.smart_toy, color: context.textBrandPrimary900, size: 20.sp),
        ),
        SizedBox(width: 10.w),
        Text('AI 智能客服', style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600)),
      ],
    ),
    actions: [
      if (aiState.isReceiving)
        IconButton(
          icon: Icon(Icons.stop, color: context.textPrimary900),
          onPressed: () => notifier.cancelStream(),
        ),
      if (aiState.messages.isNotEmpty)
        IconButton(
          icon: Icon(Icons.delete_outline, color: context.textPrimary900),
          onPressed: () => notifier.clearMessages(),
        ),
    ],
  );
}

/// AI 空状态
Widget _buildAiEmptyState(BuildContext context) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.smart_toy, size: 64, color: Colors.grey[300]),
        SizedBox(height: 16),
        Text('AI 智能客服', style: TextStyle(fontSize: 18, color: Colors.grey[400])),
        SizedBox(height: 8),
        Text('可以问我任何问题', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
      ],
    ),
  );
}

/// AI 状态文字（正在查余额...）
Widget _buildAiStatusText(BuildContext context, String statusText) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(
      children: [
        SizedBox(width: 8),
        SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
        SizedBox(width: 8),
        Text(statusText, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    ),
  );
}

/// AI 思考气泡（列表内，AI 侧气泡 + spinner + 状态文字）
Widget _buildAiThinkingBubble(BuildContext context, String statusText) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI 头像
        CircleAvatar(
          radius: 18.r,
          backgroundColor: context.bgSecondary,
          child: Icon(Icons.smart_toy, size: 20.sp, color: context.textBrandPrimary900),
        ),
        SizedBox(width: 8.w),
        // 白色圆角气泡 + spinner + 文字
        Container(
          constraints: BoxConstraints(maxWidth: 0.72.sw),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 14.w, height: 14.w,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(statusText,
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// AI 错误提示
Widget _buildAiErrorBar(
  BuildContext context,
  String error,
  VoidCallback onRetry,
) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(
      children: [
        Icon(Icons.error_outline, size: 14, color: Colors.red),
        SizedBox(width: 4),
        Expanded(
          child: Text(error, style: TextStyle(fontSize: 12, color: Colors.red)),
        ),
        TextButton(
          onPressed: onRetry,
          child: Text('重试', style: TextStyle(fontSize: 12)),
        ),
      ],
    ),
  );
}

/// AI 简单输入栏（只有文字，无语音/图片/文件）
Widget _buildAiInput(
  BuildContext context,
  TextEditingController textController,
  void Function(String) onSend,
) {
  return Container(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
    decoration: BoxDecoration(
      color: context.bgPrimary,
      border: Border(top: BorderSide(color: context.borderPrimary, width: 0.5)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: 12, top: 8, bottom: 8),
            child: TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: '输入消息...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: context.bgSecondary,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  onSend(text);
                  textController.clear();
                }
              },
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Icon(Icons.send, color: context.textBrandPrimary900),
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                onSend(text);
                textController.clear();
              }
            },
          ),
        ),
      ],
    ),
  );
}

// --- Component: Bottom Loading Indicator ---
Widget _buildLoadingIndicator(BuildContext context, bool hasMore) {
  if (hasMore) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      alignment: Alignment.center,
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: context.textBrandPrimary900,
        ),
      ),
    );
  } else {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      alignment: Alignment.center,
      child: Text(
        "—— No more history ——",
        style: TextStyle(color: Colors.grey[400], fontSize: 12),
      ),
    );
  }
}