import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/chat_ui_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatUiModel message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 别人的头像
          if (!isMe) ...[
            CircleAvatar(
              radius: 18.r,
              backgroundColor: Colors.grey[300],
              backgroundImage: message.senderAvatar != null
                  ? NetworkImage(message.senderAvatar!)
                  : null,
              child: message.senderAvatar == null
                  ? const Icon(Icons.person, color: Colors.grey) : null,
            ),
            SizedBox(width: 8.w),
          ],

          // 2. 气泡本体
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 昵称 (别人的时候显示)
                if (!isMe && message.senderName != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h, left: 4.w),
                    child: Text(
                      message.senderName!,
                      style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                    ),
                  ),

                // 气泡背景
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF95EC69) : Colors.white, // 微信绿 vs 白色
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, offset: Offset(0, 1), blurRadius: 2)
                      ]
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15.sp,
                    ),
                  ),
                ),

                // 3. 状态 (Sending / Failed)
                if (isMe && message.status != MessageStatus.success)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h, right: 4.w),
                    child: message.status == MessageStatus.sending
                        ? SizedBox(
                        width: 10.w,
                        height: 10.w,
                        child: const CircularProgressIndicator(strokeWidth: 1)
                    )
                        : const Icon(Icons.error, size: 14, color: Colors.red),
                  ),
              ],
            ),
          ),

          // 4. 我的头像 (占位，实际项目可能显示在右边)
          if (isMe) ...[
            SizedBox(width: 8.w),
            CircleAvatar(
              radius: 18.r,
              backgroundColor: Colors.blue[100],
              child: const Icon(Icons.face),
            ),
          ]
        ],
      ),
    );
  }
}