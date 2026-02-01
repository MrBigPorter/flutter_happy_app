import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/utils/url_resolver.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../utils/asset/image_provider_utils.dart';

class PhotoPreviewPage extends StatelessWidget {
  final String heroTag;
  final String imageSource;          // 高清大图地址（原始 source：可能是 /uploads）
  final String? cachedThumbnailUrl;  //  列表页的缩略图（必须尽量传 CDN url）
  final Uint8List? previewBytes;     // 上传时的内存图（最快）
  final Map<String, dynamic>? metadata;

  const PhotoPreviewPage({
    super.key,
    required this.heroTag,
    required this.imageSource,
    this.cachedThumbnailUrl,
    this.previewBytes,
    this.metadata,
  });

  // CHANGED: 统一 headers（让 iOS/Android 不再是 Dart UA）
  static final Map<String, String> _imgHeaders = buildImgHeaders();

  // CHANGED: 高清 Provider：统一走 ImageUrl.build，且传 headers
  ImageProvider _getHighResProvider(BuildContext context, String source) {
    // blob: 直接 NetworkImage
    if (source.startsWith('blob:')) return NetworkImage(source);

    // 本地文件（Web 下这个函数会返回 null）
    final fileProvider = tryBuildFileImageProvider(source);
    if (fileProvider != null) return fileProvider;

    // CHANGED: 网络图片：无论 source 是 uploads 还是 cdn-cgi，都统一用 ImageUrl.build 再包一次
    // 这样保证：移动端会强制 f=webp；Web 用 auto
    final finalUrl = UrlResolver.resolveImage(
      context,
      source,
      logicalWidth: 1080,
      quality: 85,
      // 如果你的 ImageUrl.build 支持 format 参数，建议也传：
      // format: kIsWeb ? 'auto' : 'webp',
    );

    return CachedNetworkImageProvider(
      finalUrl,
      headers: _imgHeaders, // CHANGED
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: PhotoView(
              imageProvider: _getHighResProvider(context, imageSource),
              heroAttributes: PhotoViewHeroAttributes(tag: heroTag),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2.5,
              gaplessPlayback: true,

              loadingBuilder: (_, __) => _buildLowResPlaceholder(),
              errorBuilder: (_, __, ___) => _buildLowResPlaceholder(),
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

  Widget _buildLowResPlaceholder() {
    // 1) 内存图最快
    if (previewBytes != null && previewBytes!.isNotEmpty) {
      return Image.memory(
        previewBytes!,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      );
    }

    // 2) CHANGED: 缩略图（强烈建议传进来的是“列表页实际加载的 CDN url”）
    if (cachedThumbnailUrl != null && cachedThumbnailUrl!.isNotEmpty) {
      return Image(
        image: CachedNetworkImageProvider(
          cachedThumbnailUrl!,
          headers: _imgHeaders, // CHANGED：同样传 headers
        ),
        fit: BoxFit.contain,
        gaplessPlayback: true,
      );
    }

    // 3) 兜底
    return Container(color: Colors.black);
  }
}