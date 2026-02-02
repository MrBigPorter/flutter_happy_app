import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';

// 引入你刚才封装好的 GroupAvatar 组件
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

    // 2. 监听详情（用于获取群成员列表）
    // valueOrNull 会在有缓存时立即返回数据，不会导致闪烁
    final asyncDetail = ref.watch(chatDetailProvider(item.id));

    // 3. 判断发送状态
    final isSendFailed = item.lastMsgStatus == MessageStatus.failed;

    //  4. 核心修复：构建安全的头像列表 List<String>
    List<String> avatarList = [];

    if (item.type == ConversationType.group) {
      // 策略 A: 如果群组本身有设置专用大头像 (item.avatar)，优先用它
      if (item.avatar != null && item.avatar!.isNotEmpty) {
        avatarList = [item.avatar!];
      } else {
        // 策略 B: 如果没有专用头像，从缓存的详情里拿前 9 个成员的头像拼九宫格
        final cachedMembers = asyncDetail.valueOrNull?.members;

        if (cachedMembers != null) {
          avatarList = cachedMembers
              .map((m) {
            // 1. 如果有真实头像，直接用
            if (m.avatar != null && m.avatar!.isNotEmpty) {
              return m.avatar!;
            }

            // 2. 如果是 null，生成一个“首字母头像”链接
            // 使用 ui-avatars.com 服务 (免费、稳定、支持中文)
            // background=random: 随机背景色
            // color=fff: 白色文字
            // name: 成员名字
            final safeName = Uri.encodeComponent(m.nickname);
            return "https://ui-avatars.com/api/?name=$safeName&background=random&color=fff&size=128";
          })
              .take(9) // 取前9个
              .toList(); // 这里不再需要 cast，因为 map 保证了返回 String
        }
      }
    } else {
      // 策略 C: 私聊直接用对方头像
      if (item.avatar != null && item.avatar!.isNotEmpty) {
        avatarList = [item.avatar!];
      }else{
        // 私聊没有头像时，使用默认头像服务
        final safeName = Uri.encodeComponent(item.name);
        avatarList = ["https://ui-avatars.com/api/?name=$safeName&background=random&color=fff&size=128"];
      }
    }

    // 注意：如果 avatarList 为空，GroupAvatar 组件内部的 DefaultGroupAvatar
    // 会自动显示默认的灰色图标或空九宫格，这是最规范的处理方式。

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),

      // ===========================
      //  头像区域 (带红点)
      // ===========================
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          // 真正的头像组件
          GroupAvatar(
            memberAvatars: avatarList, // ✅ 现在这里绝对是 List<String>
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
      //  标题 (群名/人名)
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
      //  摘要 (最后一条消息)
      // ===========================
      subtitle: Padding(
        padding: EdgeInsets.only(top: 4.h),
        child: Row(
          children: [
            // 失败图标
            if (isSendFailed) ...[
              Icon(
                Icons.error,
                size: 16.sp,
                color: Colors.red,
              ),
              SizedBox(width: 4.w),
            ],

            // 消息内容
            Expanded(
              child: Text(
                item.lastMsgContent ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  // 失败时文字稍微变红，正常时显示灰色
                  color: isSendFailed ? Colors.red.withOpacity(0.8) : context.textSecondary700,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ],
        ),
      ),

      // ===========================
      //  时间
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
      //   点击事件
      // ===========================
      onTap: () {
        // 1. 调用 Provider 清除本地红点
        ref.read(conversationListProvider.notifier).clearUnread(item.id);

        // 2. 路由跳转到详情页 (传递 title 防止详情页标题闪烁)
        context.push(
          '/chat/room/${item.id}?title=${Uri.encodeComponent(item.name)}',
        );
      },
    );
  }
}