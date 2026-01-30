import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/image_url.dart';

class PhotoPreviewPage extends StatelessWidget {
  final String heroTag;
  final String imageSource;       // 高清大图地址
  final String? cachedThumbnailUrl; // 列表页的缩略图 (通常已有缓存)
  final Uint8List? previewBytes;    // 上传时的内存图 (速度最快)
  final Map<String, dynamic>? metadata;

  const PhotoPreviewPage({
    super.key,
    required this.heroTag,
    required this.imageSource,
    this.cachedThumbnailUrl,
    this.previewBytes,
    this.metadata,
  });

  // 获取高清大图的 Provider
  ImageProvider _getHighResProvider(BuildContext context, String source) {
    if (source.startsWith('blob:')) return NetworkImage(source);

    // 本地文件直接读
    if (!kIsWeb && (source.startsWith('/') || source.startsWith('file://'))) {
      return FileImage(File(source.replaceFirst('file://', '')));
    }

    // 网络图片：构造高清参数 (1080p, q85)
    final String finalPath = ImageUrl.build(
        context, source,
        logicalWidth: 1080, quality: 85
    );
    return CachedNetworkImageProvider(finalPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ==============================
          // 核心图片区域
          // ==============================
          Center(
            child: PhotoView(
              imageProvider: _getHighResProvider(context, imageSource),
              heroAttributes: PhotoViewHeroAttributes(tag: heroTag),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2.5,
              gaplessPlayback: true, // 防止替换图片时闪烁

              //  核心逻辑：渐进式加载 (Progressive Loading)
              // 当高清大图还在下载时，PhotoView 会显示这个 builder 的内容
              loadingBuilder: (context, event) {
                return _buildLowResPlaceholder();
              },

              // 如果高清图加载失败，也显示低清图兜底，至少能看
              errorBuilder: (context, error, stackTrace) {
                return _buildLowResPlaceholder();
              },
            ),
          ),

          // ==============================
          // 关闭按钮
          // ==============================
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLowResPlaceholder() {
    // 1. 优先使用内存图 (Bytes) - 最快
    if (previewBytes != null && previewBytes!.isNotEmpty) {
      return Image.memory(
        previewBytes!,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      );
    }

    // 2. 其次使用缩略图 (URL) - 核心修改
    if (cachedThumbnailUrl != null && cachedThumbnailUrl!.isNotEmpty) {

      //  改用最原始的 Image 组件 + Provider
      // 只要 URL 和列表页的一样，它就会直接从内存/磁盘里拿，0 延迟！
      return Image(
        image: CachedNetworkImageProvider(cachedThumbnailUrl!),
        fit: BoxFit.contain,
        gaplessPlayback: true, // 防止闪烁的关键
      );
    }

    // 3. 兜底
    return Container(color: Colors.black);
  }
}