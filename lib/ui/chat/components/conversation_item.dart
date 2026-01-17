import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

// 🔥 引入相关 Provider 和 Model
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';

class ConversationItem extends ConsumerWidget {
  final Conversation item;

  const ConversationItem({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 时间格式化 (简单版：HH:mm)
    // 如果需要 "昨天"、"星期几" 这种复杂格式，建议写个扩展函数
    final date = DateTime.fromMillisecondsSinceEpoch(item.lastMsgTime);
    final timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),

      // ===========================
      // 🟢 头像区域 (带红点)
      // ===========================
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          // 头像
          CircleAvatar(
            radius: 24.r,
            backgroundColor: Colors.grey[200],
            backgroundImage: (item.avatar != null && item.avatar!.isNotEmpty)
                ? NetworkImage(item.avatar!)
                : null,
            child: (item.avatar == null || item.avatar!.isEmpty)
                ? Icon(Icons.person, color: Colors.grey[500], size: 24.r)
                : null,
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
      // 🔵 标题 (群名/人名)
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
      // 🟡 摘要 (最后一条消息)
      // ===========================
      subtitle: Padding(
        padding: EdgeInsets.only(top: 4.h),
        child: Text(
          item.lastMsgContent ?? '', // 如果没有消息显示空
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.textSecondary700,
            fontSize: 13.sp,
          ),
        ),
      ),

      // ===========================
      // 🟣 时间
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
          // 这里以后可以扩展：比如显示免打扰图标
        ],
      ),

      // ===========================
      // 🔥 点击事件
      // ===========================
      onTap: () {
        // 1. 调用 Provider 清除本地红点
        ref.read(conversationListProvider.notifier).clearUnread(item.id);

        // 2. 路由跳转到详情页
        // 传参：ID 和 Title (用于 AppBar 显示)
        context.push(
          '/chat/${item.id}?title=${Uri.encodeComponent(item.name)}',
        );
      },
    );
  }
}