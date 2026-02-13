import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../img/app_image.dart';
import '../models/chat_ui_model.dart';

import 'bubbles/file_msg_bubble.dart';
import 'bubbles/image_msg_bubble.dart';
import 'bubbles/text_msg_bubble.dart';
import 'bubbles/video_msg_bubble.dart';
import 'bubbles/voice_bubble.dart';
import 'bubbles/location_msg_bubble.dart';

class ChatBubble extends ConsumerWidget {
  final ChatUiModel message;
  final VoidCallback? onRetry;
  final bool showReadStatus;
  final bool isGroup;

  //  [核心改动] 新增回调：将长按事件抛给父组件处理
  final Function(ChatUiModel)? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.showReadStatus = false,
    this.isGroup = false,
    this.onLongPress, // 构造函数接收
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 系统消息或撤回消息：显示居中灰条
    if (message.isRecalled || message.type == MessageType.system) {
      return _buildCenteredSystemTip();
    }

    final isMe = message.isMe;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 对方头像
          if (!isMe) ...[
            _buildAvatar(message.senderAvatar),
            SizedBox(width: 8.w),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 群聊中显示对方昵称
                if (!isMe && isGroup && message.senderName != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h, left: 4.w),
                    child: Text(
                      message.senderName!,
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                    ),
                  ),

                // 消息主体行
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 发送状态图标 (Loading/Fail)
                    if (isMe) _buildStatusPrefix(),

                    Flexible(
                      child: GestureDetector(
                        //  [核心改动] 不再自己处理，而是调用回调
                        onLongPress: () => onLongPress?.call(message),
                        child: _buildContentFactory(context),
                      ),
                    ),
                  ],
                ),

                // 已读标识 (仅自己)
                if (isMe && showReadStatus)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h, right: 2.w),
                    child: Text(
                      "Read",
                      style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[400]
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 我的头像
          if (isMe) ...[
            SizedBox(width: 8.w),
            _buildAvatar(message.senderAvatar),
          ],
        ],
      ),
    );
  }

  /// 构建居中系统提示
  Widget _buildCenteredSystemTip() {
    String tipText;
    if (message.isRecalled) {
      final String displayName = message.isMe ? "You" : (message.senderName ?? 'Someone');
      tipText = "$displayName recalled a message";
    } else {
      tipText = message.content;
    }

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
        child: Text(
          tipText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.sp,
            color: const Color(0xFFB0B0B0),
            fontStyle: message.isRecalled ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }

  /// 工厂方法：根据类型渲染具体气泡
  Widget _buildContentFactory(BuildContext context) {
    switch (message.type) {
      case MessageType.image: return ImageMsgBubble(message: message);
      case MessageType.audio: return VoiceBubble(message: message, isMe: message.isMe);
      case MessageType.video: return VideoMsgBubble(message: message, isMe: message.isMe);
      case MessageType.file: return FileMsgBubble(message: message);
      case MessageType.location: return LocationMsgBubble(message: message);
      case MessageType.text:
      default:
        return TextMsgBubble(message: message);
    }
  }

  /// 头像渲染
  Widget _buildAvatar(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.r),
          color: Colors.grey[200],
        ),
        child: Icon(Icons.person, color: Colors.grey[400], size: 24.sp),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6.r),
      child: AppCachedImage(
        url,
        width: 40.w,
        height: 40.w,
        fit: BoxFit.cover,
        enablePreview: false,
      ),
    );
  }

  /// 状态图标前缀
  Widget _buildStatusPrefix() {
    if (message.status == MessageStatus.pending) {
      return Padding(
        padding: EdgeInsets.only(right: 8.w, bottom: 4.h),
        child: Icon(Icons.access_time_rounded, size: 16.sp, color: Colors.grey[400]),
      );
    }
    if (message.status == MessageStatus.sending) {
      // 图片视频自带 Loading 遮罩，不需要外面的转圈
      if (message.type == MessageType.image || message.type == MessageType.video) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.only(right: 8.w, bottom: 4.h),
        child: SizedBox(
          width: 14.w, height: 14.w,
          child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
        ),
      );
    }
    if (message.status == MessageStatus.failed) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onRetry?.call(),
        child: Padding(
          padding: EdgeInsets.only(right: 8.w, bottom: 4.h),
          child: Icon(Icons.error, size: 20.sp, color: Colors.red[400]),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}