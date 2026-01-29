import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../chat/photo_preview_page.dart';
import '../../utils/image_url.dart';

class AppCachedImage extends StatelessWidget {
  final dynamic src;
  final double? width, height, cacheWidth, cacheHeight;
  final BoxFit fit;
  final BorderRadius? radius;
  final String? heroTag; // 如果开启预览，建议必须传唯一的 heroTag
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
    // 1. 快速处理二进制数据 (Uint8List)
    if (src is Uint8List) {
      return _wrapper(
        context,
        Image.memory(
          src as Uint8List,
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
        ),
      );
    }

    final String path = src?.toString() ?? '';
    if (path.isEmpty || path == '[Image]') return _ph(width, height);

    // 2. 计算内存缓存尺寸 (DPR 优化)
    // 避免解码超大图片导致内存溢出和卡顿
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final int? memW = _calcMemSize(cacheWidth ?? width, dpr);
    final int? memH = _calcMemSize(cacheHeight ?? height, dpr);

    // 3. 判定图片类型
    // 优先判定 Web，因为 Web 不支持 File IO
    if (kIsWeb) {
      // Web 端全部视为 NetworkImage (包括 blob: 和 assets 也是通过 url 加载)
      // 注意：Assets 在 Web 上通常不需要 ImageUrl 处理，除非你有特殊 CDN
      bool isRemote = !path.startsWith('blob:') && !path.startsWith('assets/');
      if (isRemote) {
        return _buildNetworkImage(context, path, memW, memH);
      } else {
        return _wrapper(
          context,
          Image.network(
            path,
            width: width,
            height: height,
            fit: fit,
            gaplessPlayback: true,
          ),
        );
      }
    }

    // 4. Mobile 端逻辑
    final isAsset = path.startsWith('assets/');
    final isFile = path.startsWith('/') || path.startsWith('file://');
    final isRemote = !isAsset && !isFile;

    if (isRemote) {
      return _buildNetworkImage(context, path, memW, memH);
    } else if (isAsset) {
      return _wrapper(
        context,
        Image.asset(
          path,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: memW,
          gaplessPlayback: true,
        ),
      );
    } else {
      // File 处理优化
      File file;
      try {
        if (path.startsWith('file://')) {
          file = File(Uri.parse(path).toFilePath());
        } else {
          file = File(path);
        }
      } catch (e) {
        return _err(width, height);
      }

      return _wrapper(
        context,
        Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: memW,
          gaplessPlayback: true,
        ),
      );
    }
  }

  // 构建网络图片 (核心优化点)
  Widget _buildNetworkImage(
      BuildContext context, String path, int? memW, int? memH) {
    // 调用 ImageUrl 工具进行 CDN 裁剪/格式转换参数拼接
    final url = ImageUrl.build(
      context,
      path,
      logicalWidth: cacheWidth ?? width,
      logicalHeight: cacheHeight ?? height,
      fit: fit,
      quality: quality,
      format: format,
    );

    // 设定动画时间：如果外部传了就用外部的，否则为了性能默认 0
    final animDuration = fadeInDuration ?? Duration.zero;

    // 占位图逻辑：优先用传入的 -> 其次用预览图(高斯模糊/缩略图) -> 最后用 Shimmer
    Widget buildPlaceholder(BuildContext ctx, String url) {
      if (placeholder != null) return placeholder!;
      if (previewBytes != null) {
        return Image.memory(
          previewBytes!,
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
        );
      }
      return _buildShimmer(width, height);
    }

    return _wrapper(
      context,
      CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        // 核心：指定内存缓存大小，由 flutter 引擎在解码时缩小图片，大幅降低内存
        memCacheWidth: memW,
        memCacheHeight: memH,
        // 动画控制
        fadeOutDuration: animDuration,
        fadeInDuration: animDuration,
        placeholderFadeInDuration: Duration.zero, // 占位图不需要渐变，直接显示
        placeholder: buildPlaceholder,
        errorWidget: (_, __, ___) => error ?? _err(width, height),
      ),
      currentUrl: url,
      memW: memW,
      memH: memH,
    );
  }

  // 包装器：处理 圆角、Hero、点击预览
  Widget _wrapper(
      BuildContext context,
      Widget child, {
        String? currentUrl,
        int? memW,
        int? memH,
      }) {
    Widget res = child;

    // 1. 圆角
    if (radius != null) {
      res = ClipRRect(borderRadius: radius!, child: res);
    }

    // 2. Hero 动画 (安全检查)
    // 只有当提供了 heroTag 且不为空时才启用 Hero。
    // 避免在列表中多个相同 URL 图片导致 crash。
    if (heroTag != null && heroTag!.isNotEmpty) {
      res = Hero(tag: heroTag!, child: res);
    }

    // 3. 点击预览
    if (enablePreview && src != null) {
      res = GestureDetector(
        onTap: () {
          // 预览页面通常需要显示原始大图，但这里为了过渡平滑，
          // 可以把当前已经加载好的缩略图 url 传过去作为 thumbnail
          Navigator.push(
            context,
            PageRouteBuilder(
              opaque: false, // 透明背景
              pageBuilder: (_, __, ___) => PhotoPreviewPage(
                // 必须保证 Hero tag 一致
                heroTag: heroTag ?? src.toString(),
                imageSource: src.toString(),
                cachedThumbnailUrl: currentUrl,
                previewBytes: previewBytes,
                // 传过去是为了预览页也能做初始优化，虽然预览页一般看原图
                memW: memW,
                memH: memH,
              ),
            ),
          );
        },
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
    period: const Duration(milliseconds: 1500), // 稍微调慢一点，更有质感
    child: Container(width: w, height: h, color: Colors.white),
  );

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
    child: Icon(Icons.broken_image, color: Colors.grey[400], size: 24),
  );
}