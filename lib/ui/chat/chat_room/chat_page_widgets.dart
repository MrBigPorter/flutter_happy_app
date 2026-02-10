part of 'chat_page.dart';

// --- 组件：公告栏 ---
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

// --- 组件：AppBar 构建方法 ---
// 注意：这是 top-level 函数，因为它是 part of chat_page.dart，所以可以访问 import
PreferredSizeWidget _buildAppBar(
  BuildContext context,
  ConversationDetail? detail,
  bool isGroup,
) {
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
                    detail!.avatar!,
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
                detail?.name ?? "Chat",
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

// --- 组件：底部 Loading ---
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
