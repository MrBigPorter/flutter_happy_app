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
    WidgetRef ref,
    ) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
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
      // 1. Video Call Button
      IconButton(
        icon: Icon(Icons.videocam, color: context.textPrimary900, size: 24.sp),
        onPressed: () {
          if (isGroup) {
            // Group video calls currently not supported
            return;
          }
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
          if (isGroup) return;
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

      // 3. More Actions (Profile/Settings)
      IconButton(
        icon: Icon(
          Icons.more_horiz,
          color: context.textPrimary900,
          size: 24.sp,
        ),
        onPressed: () {
          if (detail != null) {
            if (isGroup) {
              appRouter.push('/chat/group/profile/${detail.id}');
            } else {
              appRouter.push('/chat/direct/profile/${detail.id}');
            }
          }
        },
      ),
      SizedBox(width: 8.w),
    ],
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