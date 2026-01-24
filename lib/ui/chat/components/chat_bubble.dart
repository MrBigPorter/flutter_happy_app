import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/ui/chat/components/voice_bubble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:flutter_app/ui/img/app_image.dart';
import '../models/chat_ui_model.dart';
import '../photo_preview_page.dart';
import '../providers/chat_room_provider.dart';

class ChatBubble extends ConsumerWidget {
  final ChatUiModel message;
  final VoidCallback? onRetry;
  final bool showReadStatus;

  const ChatBubble({super.key, required this.message, this.onRetry, this.showReadStatus = false});

  void _showContextMenu(BuildContext context, WidgetRef ref, bool isMe) {
    final bool isText = message.type == MessageType.text;
    final bool canRecall =
        isMe &&
        DateTime.now()
                .difference(
                  DateTime.fromMillisecondsSinceEpoch(message.createdAt),
                )
                .inMinutes <
            2;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text("Message Actions"),
        actions: [
          if (isText && !message.isRecalled) // 撤回的消息不能再复制内容
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.content));
              },
              child: const Text("Copy"),
            ),

          // --- 撤回逻辑 (Unsend for everyone) ---
          if (canRecall && !message.isRecalled)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                //  核心：调用 Notifier 执行撤回
                ref
                    .read(chatControllerProvider(message.conversationId))
                    .recallMessage(message.id);
              },
              child: const Text("Unsend for Everyone"),
            ),

          // --- 删除逻辑 (Remove for you) ---
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              // 本地删除，调用 Notifier 移除该消息
              ref
                  .read(chatControllerProvider(message.conversationId))
                  .deleteMessage(message.id);
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
    // 第一优先级：撤回拦截 (直接渲染系统提示)
    if (message.isRecalled) {
      return _buildRecalledSystemTip();
    }
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
                    Flexible(child: _buildContentFactory(context, ref, isMe)),
                  ],
                ),

                // C. "Read" 已读状态 (仅我方显示)
                if (isMe && showReadStatus)
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

  // =======================================================
  //  撤回系统提示气泡
  // =======================================================
  Widget _buildRecalledSystemTip() {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          // Messenger 风格通常是透明背景搭配细边框，或者仅斜体文字
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
        ),
        child: Text(
          message.isMe
              ? "You unsent a message"
              : "${message.senderName ?? 'Someone'} unsent a message",
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[500],
            fontStyle: FontStyle.italic, // 斜体是 Messenger 的标志性设计
          ),
        ),
      ),
    );
  }

  //  内容工厂：根据 type 分发
  Widget _buildContentFactory(BuildContext context, WidgetRef ref, bool isMe) {
    Widget content;

    switch (message.type) {
      case MessageType.image:
        content = _buildImageBubble(context, isMe);
        break;
      case MessageType.audio:
        content = VoiceBubble(message: message, isMe: isMe);
      case MessageType.text:
      default:
        content = _buildTextBubble(context, isMe);
        break;
    }

    return GestureDetector(
      onLongPress: () => _showContextMenu(context, ref, isMe),
      child: content,
    );
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
  //  图片气泡 (Web/Mobile 全兼容 + Hero 动画版)
  // =======================================================
  Widget _buildImageBubble(BuildContext context, bool isMe) {
    final double bubbleSize = 0.60.sw;
    final double dpr = MediaQuery.of(context).devicePixelRatio;
    final int cacheW = (bubbleSize * dpr).toInt();

    // 1.  关键：优先从内存缓存中查找路径
    final String? sessionPath = ChatRoomController.getPathFromCache(message.id);
    // 2. 优先级排序：内存路径 (Session) > 数据库路径 (LocalPath) > 远程 URL (Content)
    final String? activeLocalPath = sessionPath ?? message.localPath;
    final bool canTryLocal =
        activeLocalPath != null && activeLocalPath.isNotEmpty;

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
        enablePreview: true,
        // 开启内部预览
        //  关键：传入 Hero Tag，确保网络图也有动画
        heroTag: message.id,
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
            //  核心渲染逻辑
            // ==========================================
            if (canTryLocal)
              _buildLocalImage(
                context: context,
                path: activeLocalPath,
                width: bubbleSize,
                height: bubbleSize,
                cacheW: cacheW,
                fallback: buildNetworkImage, // 传进去当兜底
              )
            else
              buildNetworkImage(),

            // ==========================================
            //  发送中 Loading
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
            // 时间戳
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

  //  本地图片构建器 (修复版：自动纠错)
  Widget _buildLocalImage({
    required BuildContext context,
    required String path,
    required double width,
    required double height,
    required int cacheW,
    required Widget Function() fallback,
  }) {
    // 1. 构建基础图片组件
    Widget imageWidget;

    if (kIsWeb) {
      imageWidget = Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) {
          debugPrint(" [Web] Blob 加载失败: $error");
          return fallback();
        },
      );
    } else {
      imageWidget = Image.file(
        File(path),
        width: width,
        height: height,
        fit: BoxFit.cover,
        cacheWidth: cacheW,
        gaplessPlayback: true,
        key: ValueKey("${message.id}_local"),
        errorBuilder: (context, error, stack) {
          // 列表页加载失败时，自动降级显示网络图
          return fallback();
        },
      );
    }

    // 2.  核心修复：点击时智能判断
    return GestureDetector(
      onTap: () {
        // 默认使用传入的 path
        String finalSource = path;

        // 2. Web 端特判修复 (Blob 失效问题)
        if (kIsWeb) {
          // 如果消息发送成功且有 CDN 链接，强制使用 CDN
          // 因为 Blob URL 刷新页面后就打不开了
          if (message.status == MessageStatus.success && message.content.isNotEmpty) {
            finalSource = message.content;
          }
        }
        // 3. App 端特判修复 (本地文件丢失问题)
        else {
          final file = File(path);
          // 如果本地文件不存在 (被清理了或路径变了)，降级使用 CDN
          if (!file.existsSync()) {
            // 确保 CDN 链接不为空
            if (message.content.isNotEmpty) {
              finalSource = message.content;
            }
          }
        }

        // 4. 安全检查：如果最终没有任何可用的链接，拦截跳转
        if (finalSource.isEmpty) {
          debugPrint("❌ 无法预览：本地文件不存在且没有 CDN 链接");
          return;
        }

        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => PhotoPreviewPage(
              heroTag: message.id,
              imageSource: finalSource,
              thumbnailSource: finalSource,
            ),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: Hero(
        tag: message.id,
        transitionOnUserGestures: true,
        child: imageWidget,
      ),
    );
  }

  // -------------------------------------------------------
  // 辅助组件
  // -------------------------------------------------------

  Widget _buildStatusPrefix() {
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
