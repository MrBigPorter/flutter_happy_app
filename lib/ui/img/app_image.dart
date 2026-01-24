import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/chat/photo_preview_page.dart';

 import 'package:shimmer/shimmer.dart';
import '../../utils/image_url.dart';

class AppCachedImage extends StatelessWidget {
  final String? src;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? radius;
  final String? heroTag;
  final int quality;
  final String format;
  final bool forceGatewayOnNative;
  final Color placeholderColor;
  final Widget? placeholder;
  final Widget? error;
  final bool enablePreview;

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
    this.placeholderColor = const Color(0xFFF5F5F5),
    this.placeholder,
    this.error,
    this.enablePreview = false,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    if (src == null || src!.isEmpty) {
      return _wrapper(_ph(width, height), context);
    }

    final isNetwork = src!.startsWith('http');
    final isAsset = src!.startsWith('assets/');

    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    final int? memW = (width == null) ? null : (width! * dpr).round();
    final int? memH = (height == null) ? null : (height! * dpr).round();

    Widget imageWidget;

    if (isNetwork) {
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

      //  修正点 1：Web 端强制使用 Image.network (解决大图卡顿/黑屏)
      if (kIsWeb) {
        imageWidget = Image.network(
          url,
          width: width,
          height: height,
          fit: fit,
          // 加上淡入动画，体验和 CachedNetworkImage 一致
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: child,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return placeholder ?? _buildShimmer(width, height);
          },
          errorBuilder: (_, __, ___) => error ?? _err(width, height),
        );
      } else {
        // App 端保持原样
        imageWidget = CachedNetworkImage(
          imageUrl: url,
          width: width,
          height: height,
          fit: fit,
          memCacheWidth: memW,
          memCacheHeight: memH,
          maxWidthDiskCache: memW,
          maxHeightDiskCache: memH,
          fadeOutDuration: Duration.zero,
          fadeInDuration: const Duration(milliseconds: 300),
          placeholder: (_, __) => placeholder ?? _buildShimmer(width, height),
          errorWidget: (_, __, ___) => error ?? _err(width, height),
        );
      }
    } else if (isAsset) {
      imageWidget = Image.asset(
        src!,
        width: width,
        height: height,
        cacheWidth: memW,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => error ?? _err(width, height),
      );
    } else {
      // 本地文件 / Blob
      if (kIsWeb) {
        imageWidget = Image.network(
          src!,
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => error ?? _err(width, height),
        );
      } else {
        final file = File(src!);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            width: width,
            height: height,
            cacheWidth: memW,
            fit: fit,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => error ?? _err(width, height),
          );
        } else {
          imageWidget = _err(width, height);
        }
      }
    }

    return _wrapper(imageWidget, context);
  }

  Widget _wrapper(Widget child, BuildContext context) {
    Widget res = child;

    if (radius != null) {
      res = ClipRRect(borderRadius: radius!, child: res);
    }

    //  修正点 2：修复 Hero 逻辑 (isEmpty -> isNotEmpty)
    if (heroTag != null && heroTag!.isNotEmpty) {
      res = Hero(tag: heroTag!, transitionOnUserGestures: true, child: res);
    }

    if (enablePreview && src != null && src!.isNotEmpty) {
      res = GestureDetector(
        onTap: () {
          // 这里只负责最基础的预览，聊天页面会自己处理点击
          // 所以这段逻辑主要是给非聊天页面用的
          final bool _ =
              !src!.startsWith('http') && !src!.startsWith('assets/');

          Navigator.push(
            context,
            PageRouteBuilder(
              opaque: false,
              pageBuilder: (_, __, ___) => PhotoPreviewPage(
                heroTag: heroTag ?? src!,
                imageSource: src!,
                thumbnailSource: src!,
              ),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        },
        child: res,
      );
    }

    return res;
  }

  //  骨架屏效果 (使用 shimmer 包)
  Widget _buildShimmer(double? w, double? h) {
    return Shimmer.fromColors(
      // 基础底色 (和你原本的 placeholderColor 一致)
      baseColor: placeholderColor,
      // 扫光颜色 (稍微亮一点，形成扫光效果)
      highlightColor: Colors.white,
      child: Container(
        width: w,
        height: h,
        color: Colors.white, // 这里必须给个颜色，Shimmer 才能依附在形状上
      ),
    );
  }

  Widget _ph(double? w, double? h) => Container(
    width: w,
    height: h,
    color: placeholderColor,
    alignment: Alignment.center,
    child: Icon(Icons.image, color: Colors.grey[400], size: 20),
  );

  Widget _err(double? w, double? h) => Container(
    width: w,
    height: h,
    color: placeholderColor,
    alignment: Alignment.center,
    child: Icon(Icons.broken_image_rounded, color: Colors.grey[400], size: 24),
  );
}
