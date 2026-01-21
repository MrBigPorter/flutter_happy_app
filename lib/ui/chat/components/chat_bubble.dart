import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:flutter_app/ui/img/app_image.dart';
import '../models/chat_ui_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatUiModel message;
  final VoidCallback? onRetry;

  const ChatBubble({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
      child: Row(
        // 布局方向：我是右对齐，对方是左对齐
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 对方头像 (左侧)
          if (!isMe) ...[
            _buildAvatar(message.senderAvatar),
            SizedBox(width: 8.w),
          ],

          // 2. 核心消息区域
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // A. 对方昵称
                if (!isMe && message.senderName != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h, left: 4.w),
                    child: Text(
                      message.senderName!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),

                // B. 气泡主体行 (包含 loading/error 状态图标)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // --- 我方状态图标 (Loading/Error) ---
                    if (isMe) _buildStatusPrefix(),

                    // --- 消息内容工厂 (文本/图片) ---
                    Flexible(child: _buildContentFactory(context, isMe)),
                  ],
                ),

                // C. "Read" 已读状态 (仅我方显示)
                if (isMe && message.status == MessageStatus.read)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h, right: 2.w),
                    child: Text(
                      "Read",
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

          // 3. 我方头像 (右侧)
          if (isMe) ...[
            SizedBox(width: 8.w),
            _buildAvatar(null), // 传 null 或传自己的头像 url
          ],
        ],
      ),
    );
  }

  //  内容工厂：根据 type 分发
  Widget _buildContentFactory(BuildContext context, bool isMe) {
    switch (message.type) {
      case MessageType.image:
        return _buildImageBubble(context, isMe);
      case MessageType.text:
      default:
        return _buildTextBubble(context, isMe);
    }
  }

  // =======================================================
  //  文本气泡
  // =======================================================
  Widget _buildTextBubble(BuildContext context, bool isMe) {
    final timeStr = DateFormat(
      'HH:mm',
    ).format(DateTime.fromMillisecondsSinceEpoch(message.createdAt));

    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 8.h),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF95EC69) : Colors.white,
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
          ),
        ],
      ),
      constraints: BoxConstraints(maxWidth: 0.72.sw),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.content,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16.sp,
              height: 1.4,
            ),
          ),
          SizedBox(height: 2.h),
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

  // =======================================================
  // 📸 图片气泡 (智能降级版)
  // =======================================================
  // =======================================================
  // 📸 图片气泡 (Web/Mobile 全兼容版)
  // =======================================================
  Widget _buildImageBubble(BuildContext context, bool isMe) {
    final double bubbleSize = 0.60.sw;
    final double dpr = MediaQuery.of(context).devicePixelRatio;
    final int cacheW = (bubbleSize * dpr).toInt();

    final bool canTryLocal =
        message.localPath != null && message.localPath!.isNotEmpty;

    final timeStr = DateFormat(
      'HH:mm',
    ).format(DateTime.fromMillisecondsSinceEpoch(message.createdAt));

    // 提取网络图组件 (复用)
    Widget buildNetworkImage() {
      return AppCachedImage(
        message.content,
        width: bubbleSize,
        height: bubbleSize,
        fit: BoxFit.cover,
        enablePreview: false,
      );
    }

    return Container(
      width: bubbleSize,
      height: bubbleSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        color: Colors.grey[50],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ==========================================
            // 🖼️ 核心渲染逻辑 (跨平台分流)
            // ==========================================
            if (canTryLocal)
              _buildLocalImage(
                path: message.localPath!,
                width: bubbleSize,
                height: bubbleSize,
                cacheW: cacheW,
                fallback: buildNetworkImage, // 传进去当兜底
              )
            else
              buildNetworkImage(),

            // ==========================================
            // 👇 点击预览
            // ==========================================
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final url = canTryLocal
                        ? message.localPath
                        : message.content;
                    debugPrint("预览图片: $url");
                  },
                ),
              ),
            ),

            // ==========================================
            // ⏳ 发送中 Loading
            // ==========================================
            if (message.status == MessageStatus.sending)
              Container(
                color: Colors.black38,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),

            // ==========================================
            // 🕒 时间戳
            // ==========================================
            Positioned(
              right: 6.w,
              bottom: 6.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  timeStr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //  新增：专门处理本地图片的跨平台组件
  Widget _buildLocalImage({
    required String path,
    required double width,
    required double height,
    required int cacheW,
    required Widget Function() fallback,
  }) {
    //  Web 端逻辑：把 Blob URL 当作网络图处理
    if (kIsWeb) {
      return Image.network(
        path, // Web 上 path 是 "blob:http://..."
        width: width,
        height: height,
        fit: BoxFit.cover,
        // Web 浏览器自带缓存管理，通常不需要手动 cacheWidth
        errorBuilder: (context, error, stack) {
          debugPrint(" [Web] Blob 加载失败，降级网络图: $error");
          return fallback();
        },
      );
    }

    // 📱 Mobile 端逻辑：使用 File
    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: BoxFit.cover,
      cacheWidth: cacheW,
      // 内存优化仅对 Mobile 有效
      gaplessPlayback: true,
      key: ValueKey("${message.id}_local"),
      errorBuilder: (context, error, stack) {
        debugPrint(" [Mobile] 本地文件失效，降级网络图: $error");
        return fallback();
      },
    );
  }

  //  状态前缀 (Loading圈 / 红色感叹号)
  Widget _buildStatusPrefix() {
    // 图片消息自带内部 Loading，这里不需要外部 Loading
    if (message.status == MessageStatus.sending) {
      if (message.type == MessageType.image) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: EdgeInsets.only(right: 8.w, bottom: 4.h),
        child: SizedBox(
          width: 14.w,
          height: 14.w,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey,
          ),
        ),
      );
    }

    // 失败状态 (点击重试)
    if (message.status == MessageStatus.failed) {
      return GestureDetector(
        onTap: onRetry,
        child: Padding(
          padding: EdgeInsets.only(right: 8.w, bottom: 4.h),
          child: Icon(Icons.error, size: 20.sp, color: Colors.red[400]),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // 🛠️ 头像组件
  Widget _buildAvatar(String? url) {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.r),
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
