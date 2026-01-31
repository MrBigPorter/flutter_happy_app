import 'dart:io';
import 'package:flutter/foundation.dart';
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

  @override
  Widget build(BuildContext context) {
    // 1. 提取元数据
    final Map<String, dynamic> meta = message.meta ?? {};

    // 2. 气泡基础宽度
    final double baseWidth = 0.60.sw;

    // 3. 时间字符串
    final timeStr = DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(message.createdAt),
    );

    // 4. 统一路径获取
    final String? readyPath = message.resolvedPath ?? message.localPath ??
        (message.content != '[Image]' ? message.content : null);

    return RepaintBoundary(
      child: GestureDetector(
        //  传参优化
        onTap: () => _openPreview(context, readyPath, baseWidth),
        child: Container(
          width: baseWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Stack(
              children: [
                // AppCachedImage 内部会自动调用 ImageUrl.build 生成 CDN 链接
                AppCachedImage(
                  readyPath,
                  width: baseWidth,
                  // 这里的 quality 默认是 50，记住这个参数，下面要对齐
                  quality: 50,
                  metadata: meta,
                  previewBytes: message.previewBytes,
                  heroTag: message.id,
                  enablePreview: false,
                  fit: BoxFit.cover,
                ),

                // 发送中遮罩
                if (message.status == MessageStatus.sending)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                    ),
                  ),

                // 时间戳
                Positioned(
                  right: 6.w, bottom: 6.h,
                  child: _buildTimeTag(timeStr),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeTag(String time) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        time,
        style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _openPreview(BuildContext context, String? imageSource, double bubbleWidth) {
    if (imageSource == null || imageSource.isEmpty) return;

    //  核心修正：必须与 AppCachedImage 的默认参数完全对齐！
    // 1. AppCachedImage 默认 quality = 50
    // 2. AppCachedImage 默认 format = kIsWeb ? 'auto' : 'webp'
    final String thumbUrl = ImageUrl.build(
      context,
      imageSource,
      logicalWidth: bubbleWidth,
      quality: 50,                // 必须对齐
      fit: BoxFit.cover,          // 必须对齐
      format: kIsWeb ? 'auto' : 'webp', //  必须对齐！之前这里漏了，导致 URL 不一致
    );

    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => PhotoPreviewPage(
          heroTag: message.id,
          imageSource: imageSource,
          cachedThumbnailUrl: thumbUrl, // 现在这个 URL 和列表页的一模一样了
          previewBytes: message.previewBytes,
          metadata: message.meta,
        ),
      ),
    );
  }
}