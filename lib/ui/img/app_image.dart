import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:shimmer/shimmer.dart';

// 引入你的路径判断工具 (确保这两个文件存在)
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_app/utils/media/media_path.dart';
import 'package:flutter_app/ui/chat/photo_preview_page.dart';

class AppCachedImage extends StatelessWidget {
  final dynamic src; // 支持 String (路径/URL) 或 Uint8List (内存流)
  final double? width, height;
  final BoxFit fit;
  final BorderRadius? radius;
  final String? heroTag;
  final Color placeholderColor;
  final Widget? placeholder, error;
  final bool enablePreview;
  final Duration? fadeInDuration;

  // 核心无缝切换参数
  final Uint8List? previewBytes;
  // 元数据 (BlurHash)
  final Map<String, dynamic>? metadata;

  const AppCachedImage(
      this.src, {
        super.key,
        this.width,
        this.height,
        this.fit = BoxFit.cover,
        this.radius,
        this.placeholderColor = const Color(0xFFF5F5F5),
        this.placeholder,
        this.error,
        this.enablePreview = false,
        this.heroTag,
        this.fadeInDuration,
        this.previewBytes,
        this.metadata,
      });

  @override
  Widget build(BuildContext context) {
    // 0. 宽高比优化
    double? aspectRatio;
    if (metadata != null) {
      final double metaW = (metadata!['w'] ?? metadata!['width'] ?? 0).toDouble();
      final double metaH = (metadata!['h'] ?? metadata!['height'] ?? 0).toDouble();
      if (metaW > 0 && metaH > 0) {
        aspectRatio = metaW / metaH;
      }
    }

    Widget mainWidget = _buildContent(context);

    // 只有在定宽不定高的情况下，才强制使用 AspectRatio
    if (aspectRatio != null && height == null && width != null) {
      mainWidget = AspectRatio(aspectRatio: aspectRatio, child: mainWidget);
    }

    return _wrapper(context, mainWidget);
  }

  Widget _buildContent(BuildContext context) {
    // 1. 内存流 (最快)
    if (src is Uint8List) {
      return Image.memory(src as Uint8List, width: width, height: height, fit: fit, gaplessPlayback: true);
    }

    final String path = (src?.toString() ?? '').trim();

    // 2. 空路径
    if (path.isEmpty || path == '[Image]') {
      return _buildFallback();
    }

    // 3. 路径分类处理
    final type = MediaPath.classify(path);

    switch (type) {
      case MediaPathType.blob: // Web 专用
        return Image.network(path, width: width, height: height, fit: fit);

      case MediaPathType.asset:
        return Image.asset(path, width: width, height: height, fit: fit);

      case MediaPathType.fileUri:
      case MediaPathType.localAbs:
      // 本地文件检测 + 自动降级
        if (kIsWeb) return _buildNetworkImage(context, path);

        File file;
        try {
          if (path.startsWith('file://')) {
            file = File(Uri.parse(path).toFilePath());
          } else {
            file = File(path);
          }

          if (file.existsSync()) {
            return Image.file(file, width: width, height: height, fit: fit, gaplessPlayback: true);
          } else {
            // 本地丢了，尝试网络
            debugPrint("⚠️ Local file missing: $path, attempting network fallback...");
            return _buildNetworkImage(context, path);
          }
        } catch (e) {
          return _buildNetworkImage(context, path);
        }

      case MediaPathType.http:
      case MediaPathType.uploads:
      case MediaPathType.relative:
      default:
        return _buildNetworkImage(context, path);
    }
  }

  Widget _buildNetworkImage(BuildContext context, String path) {
    final url = UrlResolver.resolveImage(
      context,
      path,
      logicalWidth: width,
      fit: fit,
    );

    if (url.isEmpty) return _buildFallback();

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _buildFallback(isPlaceholder: true),
      errorWidget: (context, url, error) => _buildFallback(),
      fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 200),
    );
  }

  Widget _buildFallback({bool isPlaceholder = false}) {
    if (previewBytes != null && previewBytes!.isNotEmpty) {
      return Image.memory(previewBytes!, width: width, height: height, fit: fit, gaplessPlayback: true);
    }

    final String? hash = metadata?['blurHash'] ?? metadata?['blur_hash'];
    if (hash != null && hash.isNotEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: BlurHash(hash: hash, imageFit: fit, color: placeholderColor),
      );
    }

    if (isPlaceholder) {
      return Shimmer.fromColors(
        baseColor: placeholderColor,
        highlightColor: Colors.white.withOpacity(0.5),
        child: Container(width: width, height: height, color: Colors.white),
      );
    }

    if (error != null) return error!;
    return Container(
      width: width,
      height: height,
      color: placeholderColor,
      child: const Icon(Icons.broken_image, color: Colors.grey, size: 24),
    );
  }

  Widget _wrapper(BuildContext context, Widget child) {
    Widget res = child;
    if (radius != null) res = ClipRRect(borderRadius: radius!, child: res);
    if (heroTag != null) res = Hero(tag: heroTag!, child: res);

    if (enablePreview) {
      res = GestureDetector(
        onTap: () {
          if (src != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) =>
                PhotoPreviewPage(
                  heroTag: heroTag ?? src.toString(),
                  imageSource: src.toString(),
                  previewBytes: previewBytes,
                  metadata: metadata,
                )
            ));
          }
        },
        child: res,
      );
    }
    return res;
  }
}