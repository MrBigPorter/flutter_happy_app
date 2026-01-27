import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/chat_ui_model.dart';
import '../providers/chat_room_provider.dart';

import 'bubbles/image_msg_bubble.dart';
import 'bubbles/text_msg_bubble.dart';
import 'bubbles/video_msg_bubble.dart';
import 'bubbles/voice_bubble.dart';

class ChatBubble extends ConsumerWidget {
  final ChatUiModel message;
  final VoidCallback? onRetry;
  final bool showReadStatus;
  final bool isGroup;

  const ChatBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.showReadStatus = false,
    this.isGroup = false,
  });

  // 长按菜单逻辑 (保持不变)
  void _showContextMenu(BuildContext context, WidgetRef ref, bool isMe) {
    final bool isText = message.type == MessageType.text;
    final bool canRecall = isMe &&
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(message.createdAt)).inMinutes < 2;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text("Message Actions"),
        actions: [
          if (isText && !message.isRecalled)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.content));
              },
              child: const Text("Copy"),
            ),
          if (canRecall && !message.isRecalled)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                ref.read(chatControllerProvider(message.conversationId)).recallMessage(message.id);
              },
              child: const Text("Unsend for Everyone"),
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatControllerProvider(message.conversationId)).deleteMessage(message.id);
            },
            child: const Text("Remove for You"),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (message.isRecalled) return _buildRecalledSystemTip();

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
                // 群聊昵称
                if (!isMe && isGroup && message.senderName != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h, left: 4.w),
                    child: Text(
                      message.senderName!,
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                    ),
                  ),

                // 消息内容行 (状态 + 气泡)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 我发送的消息，状态在左边
                    if (isMe) _buildStatusPrefix(),

                    // 气泡本体 (包裹 GestureDetector 处理长按)
                    Flexible(
                      child: GestureDetector(
                        onLongPress: () => _showContextMenu(context, ref, isMe),
                        child: _buildContentFactory(context),
                      ),
                    ),
                  ],
                ),

                // 已读状态
                if (isMe && showReadStatus)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h, right: 2.w),
                    child: Text(
                      "Read",
                      style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.grey[400]),
                    ),
                  ),
              ],
            ),
          ),

          // 我的头像
          if (isMe) ...[SizedBox(width: 8.w), _buildAvatar(null)],
        ],
      ),
    );
  }

  Widget _buildContentFactory(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return ImageMsgBubble(message: message);
      case MessageType.audio:
        return VoiceBubble(message: message, isMe: message.isMe);
      case MessageType.video:
        return VideoMsgBubble(message: message);
      case MessageType.text:
      default:
        return TextMsgBubble(message: message);
    }
  }


  Widget _buildRecalledSystemTip() {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
        ),
        child: Text(
          message.isMe ? "You unsent a message" : "${message.senderName ?? 'Someone'} unsent a message",
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[500], fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Widget _buildStatusPrefix() {
    if (message.status == MessageStatus.pending) {
      return Padding(
        padding: EdgeInsets.only(right: 8.w, bottom: 4.h),
        child: Icon(Icons.access_time_rounded, size: 16.sp, color: Colors.grey[400]),
      );
    }
    if (message.status == MessageStatus.sending) {
      // 图片和视频自己有遮罩，不需要外面的转圈圈
      if (message.type == MessageType.image || message.type == MessageType.video) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.only(right: 8.w, bottom: 4.h),
        child: SizedBox(width: 14.w, height: 14.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)),
      );
    }
    if (message.status == MessageStatus.failed) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (onRetry != null) {
            HapticFeedback.lightImpact();
            onRetry!();
          }
        },
        child: Padding(
          padding: EdgeInsets.only(right: 8.w, bottom: 4.h),
          child: Icon(Icons.error, size: 20.sp, color: Colors.red[400]),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAvatar(String? url) {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.r),
        color: Colors.grey[200],
        image: url != null && url.isNotEmpty ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
      ),
      child: url == null || url.isEmpty ? Icon(Icons.person, color: Colors.grey[400], size: 24.sp) : null,
    );
  }
}