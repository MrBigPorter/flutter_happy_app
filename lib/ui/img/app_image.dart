import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../utils/image_url.dart';

class AppCachedImage extends StatelessWidget {
  final String? src;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? radius;

  /// 图片优化
  final int quality; // 30~95
  final String format; // auto/webp/avif...
  final bool forceGatewayOnNative;

  /// UI
  final Color placeholderColor;
  final Widget? placeholder;
  final Widget? error;

  const AppCachedImage(
    this.src, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius,
    this.quality = 75,
    this.format = 'auto',
    this.forceGatewayOnNative = false,
    this.placeholderColor = const Color(0x11000000),
    this.placeholder,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final url = ImageUrl.build(
      context,
      src,
      logicalWidth: width,
      logicalHeight: height,
      fit: fit,
      quality: quality,
      format: format,
      forceGatewayOnNative: forceGatewayOnNative,
    );

    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    final memW = (width == null) ? null : (width! * dpr).round();
    final memH = (height == null) ? null : (height! * dpr).round();

    Widget child;
    if (url.isEmpty) {
      child = _ph(width, height);
    } else {
      child = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,

        // 缓存优化（减少内存/磁盘占用）
        memCacheWidth: memW,
        memCacheHeight: memH,
        maxWidthDiskCache: memW,
        maxHeightDiskCache: memH,

        fadeInDuration: const Duration(milliseconds: 150),
        fadeOutDuration: const Duration(milliseconds: 100),

        placeholder: (_, __) => placeholder ?? _ph(width, height),
        errorWidget: (_, __, ___) => error ?? _err(width, height),
      );
    }

    if (radius != null) {
      child = ClipRRect(borderRadius: radius!, child: child);
    }
    return child;
  }

  Widget _ph(double? w, double? h) => Container(
    width: w,
    height: h,
    color: placeholderColor,
    alignment: Alignment.center,
    child: const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );

  Widget _err(double? w, double? h) => Container(
    width: w,
    height: h,
    color: placeholderColor,
    alignment: Alignment.center,
    child: const Icon(Icons.broken_image_outlined, size: 18),
  );
}
