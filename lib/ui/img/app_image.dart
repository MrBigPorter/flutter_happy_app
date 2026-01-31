import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:shimmer/shimmer.dart';
import '../chat/photo_preview_page.dart';
import '../../utils/image_url.dart';
import 'dart:async';
import 'package:dio/dio.dart';

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

  final Map<String, dynamic>? metadata;

  // 用于去重，防止列表滚动时重复打印同一个URL的日志
  static final Set<String> _debugged = {};

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
        this.format = kIsWeb ? 'auto' : 'webp',
        this.placeholderColor = const Color(0xFFF5F5F5),
        this.placeholder,
        this.error,
        this.enablePreview = false,
        this.heroTag,
        this.fadeInDuration,
        this.previewBytes,
        this.metadata,
      });

  ///  调试入口：仅在 Debug 模式下触发
  Future<void> debugImageHeaders(String url) async {
    // assert 语句只在 Debug 模式下运行，Release 模式会被编译器完全移除
    assert(() {
      unawaited(_debugImageHeadersAsync(url));
      return true;
    }());
  }

  /// ‍抓取并打印服务器返回的真实头部信息
  Future<void> _debugImageHeadersAsync(String url) async {
    try {
      final dio = Dio(BaseOptions(
        followRedirects: false,
        validateStatus: (_) => true, // 允许所有状态码
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));

      // 发起 HEAD 请求（轻量级，不下载图片体）
      final response = await dio.head(
        url,
        options: Options(headers: {
          'User-Agent':
          'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
        }),
      );

      // 🖨️ 只打印关键数据：格式、大小、CDN状态
      debugPrint('\n🔎 [IMG DATA] URL: $url');
      debugPrint('   Status: ${response.statusCode}');
      debugPrint('   Type:   ${response.headers.value('content-type')}');
      debugPrint('   Size:   ${response.headers.value('content-length')} bytes');
      debugPrint('   CDN:    ${response.headers.value('cf-cache-status') ?? 'MISS'}');
      debugPrint('---------------------------------------\n');

    } catch (e) {
      // 网络错误忽略即可，不影响主流程
    }
  }

  @override
  Widget build(BuildContext context) {
    // 布局锁定 (Anti-Jank)
    double? aspectRatio;
    if (metadata != null) {
      final double metaW = (metadata!['w'] ?? metadata!['width'] ?? 0).toDouble();
      final double metaH = (metadata!['h'] ?? metadata!['height'] ?? 0).toDouble();
      if (metaW > 0 && metaH > 0) {
        aspectRatio = metaW / metaH;
      }
    }

    Widget mainWidget = _buildContent(context);

    if (aspectRatio != null && height == null) {
      mainWidget = AspectRatio(aspectRatio: aspectRatio, child: mainWidget);
    }

    return mainWidget;
  }

  Widget _buildContent(BuildContext context) {
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

    // 空路径兜底：优先显示预览图
    if (path.isEmpty || path == '[Image]') {
      if (previewBytes != null && previewBytes!.isNotEmpty) {
        return _wrapper(
          context,
          Image.memory(previewBytes!, width: width, height: height, fit: fit, gaplessPlayback: true),
        );
      }
      return _ph(width, height);
    }

    final dpr = MediaQuery.of(context).devicePixelRatio;
    final int? memW = _calcMemSize(cacheWidth ?? width, dpr);
    final int? memH = _calcMemSize(cacheHeight ?? height, dpr);

    if (kIsWeb) {
      bool isRemote = !path.startsWith('blob:') && !path.startsWith('assets/');
      if (isRemote) return _buildNetworkImage(context, path, memW, memH);
      return _wrapper(context, Image.network(path, width: width, height: height, fit: fit, gaplessPlayback: true));
    }

    final isAsset = path.startsWith('assets/');
    final isFile = path.startsWith('/') || path.startsWith('file://');

    if (!isAsset && !isFile) {
      //  网络图片逻辑
      return _buildNetworkImage(context, path, memW, memH);
    } else if (isAsset) {
      return _wrapper(context, Image.asset(path, width: width, height: height, fit: fit, cacheWidth: memW, gaplessPlayback: true));
    } else {
      File file = path.startsWith('file://') ? File(Uri.parse(path).toFilePath()) : File(path);
      if (!file.existsSync()) {
        if (previewBytes != null && previewBytes!.isNotEmpty) {
          return _wrapper(context, Image.memory(previewBytes!, width: width, height: height, fit: fit, gaplessPlayback: true));
        }
        return _err(width, height);
      }
      return _wrapper(context, Image.file(file, width: width, height: height, fit: fit, cacheWidth: memW, gaplessPlayback: true));
    }
  }

  Widget _buildNetworkImage(BuildContext context, String path, int? memW, int? memH) {
    final String url;
    //  核心优化：如果已经是 CDN 链接，直接使用；否则调用 ImageUrl 计算
    if (path.contains('/cdn-cgi/')) {
      url = path;
    } else {
      url = ImageUrl.build(
        context, path,
        logicalWidth: cacheWidth ?? width,
        logicalHeight: cacheHeight ?? height,
        fit: fit, quality: quality, format: format,
      );
    }

    // 防御逻辑：URL 为空时显示占位
    if (url.isEmpty) {
      if (previewBytes != null && previewBytes!.isNotEmpty) {
        return _wrapper(
          context,
          Image.memory(previewBytes!, width: width, height: height, fit: fit, gaplessPlayback: true),
        );
      }
      final String? hash = metadata?['blurHash'];
      if (hash != null && hash.isNotEmpty) {
        return _wrapper(context, BlurHash(hash: hash, imageFit: fit, color: placeholderColor));
      }
      return _wrapper(context, _buildShimmer(width, height));
    }

    //  开发环境日志：只打印 CDN 或 Uploads 的请求数据
    assert(() {
      if ((url.contains('/cdn-cgi/image/') || url.contains('/uploads/')) &&
          _debugged.add(url)) {
       // debugImageHeaders(url);
      }
      return true;
    }());

    final animDuration = fadeInDuration ?? Duration.zero;

    Widget buildPlaceholder(BuildContext ctx, String url) {
      if (placeholder != null) return placeholder!;

      final String? hash = metadata?['blurHash'];
      if (hash != null && hash.isNotEmpty) {
        return BlurHash(hash: hash, imageFit: fit, color: placeholderColor);
      }

      if (previewBytes != null && previewBytes!.isNotEmpty) {
        return Image.memory(previewBytes!, width: width, height: height, fit: fit, gaplessPlayback: true);
      }

      return _buildShimmer(width, height);
    }

    return _wrapper(
      context,
      CachedNetworkImage(
        imageUrl: url,
        cacheKey: url,
        width: width, height: height,
        fit: fit,
        memCacheWidth: memW,
        memCacheHeight: memH,
        fadeOutDuration: animDuration,
        fadeInDuration: animDuration,
        placeholderFadeInDuration: Duration.zero,
        placeholder: buildPlaceholder,
        errorWidget: (_, __, ___) {
          if (previewBytes != null && previewBytes!.isNotEmpty) {
            return Image.memory(previewBytes!, width: width, height: height, fit: fit, gaplessPlayback: true);
          }
          return error ?? _err(width, height);
        },
      ),
      memW: memW,
      memH: memH,
    );
  }

  // 纯净版 wrapper：去掉了屏幕上的红绿框调试代码
  Widget _wrapper(BuildContext context, Widget child, {int? memW, int? memH}) {
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
            // 此时不需要传 debug url，保持界面整洁
            cachedThumbnailUrl: null,
            previewBytes: previewBytes,
            metadata: metadata,
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