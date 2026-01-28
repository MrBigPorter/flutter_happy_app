import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../models/chat_ui_model.dart';
import '../../../img/app_image.dart';
import '../../photo_preview_page.dart';

class ImageMsgBubble extends StatelessWidget {
  final ChatUiModel message;

  const ImageMsgBubble({super.key, required this.message});

  /// 计算降采样宽度：根据屏占比和DPR计算真实的物理像素需求
  /// (直接复用之前的高效逻辑)
  int _getCacheWidth(BuildContext context, double widgetWidth) {
    final double dpr = MediaQuery.of(context).devicePixelRatio;
    return (widgetWidth * dpr).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final double bubbleSize = 0.60.sw; // 气泡最大宽度
    final int cacheW = _getCacheWidth(context, bubbleSize);
    final timeStr = DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(message.createdAt),
    );

    //  核心：直接获取预热好的路径，不再使用 FutureBuilder
    // 优先级：Service预热路径 > 原始本地路径(兜底) > 消息内容(网络URL)
    final String? readyPath = message.resolvedPath ??
        (message.localPath != null && !message.localPath!.startsWith('assets') ? message.localPath : null) ??
        (message.content.startsWith('http') ? message.content : null);

    return RepaintBoundary( // 性能优化：隔离重绘
      child: Hero(
        tag: message.id,
        child: GestureDetector(
          onTap: () => _openPreview(context, readyPath),
          child: Container(
            width: bubbleSize,
            height: bubbleSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
              color: Colors.grey[50], // 浅灰底色，防止透明图尴尬
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  // ============================================
                  // Layer 1: 内存预览图 (极速响应，0 IO)
                  // ============================================
                  if (message.previewBytes != null && message.previewBytes!.isNotEmpty)
                    Image.memory(
                      message.previewBytes!,
                      width: bubbleSize,
                      height: bubbleSize,
                      fit: BoxFit.cover,
                      gaplessPlayback: true, // 防止闪烁
                      cacheWidth: cacheW,    // 内存降准
                    ),

                  // ============================================
                  // Layer 2: 高清大图 (本地文件 / 网络图)
                  // ============================================
                  if (readyPath != null)
                    _buildHighResImage(readyPath, bubbleSize, cacheW),

                  // ============================================
                  // Layer 3: 发送中遮罩
                  // ============================================
                  if (message.status == MessageStatus.sending)
                    Container(
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      ),
                    ),

                  // ============================================
                  // Layer 4: 时间戳
                  // ============================================
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
                            fontWeight: FontWeight.w500
                        ),
                      ),
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

  /// 构建高清图层 (同步渲染)
  Widget _buildHighResImage(String path, double size, int cacheW) {
    // 1. 网络图片
    if (path.startsWith('http') || path.startsWith('blob:')) {
      return AppCachedImage(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        enablePreview: false, // 已经在气泡外层处理了点击
      );
    }

    // 2. 本地文件 (Service 已经确认过路径有效，直接读)
    final file = File(path);
    if (!kIsWeb && file.existsSync()) {
      return Image.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: cacheW,     // 🔥 关键：内存降准
        gaplessPlayback: true,  // 防止重绘时白屏
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }

    // 3. Web 平台本地路径或其他兜底
    if (kIsWeb) {
      return Image.network(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }

    return const SizedBox.shrink();
  }

  void _openPreview(BuildContext context, String? imageSource) {
    if (imageSource == null || imageSource.isEmpty) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false, // 透明路由，支持 Hero 过渡
        pageBuilder: (_, __, ___) => PhotoPreviewPage(
          heroTag: message.id,
          imageSource: imageSource,
          thumbnailSource: imageSource, // 可以传 previewBytes 做进场动画优化
          previewBytes: message.previewBytes,
        ),
      ),
    );
  }
}