import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:shimmer/shimmer.dart';

// 核心引入：使用我们之前封装的资产管理器
import 'package:flutter_app/utils/asset/asset_manager.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_app/ui/chat/photo_preview_page.dart';

class AppCachedImage extends StatelessWidget {
  final dynamic src;
  final double? width, height;
  final BoxFit fit;
  final BorderRadius? radius;
  final String? heroTag;
  final Color placeholderColor;
  final Widget? placeholder, error;
  final bool enablePreview;
  final Duration? fadeInDuration;
  final Uint8List? previewBytes;
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
    // 1. 处理宽高比（防止列表抖动）
    Widget mainWidget = _buildContent(context);

    if (metadata != null && height == null && width != null) {
      final double w = (metadata!['w'] ?? metadata!['width'] ?? 0).toDouble();
      final double h = (metadata!['h'] ?? metadata!['height'] ?? 0).toDouble();
      if (w > 0 && h > 0) {
        mainWidget = AspectRatio(aspectRatio: w / h, child: mainWidget);
      }
    }

    return _wrapper(context, mainWidget);
  }

  Widget _buildContent(BuildContext context) {
    // 1. 内存流优先（最快，通常是发送瞬间的预览）
    if (src is Uint8List) {
      return Image.memory(src, width: width, height: height, fit: fit, gaplessPlayback: true);
    }

    final String path = (src?.toString() ?? '').trim();
    if (path.isEmpty || path == '[Image]') return _buildFallback();

    //  [核心重构]：利用 AssetManager 统一还原路径
    // 它会自动处理：相对路径还原、file:// 转换、物理存在检查
    if (!kIsWeb && AssetManager.existsSync(path)) {
      final String fullPath = AssetManager.getRuntimePath(path);
      return Image.file(
        File(fullPath),
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _buildNetworkImage(context, path), // 万一 IO 错误，降级网络
      );
    }

    // 2. Web Blob 处理
    if (kIsWeb && path.startsWith('blob:')) {
      return Image.network(path, width: width, height: height, fit: fit);
    }

    // 3. 资源文件处理
    if (path.startsWith('assets/')) {
      return Image.asset(path, width: width, height: height, fit: fit);
    }

    // 4. 其余情况：一律视为网络图或需要拼接域名的路径
    return _buildNetworkImage(context, path);
  }

  Widget _buildNetworkImage(BuildContext context, String path) {
    final url = UrlResolver.resolveImage(context, path, logicalWidth: width, fit: fit);
    if (url.isEmpty) return _buildFallback();

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      //  优化：占位符优先使用内存预览图或 BlurHash
      placeholder: (context, url) => _buildFallback(isPlaceholder: true),
      errorWidget: (context, url, err) => _buildFallback(),
      fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 200),
    );
  }

  Widget _buildFallback({bool isPlaceholder = false}) {
    // 1. 第一优先级：数据库里存的预览字节流
    if (previewBytes != null && previewBytes!.isNotEmpty) {
      return Image.memory(previewBytes!, width: width, height: height, fit: fit, gaplessPlayback: true);
    }

    // 2. 第二优先级：BlurHash
    final String? hash = metadata?['blurHash'] ?? metadata?['blur_hash'];
    if (hash != null && hash.isNotEmpty) {
      return BlurHash(hash: hash, imageFit: fit, color: placeholderColor);
    }

    // 3. 第三优先级：骨架屏或纯色
    if (isPlaceholder) {
      return Shimmer.fromColors(
        baseColor: placeholderColor,
        highlightColor: Colors.white.withOpacity(0.5),
        child: Container(width: width, height: height, color: Colors.white),
      );
    }

    return error ?? Container(
      width: width, height: height, color: placeholderColor,
      child: const Icon(Icons.broken_image, color: Colors.grey, size: 24),
    );
  }

  Widget _wrapper(BuildContext context, Widget child) {
    Widget res = child;
    if (radius != null) res = ClipRRect(borderRadius: radius!, child: res);
    if (heroTag != null) res = Hero(tag: heroTag!, child: res, transitionOnUserGestures: true);

    if (enablePreview && src != null) {
      res = GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
            PhotoPreviewPage(
              heroTag: heroTag ?? src.toString(),
              imageSource: src.toString(),
              previewBytes: previewBytes,
              metadata: metadata,
            )
        )),
        child: res,
      );
    }
    return res;
  }
}