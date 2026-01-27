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
    final asyncDetail = ref.watch(chatDetailProvider(item.id));
    // 直接比较枚举，代码清晰易读
    final isSendFailed = item.lastMsgStatus == MessageStatus.failed;
    List<String?> avatarList = [];
    if (item.type == ConversationType.group) {
      // 1. 如果群组本身有设置专用大头像，优先用它
      if (item.avatar != null && item.avatar!.isNotEmpty) {
        avatarList = [item.avatar];
      } else {
        // 2. 如果没有专用头像，从缓存的详情里拿前 9 个成员的头像
        // asyncDetail.valueOrNull 在 SWR 模式下会瞬间返回本地缓存的数据
        final cachedMembers = asyncDetail.valueOrNull?.members;
        if (cachedMembers != null) {
          avatarList = cachedMembers.map((m) => m.avatar).toList();
        }
      }
    } else {
      // 私聊直接用对方头像
      avatarList = [item.avatar];
    }

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),

      // ===========================
      //  头像区域 (带红点) - 保持不变
      // ===========================
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          //  使用新组件
          GroupAvatar(
            memberAvatars: avatarList,
            size: 48.r, // 对应 radius 24
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
      //  摘要 (最后一条消息) - 核心修改
      // ===========================
      subtitle: Padding(
        padding: EdgeInsets.only(top: 4.h),
        child: Row(
          children: [
            //  失败图标 (只在失败时显示)
            if (isSendFailed) ...[
              Icon(
                Icons.error, // 红色感叹号
                size: 16.sp,
                color: Colors.red,
              ),
              SizedBox(width: 4.w), // 图标和文字的间距
            ],

            // 消息预览文字
            Expanded(
              child: Text(
                item.lastMsgContent ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  // 失败时文字稍微变红(可选)，正常时显示灰色
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

      // ===========================
      //  点击事件 - 保持不变
      // ===========================
      onTap: () {
        // 1. 调用 Provider 清除本地红点
        ref.read(conversationListProvider.notifier).clearUnread(item.id);

        // 2. 路由跳转到详情页
        context.push(
          '/chat/room/${item.id}?title=${Uri.encodeComponent(item.name)}',
        );
      },
    );
  }
}