import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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

    return Slidable(
      key: ValueKey(item.id),
      // Left swipe: Pin / Unpin (Apple-style flat action)
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              final newPinned = !item.isPinned;
              ref.read(conversationSettingsControllerProvider.notifier)
                  .togglePin(item.id, newPinned);
            },
            backgroundColor: context.utilityBrand50,
            foregroundColor: context.utilityBrand500,
            icon: item.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            label: item.isPinned ? 'Unpin' : 'Pin',
            borderRadius: BorderRadius.zero,
          ),
        ],
      ),
      // Right swipe: Mute / Delete (Apple-style flat actions)
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              final newMuted = !item.isMuted;
              ref.read(conversationSettingsControllerProvider.notifier)
                  .toggleMute(item.id, newMuted);
            },
            backgroundColor: context.bgWarningPrimary,
            foregroundColor: context.textPrimary900,
            icon: item.isMuted ? Icons.notifications : Icons.notifications_off,
            label: item.isMuted ? 'Unmute' : 'Mute',
            borderRadius: BorderRadius.zero,
          ),
          SlidableAction(
            onPressed: (_) => _confirmDelete(context, ref),
            backgroundColor: context.bgErrorPrimary,
            foregroundColor: context.textPrimary900,
            icon: Icons.delete_outline,
            label: 'Delete',
            borderRadius: BorderRadius.zero,
          ),
        ],
      ),

      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),

        // ===========================
        // Avatar Area (With Badge)
        // ===========================
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            GroupAvatar(
              avatarUrl: item.avatar,
              size: 48.r,
            ),

            if (item.unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: item.isMuted
                    ?
                Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                )
                    :
                Container(
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
        title: Row(
          children: [
            Flexible(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (item.isMuted) ...[
              SizedBox(width: 4.w),
              Icon(Icons.notifications_off, size: 14.sp, color: Colors.grey[400]),
            ],
          ],
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
          ref.read(conversationListProvider.notifier).clearUnread(item.id);
          context.push(
            '/chat/room/${item.id}?title=${Uri.encodeComponent(item.name)}',
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(conversationSettingsControllerProvider.notifier)
                  .clearHistory(item.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}