import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../models/chat_ui_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatUiModel message;
  final VoidCallback? onRetry;

  const ChatBubble({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;

    // 格式化时间
    final timeStr = DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(message.createdAt),
    );

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 对方头像
          if (!isMe) ...[
            _buildAvatar(message.senderAvatar),
            SizedBox(width: 8.w),
          ],

          // 2. 核心内容区域 (使用 Flexible 防止溢出)
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // A. 昵称 (仅群聊且对方发送时显示)
                if (!isMe && message.senderName != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h, left: 4.w),
                    child: Text(
                      message.senderName!,
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                    ),
                  ),

                // B. 气泡行 (包含：[加载/失败图标] + [气泡])
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end, // 底部对齐，方便对齐时间
                  children: [
                    // --- 发送者独有：加载中/失败图标在气泡左侧 ---
                    if (isMe) _buildStatusPrefix(),

                    // --- 气泡本体 ---
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 8.h),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF95EC69) : Colors.white,
                          // 🔥 优化圆角：发送者右上角直角，接收者左上角直角
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12.r),
                            topRight: Radius.circular(12.r),
                            bottomLeft: Radius.circular(isMe ? 12.r : 2.r),
                            bottomRight: Radius.circular(isMe ? 2.r : 12.r),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              offset: const Offset(0, 1),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        // 限制气泡最大宽度
                        constraints: BoxConstraints(maxWidth: 0.72.sw),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end, // 内容靠左，但时间靠右
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 消息文本 (使用 Stack 或者 Wrap 可以做更高级的文字环绕，这里用简单的 Column)
                            Text(
                              message.content,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16.sp,
                                height: 1.4, // 舒适的行高
                              ),
                            ),

                            SizedBox(height: 2.h), // 文字和时间的间距

                            // 时间戳 (右下角微型显示)
                            Text(
                              timeStr, // 显示真实时间
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: isMe ? Colors.black.withOpacity(0.4) : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // C. 底部状态行 (仅发送者显示 "Read" 或 "已读")
                // 将 Read 状态移到气泡外面下方，这是目前最主流的做法 (Messenger风格)
                if (isMe && message.status == MessageStatus.read)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h, right: 2.w),
                    child: Text(
                      "Read", // 已读
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 3. 我的头像
          if (isMe) ...[
            SizedBox(width: 8.w),
            _buildAvatar(null),
          ],
        ],
      ),
    );
  }

  // 左侧的状态指示器 (加载/失败)
  Widget _buildStatusPrefix() {
    if (message.status == MessageStatus.sending) {
      return Padding(
        padding: EdgeInsets.only(right: 8.w, bottom: 4.h), // 稍微留点空隙
        child: SizedBox(
          width: 14.w,
          height: 14.w,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey,
          ),
        ),
      );
    } else if (message.status == MessageStatus.failed) {
      return GestureDetector(
        onTap: onRetry,
        child: Padding(
          padding: EdgeInsets.only(right: 8.w, bottom: 4.h),
          child: Icon(
            Icons.error,
            size: 20.sp,
            color: Colors.red[400],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAvatar(String? url) {
    return Container(
      width: 40.w, // 头像稍大一点
      height: 40.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.r), // 微圆角
        color: Colors.grey[200],
        image: url != null && url.isNotEmpty
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: url == null || url.isEmpty
          ? Icon(Icons.person, color: Colors.grey[400], size: 24.sp)
          : null,
    );
  }
}