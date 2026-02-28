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

  // Callback to bubble up long press events to the parent container
  final Function(ChatUiModel)? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.showReadStatus = false,
    this.isGroup = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Handle system messages or recalled messages with a centered gray tip
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
          // Remote participant's avatar
          if (!isMe) ...[
            _buildAvatar(message.senderAvatar),
            SizedBox(width: 8.w),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Display sender nickname in group chats
                if (!isMe && isGroup && message.senderName != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h, left: 4.w),
                    child: Text(
                      message.senderName!,
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                    ),
                  ),

                // Main message row body
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Delivery status prefix (Loading/Failed)
                    if (isMe) _buildStatusPrefix(),

                    Flexible(
                      child: GestureDetector(
                        // Forward long press events to the injected handler
                        onLongPress: () => onLongPress?.call(message),
                        child: _buildContentFactory(context),
                      ),
                    ),
                  ],
                ),

                // Read receipt indicator (Self only)
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

          // Current user's avatar
          if (isMe) ...[
            SizedBox(width: 8.w),
            _buildAvatar(message.senderAvatar),
          ],
        ],
      ),
    );
  }

  /// Render centered system notifications or recall alerts
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

  /// Factory method: Render specific bubble UI based on message type
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

  /// Avatar rendering with fallback icon
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

  /// Status icon prefix for outgoing messages
  Widget _buildStatusPrefix() {
    if (message.status == MessageStatus.pending) {
      return Padding(
        padding: EdgeInsets.only(right: 8.w, bottom: 4.h),
        child: Icon(Icons.access_time_rounded, size: 16.sp, color: Colors.grey[400]),
      );
    }
    if (message.status == MessageStatus.sending) {
      // Media messages handle their own internal loading states
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