import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../models/chat_ui_model.dart';
import '../../../img/app_image.dart';
import '../../photo_preview_page.dart';
import '../../../../utils/image_url.dart';

class ImageMsgBubble extends StatelessWidget {
  final ChatUiModel message;

  const ImageMsgBubble({super.key, required this.message});

  int _getCacheWidth(BuildContext context, double widgetWidth) {
    final double dpr = MediaQuery.of(context).devicePixelRatio;
    return (widgetWidth * dpr).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final double bubbleSize = 0.60.sw;
    final int cacheW = _getCacheWidth(context, bubbleSize);
    final timeStr = DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(message.createdAt),
    );

    // 1. 获取有效路径
    final String? readyPath = message.resolvedPath ??
        (message.localPath != null && (message.localPath!.startsWith('/') || message.localPath!.startsWith('blob:'))
            ? message.localPath
            : null) ??
        (message.content != '[Image]' ? message.content : null);

    // AppCachedImage 默认 format 是 'webp'
    // ImageUrl.build 默认 format 是 'auto'
    // 这里必须强制指定 format: 'webp'，否则生成的 URL 会变成 f=auto，导致无法命中列表页的缓存！
    final String? currentBubbleUrl = (readyPath != null)
        ? ImageUrl.build(
      context,
      readyPath,
      logicalWidth: bubbleSize,
      logicalHeight: bubbleSize,
      fit: BoxFit.cover,
      quality: 50,
    )
        : null;

    return RepaintBoundary(
      child: Hero(
        tag: message.id,
        child: GestureDetector(
          onTap: () => _openPreview(context, readyPath, currentBubbleUrl),
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
                fit: StackFit.expand,
                children: [
                  // Layer 1: 内存微缩图
                  if (message.previewBytes != null && message.previewBytes!.isNotEmpty)
                    Image.memory(
                      message.previewBytes!,
                      width: bubbleSize, height: bubbleSize,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      cacheWidth: cacheW,
                    ),

                  // Layer 2: 高清图层
                  if (readyPath != null)
                    _buildHighResImage(readyPath, bubbleSize, cacheW),

                  // Layer 3: Loading
                  if (message.status == MessageStatus.sending)
                    Container(
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      ),
                    ),

                  // Layer 4: Time
                  Positioned(
                    right: 6.w, bottom: 6.h,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(10.r)),
                      child: Text(timeStr, style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighResImage(String path, double size, int cacheW) {
    final isLocalFile = !kIsWeb && (path.startsWith('/') || path.startsWith('file://'));

    if (isLocalFile) {
      final file = File(path.replaceFirst('file://', ''));
      if (file.existsSync()) {
        return Image.file(file, width: size, height: size, fit: BoxFit.cover, cacheWidth: cacheW, gaplessPlayback: true, errorBuilder: (_, __, ___) => const SizedBox.shrink());
      }
    }

    // AppCachedImage 内部默认就是 format: 'webp'，所以这里不用动
    return AppCachedImage(
      path,
      width: size, height: size, fit: BoxFit.cover,
      quality: 50,
      enablePreview: false,
    );
  }

  void _openPreview(BuildContext context, String? imageSource, String? cachedUrl) {
    if (imageSource == null || imageSource.isEmpty) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => PhotoPreviewPage(
          heroTag: message.id,
          imageSource: imageSource,
          cachedThumbnailUrl: cachedUrl,
          previewBytes: message.previewBytes,
        ),
      ),
    );
  }
}