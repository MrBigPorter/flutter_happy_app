import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';

import 'group_avatar.dart';

class ConversationItem extends ConsumerWidget {
  final Conversation item;

  const ConversationItem({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Time formatting
    final date = DateTime.fromMillisecondsSinceEpoch(item.lastMsgTime);
    final timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    // 2. Delivery failure status check
    final isSendFailed = item.lastMsgStatus == MessageStatus.failed;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),

      // ===========================
      // Avatar Area (With Badge)
      // ===========================
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          // Implementation Note: Listener for chatDetailProvider removed.
          // Directly using item.avatar. memberCount is passed as a constant 1 or 0
          // as rendering now primarily relies on backend-synthesized images.
          GroupAvatar(
            avatarUrl: item.avatar,
            size: 48.r,
          ),

          // Unread count badge
          if (item.unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.w),
                child: Center(
                  child: Text(
                    item.unreadCount > 99 ? '99+' : '${item.unreadCount}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

      // ===========================
      // Content Area
      // ===========================
      title: Text(
        item.name,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: context.textPrimary900,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 4.h),
        child: Row(
          children: [
            if (isSendFailed) ...[
              Icon(Icons.error, size: 16.sp, color: Colors.red),
              SizedBox(width: 4.w),
            ],
            Expanded(
              child: Text(
                item.lastMsgContent ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSendFailed ? Colors.red.withOpacity(0.8) : context.textSecondary700,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ],
        ),
      ),
      trailing: Text(
        timeStr,
        style: TextStyle(
          color: context.textPrimary900,
          fontSize: 12.sp,
        ),
      ),

      onTap: () {
        // Clear local unread status
        ref.read(conversationListProvider.notifier).clearUnread(item.id);

        // Navigate to chat room
        context.push(
          '/chat/room/${item.id}?title=${Uri.encodeComponent(item.name)}',
        );
      },
    );
  }
}