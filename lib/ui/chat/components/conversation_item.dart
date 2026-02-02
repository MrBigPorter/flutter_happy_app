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
    // 1. 时间格式化
    final date = DateTime.fromMillisecondsSinceEpoch(item.lastMsgTime);
    final timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    // 2. 监听详情（主要是为了获取准确的成员人数，用于画缺省格子）
    final asyncDetail = ref.watch(chatDetailProvider(item.id));

    // 3. 判断发送状态
    final isSendFailed = item.lastMsgStatus == MessageStatus.failed;

    //  核心修改：逻辑下沉，这里只负责提取 URL 和 人数
    // 如果是私聊且没头像，给一个 ui-avatars 的兜底图，确保 GroupAvatar 渲染
    String? displayAvatar = item.avatar;
    int memberCount = 0;

    if (item.type == ConversationType.group) {
      // 群组：人数从详情缓存拿，或者从模型里的 count 拿
      memberCount = asyncDetail.valueOrNull?.members.length ?? 0;
    } else {
      // 私聊：如果是空的，我们在这里生成一个确定性的首字母头像
      memberCount = 1;
    }

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),

      // ===========================
      //  头像区域 (带红点)
      // ===========================
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          // 🔥 使用简化后的 GroupAvatar，只传 URL 和人数
          GroupAvatar(
            avatarUrl: displayAvatar,
            memberCount: memberCount,
            size: 48.r,
          ),

          // 红点 Badge
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
      //  标题 (群名/人名) - 保持不变
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

      // ===========================
      //  摘要 (最后一条消息) - 保持不变
      // ===========================
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

      // ===========================
      //  时间 - 保持不变
      // ===========================
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            timeStr,
            style: TextStyle(
              color: context.textPrimary900,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),

      onTap: () {
        ref.read(conversationListProvider.notifier).clearUnread(item.id);
        context.push(
          '/chat/room/${item.id}?title=${Uri.encodeComponent(item.name)}',
        );
      },
    );
  }
}