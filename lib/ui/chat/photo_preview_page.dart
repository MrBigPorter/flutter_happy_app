import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../utils/asset/image_provider_utils.dart';

// ✅ CHANGED: 引入统一路径判断工具
import 'package:flutter_app/utils/media/media_path.dart';

class PhotoPreviewPage extends StatelessWidget {
  final String heroTag;
  final String imageSource;          // 高清大图地址（原始 source：可能是 /uploads 或本地路径）
  final String? cachedThumbnailUrl;  // 列表页的缩略图（尽量传 CDN url）
  final Uint8List? previewBytes;     // 上传时的内存图（最快）
  final Map<String, dynamic>? metadata;

  static final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);

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

  //  CHANGED: 高清 Provider：先用 MediaPath 分流，保证本地不走网络 provider
  ImageProvider _getHighResProvider(BuildContext context, String source) {
    final src = source.trim(); //  CHANGED: trim，避免路径判断失效

    final type = MediaPath.classify(src); //  CHANGED

    // 1) blob
    if (type == MediaPathType.blob) return NetworkImage(src);

    // 2) assets（如果你预览页可能传 assets）
    if (type == MediaPathType.asset) return AssetImage(src); // CHANGED

    // 3) 本地文件（localAbs / fileUri）→ 强制走 FileImageProvider（不依赖 tryBuild...）
    if (type == MediaPathType.localAbs || type == MediaPathType.fileUri) {
      final fileProvider = tryBuildFileImageProvider(src);
      if (fileProvider != null) return fileProvider;

      //  CHANGED: tryBuild 兜底失败时，宁可返回 Memory/占位，也不要走网络 provider
      // 这里用透明占位，避免抛异常；你也可以改成返回一个默认图
      return MemoryImage(_kTransparentImage); //  CHANGED: 图标占位由 loading/errorBuilder 来画
    }



    // 4) 网络图片：uploads/http/cdn-cgi 都统一走 UrlResolver
    final finalUrl = UrlResolver.resolveImage(
      context,
      src,
      logicalWidth: 1080,
      quality: 85,
      // format: kIsWeb ? 'auto' : 'webp',
    );

    return CachedNetworkImageProvider(
      finalUrl,
      headers: _imgHeaders,
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

    // 2) 缩略图（强烈建议传进来的是“列表页实际加载的 CDN url”）
    if (cachedThumbnailUrl != null && cachedThumbnailUrl!.isNotEmpty) {
      final thumb = cachedThumbnailUrl!.trim(); // ✅ CHANGED: trim
      final thumbType = MediaPath.classify(thumb); // ✅ CHANGED

      // ✅ CHANGED: 如果传进来的是本地路径，别用 CachedNetworkImageProvider
      if (thumbType == MediaPathType.localAbs || thumbType == MediaPathType.fileUri) {
        final fileProvider = tryBuildFileImageProvider(thumb);
        if (fileProvider != null) {
          return Image(image: fileProvider, fit: BoxFit.contain, gaplessPlayback: true);
        }
        return Container(color: Colors.black);
      }

      return Image(
        image: CachedNetworkImageProvider(
          thumb,
          headers: _imgHeaders,
        ),
        fit: BoxFit.contain,
        gaplessPlayback: true,
      );
    }

    // 3) 兜底
    return Container(color: Colors.black);
  }
}