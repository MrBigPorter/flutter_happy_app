import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_view/photo_view.dart'; // 🔥 修正引入
import 'package:flutter_blurhash/flutter_blurhash.dart'; // 🔥 修正渲染库
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/image_url.dart';

class PhotoPreviewPage extends StatelessWidget {
  final String heroTag;
  final String imageSource;
  final String? cachedThumbnailUrl;
  final Uint8List? previewBytes;
  final Map<String, dynamic>? metadata;

  const PhotoPreviewPage({
    super.key,
    required this.heroTag,
    required this.imageSource,
    this.cachedThumbnailUrl,
    this.previewBytes,
    this.metadata,
  });

  // ✅ 确保这个私有方法在类内部
  ImageProvider _getHighResProvider(BuildContext context, String source) {
    final String finalPath = ImageUrl.build(
        context,
        source,
        logicalWidth: 1080,
        quality: 85
    );

    if (finalPath.startsWith('blob:')) {
      return NetworkImage(finalPath);
    }
    if (!kIsWeb && (finalPath.startsWith('/') || finalPath.startsWith('file://'))) {
      return FileImage(File(finalPath.replaceFirst('file://', '')));
    }
    return CachedNetworkImageProvider(finalPath);
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider originalProvider = _getHighResProvider(context, imageSource);
    final double metaW = (metadata?['w'] ?? metadata?['width'] ?? 100).toDouble();
    final double metaH = (metadata?['h'] ?? metadata?['height'] ?? 100).toDouble();
    final double aspectRatio = metaW / metaH;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: PhotoView(
              imageProvider: originalProvider,
              heroAttributes: PhotoViewHeroAttributes(tag: heroTag),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2.5,
              gaplessPlayback: true,
              loadingBuilder: (context, event) {
                return Center(
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Stack(
                      children: [
                        // 1. BlurHash 占位 (注意参数名是 blurHash)
                        if (metadata?['blurHash'] != null)
                          BlurHash(
                            hash: metadata!['blurHash'],
                            imageFit: BoxFit.contain,
                          ),
                        // 2. 内存缩略图
                        if (cachedThumbnailUrl != null)
                          CachedNetworkImage(
                            imageUrl: cachedThumbnailUrl!,
                            fit: BoxFit.contain,
                          ),
                        // 3. 菊花
                        const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
}