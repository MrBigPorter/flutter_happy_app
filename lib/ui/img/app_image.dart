import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
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
  final Map<String, dynamic>? metadata;

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

  //  CHANGED: 不要固定 iOS UA（也不要 const）
  // Web 上浏览器会自己带 UA；native 如需“伪装 Safari”再做平台判断
  static Map<String, String> buildImgHttpHeaders() {
    if (kIsWeb) return {};

    final base = <String, String>{
      'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
    };

    // 你如果确实需要 iOS Safari UA（为了绕某些 WAF/策略），只对 iOS 加
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      base['User-Agent'] =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) '
          'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 '
          'Mobile/15E148 Safari/604.1';
    }

    return base;
  }

  @override
  Widget build(BuildContext context) {
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
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
        ),
      );
    }

    final String path = src?.toString() ?? '';

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
      final isRemote = !path.startsWith('blob:') && !path.startsWith('assets/');
      if (isRemote) return _buildNetworkImage(context, path, memW, memH);
      return _wrapper(
        context,
        Image.network(path, width: width, height: height, fit: fit, gaplessPlayback: true),
      );
    }

    final isAsset = path.startsWith('assets/');
    final isFile = path.startsWith('/') || path.startsWith('file://');

    if (!isAsset && !isFile) {
      return _buildNetworkImage(context, path, memW, memH);
    } else if (isAsset) {
      return _wrapper(
        context,
        Image.asset(path, width: width, height: height, fit: fit, cacheWidth: memW, gaplessPlayback: true),
      );
    } else {
      final file = path.startsWith('file://') ? File(Uri.parse(path).toFilePath()) : File(path);
      if (!file.existsSync()) {
        if (previewBytes != null && previewBytes!.isNotEmpty) {
          return _wrapper(
            context,
            Image.memory(previewBytes!, width: width, height: height, fit: fit, gaplessPlayback: true),
          );
        }
        return _err(width, height);
      }
      return _wrapper(
        context,
        Image.file(file, width: width, height: height, fit: fit, cacheWidth: memW, gaplessPlayback: true),
      );
    }
  }

  Widget _buildNetworkImage(BuildContext context, String path, int? memW, int? memH) {
    final String url;

    if (path.contains('/cdn-cgi/')) {
      url = path;
    } else {
      url = ImageUrl.build(
        context,
        path,
        logicalWidth: cacheWidth ?? width,
        logicalHeight: cacheHeight ?? height,
        fit: fit,
        quality: quality,
        format: format,
      );
    }

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

    assert(() {
      if ((url.contains('/cdn-cgi/image/') || url.contains('/uploads/')) && _debugged.add(url)) {
        // 这里你要 debug HEAD 的话再打开
        // debugImageHeaders(url);
      }
      return true;
    }());

    final animDuration = fadeInDuration ?? Duration.zero;

    Widget buildPlaceholder(BuildContext ctx, String _) {
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

    //  CHANGED: 把“原始 source + 当前缩略图 url”一起传给预览页
    return _wrapper(
      context,
      CachedNetworkImage(
        imageUrl: url,
        cacheKey: url,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memW,
        memCacheHeight: memH,
        httpHeaders: buildImgHttpHeaders(), // ✅ CHANGED
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
      //  CHANGED: 预览页需要这两个参数避免再打一次 /uploads
      previewSource: path,
      cachedThumbUrl: url,
    );
  }

  // CHANGED: wrapper 增加两个参数（仅网络图时传入）
  Widget _wrapper(
      BuildContext context,
      Widget child, {
        String? previewSource,
        String? cachedThumbUrl,
      }) {
    Widget res = child;

    if (radius != null) res = ClipRRect(borderRadius: radius!, child: res);
    if (heroTag != null && heroTag!.isNotEmpty) res = Hero(tag: heroTag!, child: res);

    if (enablePreview && src != null) {
      res = GestureDetector(
        onTap: () => Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => PhotoPreviewPage(
              heroTag: heroTag ?? src.toString(),
              imageSource: previewSource ?? src.toString(),
              cachedThumbnailUrl: cachedThumbUrl,
              previewBytes: previewBytes,
              metadata: metadata,
            ),
          ),
        ),
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