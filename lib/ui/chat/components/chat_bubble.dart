import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/ui/chat/components/voice_bubble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data'; // 必须加这一行，解决 Uint8List 报错

import 'package:flutter_app/ui/img/app_image.dart';
import '../models/chat_ui_model.dart';
import '../photo_preview_page.dart';
import '../providers/chat_room_provider.dart';

class ChatBubble extends ConsumerWidget {
  final ChatUiModel message;
  final VoidCallback? onRetry;
  final bool showReadStatus;

  const ChatBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.showReadStatus = false,
  });

  void _showContextMenu(BuildContext context, WidgetRef ref, bool isMe) {
    final bool isText = message.type == MessageType.text;
    // Allow recall within 2 minutes
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
                ref
                    .read(chatControllerProvider(message.conversationId))
                    .recallMessage(message.id);
              },
              child: const Text("Unsend for Everyone"),
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
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
    if (message.isRecalled) return _buildRecalledSystemTip();

    final isMe = message.isMe;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _buildAvatar(message.senderAvatar),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isMe) _buildStatusPrefix(),
                    Flexible(child: _buildContentFactory(context, ref, isMe)),
                  ],
                ),
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
          if (isMe) ...[SizedBox(width: 8.w), _buildAvatar(null)],
        ],
      ),
    );
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
          message.isMe
              ? "You unsent a message"
              : "${message.senderName ?? 'Someone'} unsent a message",
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildContentFactory(BuildContext context, WidgetRef ref, bool isMe) {
    Widget content;
    switch (message.type) {
      case MessageType.image:
        content = _buildImageBubble(context, isMe);
        break;
      case MessageType.audio:
        content = VoiceBubble(message: message, isMe: isMe);
        break;
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

  // ---  Core Architecture: Tiered Image Rendering Pipeline ---
  Widget _buildImageBubble(BuildContext context, bool isMe) {
    final double bubbleSize = 0.60.sw;
    final double dpr = MediaQuery.of(context).devicePixelRatio;
    final int cacheW = (bubbleSize * dpr).toInt();
    final timeStr = DateFormat(
      'HH:mm',
    ).format(DateTime.fromMillisecondsSinceEpoch(message.createdAt));

    // L1: Memory Cache (Zero Jitter for sending state)
    final String? sessionPath = ChatRoomController.getPathFromCache(message.id);

    // Use FutureBuilder to dynamically resolve absolute path on iOS
    return FutureBuilder<Directory>(
      future: getApplicationDocumentsDirectory(),
      builder: (context, snapshot) {
        // 1. Path Reconstruction: Combine sandbox root with relative filename
        String? activeLocalPath = sessionPath;
        if (activeLocalPath == null &&
            snapshot.hasData &&
            message.localPath != null) {
          activeLocalPath = p.join(
            snapshot.data!.path,
            'chat_images',
            message.localPath!,
          );
        }

        // 2. Physical Validation: Ensure file exists to prevent rendering errors
        final bool hasLocalFile =
            activeLocalPath != null &&
            !kIsWeb &&
            File(activeLocalPath).existsSync();

        // 3. Persistent Preview: Check for tiny thumbnail bytes (Web refresh safety)
        // 使用 length > 0 是最稳的，绝对不会报 getter missing
        final bool hasPreviewBytes = message.previewBytes != null && (message.previewBytes as Uint8List).isNotEmpty;

        // L4: CDN Fallback Widget
        Widget buildNetworkImage() {
          return AppCachedImage(
            message.content,
            width: bubbleSize,
            height: bubbleSize,
            fit: BoxFit.cover,
            enablePreview: true,
            heroTag:
                null, // Fixed: Remove internal Hero to prevent nesting error
          );
        }

        // Fixed: Lift Hero to the top-level container
        return Hero(
          tag: message.id,
          child: Container(
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
                fit: StackFit.expand, // Ensure children fill the container
                children: [
                  // L4: Network Image (Base Layer)
                  buildNetworkImage(),

                  // L2: Persistent Preview Bytes (Visual Placeholder)
                  if (hasPreviewBytes)
                    Image.memory(message.previewBytes! as Uint8List, fit: BoxFit.cover),

                  // L3/L1: High-Res Local File (Physical Source)
                  if (hasLocalFile || (kIsWeb && sessionPath != null))
                    _buildLocalImage(
                      context: context,
                      path: activeLocalPath ?? sessionPath!,
                      width: bubbleSize,
                      height: bubbleSize,
                      cacheW: cacheW,
                      fallback: buildNetworkImage, // Pass fallback correctly
                    ),

                  // Status: Sending Overlay
                  if (message.status == MessageStatus.sending)
                    Container(
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ),

                  // Timestamp
                  Positioned(
                    right: 6.w,
                    bottom: 6.h,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
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
          ),
        );
      },
    );
  }

  Widget _buildLocalImage({
    required BuildContext context,
    required String path,
    required double width,
    required double height,
    required int cacheW,
    required Widget Function() fallback,
  }) {
    Widget imageWidget;
    if (kIsWeb) {
      imageWidget = Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => fallback(),
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
        errorBuilder: (context, error, stack) => fallback(),
      );
    }

    return GestureDetector(
      onTap: () {
        String finalSource = path;

        // Validate source before opening viewer
        if (kIsWeb) {
          if (message.status == MessageStatus.success &&
              message.content.isNotEmpty)
            finalSource = message.content;
        } else {
          // Fallback to CDN if local file is missing (e.g., cleared cache)
          if (!File(path).existsSync() && message.content.isNotEmpty)
            finalSource = message.content;
        }

        if (finalSource.isEmpty) {
          debugPrint(
            "[ChatBubble] Cannot preview: Local file missing and no CDN URL found.",
          );
          return;
        }

        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, animation, __) => PhotoPreviewPage(
              heroTag: message.id,
              imageSource: finalSource,
              thumbnailSource: finalSource,
            ),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: imageWidget,
    );
  }

  Widget _buildStatusPrefix() {
    // Pending: Show Clock Icon (Offline Queue)
    if (message.status == MessageStatus.pending) {
      return Padding(
        padding: EdgeInsets.only(right: 8.w, bottom: 4.h),
        child: Icon(
          Icons.access_time_rounded,
          size: 16.sp,
          color: Colors.grey[400],
        ),
      );
    }

    // Sending: Show Spinner (or hidden for images as they have internal spinners)
    if (message.status == MessageStatus.sending) {
      if (message.type == MessageType.image) return const SizedBox.shrink();
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

    // Failed: Show Red Warning (Tap to Retry)
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
