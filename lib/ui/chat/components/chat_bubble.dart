import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../img/app_image.dart';
import '../models/chat_ui_model.dart';
import '../providers/chat_room_provider.dart';

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

  const ChatBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.showReadStatus = false,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1.  统一拦截：系统消息或已撤回消息，显示为居中灰色提示
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
                    if (isMe) _buildStatusPrefix(),
                    Flexible(
                      child: GestureDetector(
                        //  只有正常消息才允许长按弹出菜单
                        onLongPress: () => _showContextMenu(context, ref, isMe),
                        child: _buildContentFactory(context),
                      ),
                    ),
                  ],
                ),

                // 已读标识
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

  Widget _buildCenteredSystemTip() {
    String tipText;

    // 优先判断：这到底是不是“撤回”操作
    if (message.isRecalled) {
      final String displayName = message.isMe ? "You" : (message.senderName ?? 'Someone');
      tipText = "$displayName recalled a message";
    }
    // 如果不是撤回，而是系统消息 (Type 99)
    else if (message.type == MessageType.system) {
      // 直接显示 content，它是后端生成的文案（如 "Group name updated..."）
      tipText = message.content;
    }
    else {
      tipText = "";
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
            // 只有撤回才用斜体，普通系统消息用正体
            fontStyle: message.isRecalled ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }

  /// 根据消息类型分发具体的渲染组件
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

  /// 长按菜单逻辑
  void _showContextMenu(BuildContext context, WidgetRef ref, bool isMe) {
    final bool isText = message.type == MessageType.text;
    final bool canRecall = isMe &&
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(message.createdAt)).inMinutes < 2;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text("Message Actions"),
        actions: [
          if (isText)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.content));
              },
              child: const Text("Copy"),
            ),
          if (canRecall)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                ref.read(chatControllerProvider(message.conversationId)).recallMessage(message.id);
              },
              child: const Text("Recall"), //  统一用 Recall
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatControllerProvider(message.conversationId)).deleteMessage(message.id);
            },
            child: const Text("Delete"),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ),
    );
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

  /// 状态图标渲染 (发送中/失败/等待)
  Widget _buildStatusPrefix() {
    if (message.status == MessageStatus.pending) {
      return Padding(
        padding: EdgeInsets.only(right: 8.w, bottom: 4.h),
        child: Icon(Icons.access_time_rounded, size: 16.sp, color: Colors.grey[400]),
      );
    }
    if (message.status == MessageStatus.sending) {
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