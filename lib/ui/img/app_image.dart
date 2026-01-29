import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  });

  @override
  Widget build(BuildContext context) {
    if (src is Uint8List) {
      return _wrapper(
        Image.memory(
          src as Uint8List,
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
        ),
        context,
        null,
        null,
        null,
      );
    }

    final String path = src?.toString() ?? '';
    if (path.isEmpty || path == '[Image]') return _ph(width, height);

    // 判定逻辑
    final isBlob = path.startsWith('blob:');
    final isLocal = path.startsWith('/') || path.startsWith('file://');
    final isAsset = path.startsWith('assets/');
    final isRemote =
        !isBlob && !isLocal && !isAsset && !path.contains('localhost');

    final dpr = MediaQuery.of(context).devicePixelRatio;
    final int? memW = cacheWidth != null
        ? (cacheWidth! * dpr).round()
        : (width != null && width!.isFinite ? (width! * dpr).round() : null);
    final int? memH = cacheHeight != null
        ? (cacheHeight! * dpr).round()
        : (height != null && height!.isFinite ? (height! * dpr).round() : null);

    // 1. 远程图片 (走 ImageUrl 加工)
    if (isRemote) {
      final url = ImageUrl.build(
        context,
        path,
        logicalWidth: cacheWidth ?? width,
        logicalHeight: cacheHeight ?? height,
        fit: fit,
        quality: quality,
        format: format,
      );
      return _wrapper(
        CachedNetworkImage(
          imageUrl: url,
          width: width,
          height: height,
          fit: fit,
          memCacheWidth: memW,
          memCacheHeight: memH,
          fadeOutDuration: Duration.zero,
          fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 200),
          placeholder: (context, url) =>
              placeholder ??
              (previewBytes != null
                  ? Image.memory(
                      previewBytes!,
                      width: width,
                      height: height,
                      fit: fit,
                      gaplessPlayback: true,
                    )
                  : _buildShimmer(width, height)),
          errorWidget: (_, __, ___) => error ?? _err(width, height),
        ),
        context,
        url,
        memW,
        memH,
      );
    }

    // 2. 本地/Blob 图片
    Widget localImg = isBlob
        ? Image.network(
            path,
            width: width,
            height: height,
            fit: fit,
            gaplessPlayback: true,
          )
        : (isAsset
              ? Image.asset(
                  path,
                  width: width,
                  height: height,
                  fit: fit,
                  cacheWidth: memW,
                  gaplessPlayback: true,
                )
              : Image.file(
                  File(path.replaceFirst('file://', '')),
                  width: width,
                  height: height,
                  fit: fit,
                  cacheWidth: memW,
                  gaplessPlayback: true,
                ));

    return _wrapper(localImg, context, path, memW, memH);
  }

  Widget _wrapper(
    Widget child,
    BuildContext context,
    String? currentUrl,
    int? memW,
    int? memH,
  ) {
    Widget res = child;
    if (radius != null) res = ClipRRect(borderRadius: radius!, child: res);
    if (heroTag != null && heroTag!.isNotEmpty)
      res = Hero(tag: heroTag!, child: res);

    if (enablePreview && src != null) {
      res = GestureDetector(
        onTap: () => Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => PhotoPreviewPage(
              heroTag: heroTag ?? src.toString(),
              imageSource: src.toString(),
              //  修复点：这里改用 cachedThumbnailUrl，匹配 PhotoPreviewPage 的定义
              cachedThumbnailUrl: currentUrl,
              previewBytes: previewBytes,
              memW: memW,
              memH: memH,
            ),
          ),
        ),
        child: res,
      );
    }
    return res;
  }

  Widget _buildShimmer(double? w, double? h) => Shimmer.fromColors(
    baseColor: placeholderColor,
    highlightColor: Colors.white.withOpacity(0.5),
    child: Container(width: w, height: h, color: Colors.white),
  );

  Widget _ph(double? w, double? h) => Container(
    width: w,
    height: h,
    color: placeholderColor,
    child: const Icon(Icons.image, color: Colors.grey, size: 20),
  );

  Widget _err(double? w, double? h) => Container(
    width: w,
    height: h,
    color: placeholderColor,
    child: const Icon(Icons.broken_image, color: Colors.grey, size: 24),
  );
}
