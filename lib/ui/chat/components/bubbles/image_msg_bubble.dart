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

  @override
  Widget build(BuildContext context) {
    // 1. 提取元数据 (w, h, blurHash)
    final Map<String, dynamic> meta = message.meta ?? {};

    // 2. 气泡基础宽度 (固定 0.6sw，但比例由 metadata 决定)
    final double baseWidth = 0.60.sw;

    // 3. 时间字符串
    final timeStr = DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(message.createdAt),
    );

    // 4. 统一路径获取
    final String? readyPath = message.resolvedPath ?? message.localPath ??
        (message.content != '[Image]' ? message.content : null);

    // 5. 生成用于预览图对比的 URL (必须与 AppCachedImage 内部生成逻辑完全一致)
    final String? currentBubbleUrl = (readyPath != null)
        ? ImageUrl.build(
      context,
      readyPath,
      logicalWidth: baseWidth,
      logicalHeight: baseWidth, // 这里虽然传了宽，但 AppCachedImage 内部会按比例处理
      fit: BoxFit.cover,
      quality: 50,
    )
        : null;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => _openPreview(context, readyPath, currentBubbleUrl),
        child: Container(
          width: baseWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          // 使用 ClipRRect 确保内容不溢出圆角
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Stack(
              children: [
                //  核心改变：所有的“阶梯渲染”逻辑全部交给 AppCachedImage
                // 它会自动处理：BlurHash -> previewBytes -> 高清图
                AppCachedImage(
                  readyPath,
                  width: baseWidth, // 宽度固定
                  // 这里的 height 传 null，让 AppCachedImage 根据 metadata 里的 aspectRatio 自动算高度
                  metadata: meta,
                  previewBytes: message.previewBytes,
                  heroTag: message.id, // Hero 逻辑也收拢进去
                  enablePreview: false, // 我们手动处理跳转
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
          metadata: message.meta, //  架构师补强：透传元数据给预览页
        ),
      ),
    );
  }
}