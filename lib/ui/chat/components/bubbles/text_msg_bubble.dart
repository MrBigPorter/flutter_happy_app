import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../models/chat_ui_model.dart';

class TextMsgBubble extends StatelessWidget {
  final ChatUiModel message;

  const TextMsgBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // 1. Data Preparation
    final isMe = message.isMe;
    final timeStr = DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(message.createdAt),
    );

    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 8.h),
      decoration: BoxDecoration(
        // WeChat-style green for self, white for others
        color: isMe ? const Color(0xFF95EC69) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.r),
          topRight: Radius.circular(12.r),
          // Dynamic corner radius based on sender identity
          bottomLeft: Radius.circular(isMe ? 12.r : 2.r),
          bottomRight: Radius.circular(isMe ? 2.r : 12.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      // Maximum width constrained to 72% of screen width
      constraints: BoxConstraints(maxWidth: 0.72.sw),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Message Content
          Text(
            message.content,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16.sp,
              height: 1.4,
            ),
          ),
          SizedBox(height: 2.h),
          // Small timestamp positioned at the bottom right
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 9.sp,
              color: isMe ? Colors.black.withOpacity(0.4) : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}