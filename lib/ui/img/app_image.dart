import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart'; // 渲染库
import 'package:shimmer/shimmer.dart';
import '../chat/photo_preview_page.dart';
import '../../utils/image_url.dart';

class AppCachedImage extends StatelessWidget {
  final dynamic src;
  final double? width, height, cacheWidth, cacheHeight;
  final BoxFit fit;
  final BorderRadius? radius;
  final String? heroTag;
  final int quality;
  final String format;
  final Color placeholderColor;
  final Widget? placeholder, error;
  final bool enablePreview;
  final Duration? fadeInDuration;
  final Uint8List? previewBytes;

  /// 工业级关键：包含 blurHash, w, h 的元数据
  final Map<String, dynamic>? metadata;

  const AppCachedImage(
      this.src, {
        super.key,
        this.width,
        this.height,
        this.cacheWidth,
        this.cacheHeight,
        this.fit = BoxFit.cover,
        this.radius,
        this.quality = 50,
        this.format = 'auto',
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
    // -------------------------------------------------------------------------
    // 1. 布局锁定逻辑 (Anti-Jank)
    // -------------------------------------------------------------------------
    // 优先从 metadata 提取原始比例。即使图片还没下载，AspectRatio 也会强行占坑，防止列表跳动。
    double? aspectRatio;
    if (metadata != null) {
      final double metaW = (metadata!['w'] ?? metadata!['width'] ?? 0).toDouble();
      final double metaH = (metadata!['h'] ?? metadata!['height'] ?? 0).toDouble();
      if (metaW > 0 && metaH > 0) {
        aspectRatio = metaW / metaH;
      }
    }

    Widget mainWidget = _buildContent(context);

    // 如果有比例且外部没有强制给死高度，则应用 AspectRatio
    if (aspectRatio != null && height == null) {
      mainWidget = AspectRatio(aspectRatio: aspectRatio, child: mainWidget);
    }

    return mainWidget;
  }

  Widget _buildContent(BuildContext context) {
    // 处理内存数据
    if (src is Uint8List) {
      return _wrapper(
        context,
        Image.memory(
          src as Uint8List,
          width: width, height: height,
          fit: fit,
          gaplessPlayback: true,
        ),
      );
    }

    final String path = src?.toString() ?? '';
    if (path.isEmpty || path == '[Image]') return _ph(width, height);

    final dpr = MediaQuery.of(context).devicePixelRatio;
    final int? memW = _calcMemSize(cacheWidth ?? width, dpr);
    final int? memH = _calcMemSize(cacheHeight ?? height, dpr);

    // -------------------------------------------------------------------------
    // 2. 平台与类型路由
    // -------------------------------------------------------------------------
    if (kIsWeb) {
      bool isRemote = !path.startsWith('blob:') && !path.startsWith('assets/');
      if (isRemote) return _buildNetworkImage(context, path, memW, memH);
      return _wrapper(context, Image.network(path, width: width, height: height, fit: fit, gaplessPlayback: true));
    }

    final isAsset = path.startsWith('assets/');
    final isFile = path.startsWith('/') || path.startsWith('file://');

    if (!isAsset && !isFile) {
      return _buildNetworkImage(context, path, memW, memH);
    } else if (isAsset) {
      return _wrapper(context, Image.asset(path, width: width, height: height, fit: fit, cacheWidth: memW, gaplessPlayback: true));
    } else {
      File file = path.startsWith('file://') ? File(Uri.parse(path).toFilePath()) : File(path);
      if (!file.existsSync()) return _err(width, height);
      return _wrapper(context, Image.file(file, width: width, height: height, fit: fit, cacheWidth: memW, gaplessPlayback: true));
    }
  }

  Widget _buildNetworkImage(BuildContext context, String path, int? memW, int? memH) {
    final url = ImageUrl.build(
      context, path,
      logicalWidth: cacheWidth ?? width,
      logicalHeight: cacheHeight ?? height,
      fit: fit, quality: quality, format: format,
    );

    final animDuration = fadeInDuration ?? Duration.zero;

    // -------------------------------------------------------------------------
    // 3. 阶梯式占位逻辑 (Laddering Strategy)
    // -------------------------------------------------------------------------
    Widget buildPlaceholder(BuildContext ctx, String url) {
      if (placeholder != null) return placeholder!;

      // 优先级 A: BlurHash (体感最快，颜色匹配)
      final String? hash = metadata?['blurHash'];
      if (hash != null && hash.isNotEmpty) {
        return BlurHash(hash: hash, imageFit: fit, color: placeholderColor);
      }

      // 优先级 B: 二进制预览图 (发送者本地即时显示)
      if (previewBytes != null) {
        return Image.memory(previewBytes!, width: width, height: height, fit: fit, gaplessPlayback: true);
      }

      // 优先级 C: 骨架屏
      return _buildShimmer(width, height);
    }

    return _wrapper(
      context,
      CachedNetworkImage(
        imageUrl: url,
        width: width, height: height,
        fit: fit,
        memCacheWidth: memW,
        memCacheHeight: memH,
        fadeOutDuration: animDuration,
        fadeInDuration: animDuration,
        placeholderFadeInDuration: Duration.zero,
        placeholder: buildPlaceholder,
        errorWidget: (_, __, ___) => error ?? _err(width, height),
      ),
      currentUrl: url,
      memW: memW,
      memH: memH,
    );
  }

  // -------------------------------------------------------------------------
  // 4. 辅助工具
  // -------------------------------------------------------------------------

  Widget _wrapper(BuildContext context, Widget child, {String? currentUrl, int? memW, int? memH}) {
    Widget res = child;
    if (radius != null) res = ClipRRect(borderRadius: radius!, child: res);
    if (heroTag != null && heroTag!.isNotEmpty) res = Hero(tag: heroTag!, child: res);

    if (enablePreview && src != null) {
      res = GestureDetector(
        onTap: () => Navigator.push(context, PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => PhotoPreviewPage(
            heroTag: heroTag ?? src.toString(),
            imageSource: src.toString(),
            cachedThumbnailUrl: currentUrl,
            previewBytes: previewBytes,
            metadata: metadata, // 将元数据透传给预览页，防止预览页布局闪烁
          ),
        )),
        child: res,
      );
    }
    return res;
  }

  int? _calcMemSize(double? size, double dpr) {
    if (size == null || !size.isFinite || size <= 0) return null;
    return (size * dpr).round();
  }

  Widget _buildShimmer(double? w, double? h) => Shimmer.fromColors(
    baseColor: placeholderColor,
    highlightColor: Colors.white.withOpacity(0.5),
    child: Container(width: w, height: h, color: Colors.white),
  );

  Widget _ph(double? w, double? h) => Container(width: w, height: h, color: placeholderColor, child: const Icon(Icons.image, color: Colors.grey, size: 20));

  Widget _err(double? w, double? h) => Container(width: w, height: h, color: placeholderColor, child: const Icon(Icons.broken_image, color: Colors.grey, size: 24));
}