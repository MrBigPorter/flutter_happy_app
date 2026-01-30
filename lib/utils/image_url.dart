import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class ImageUrl {
  static const String devGateway = 'https://dev.joyminis.com';
  static const String prodGateway = 'https://admin.joyminis.com';

  static String gateway({bool useProd = false}) => useProd ? prodGateway : devGateway;

  /// 🧹 强力清洗逻辑：提取相对路径
  static String formatToRelative(String? path) {
    if (path == null || path.isEmpty || path == '[Image]') return '';
    var res = path.trim();

    // 核心修复：只要包含 uploads/，直接截取后面部分
    if (res.contains('uploads/')) {
      res = res.substring(res.indexOf('uploads/'));
    }

    // 去掉开头的斜杠，确保统一为 "uploads/chat/..."
    while (res.startsWith('/')) res = res.substring(1);

    return res;
  }

  ///  构建 CDN 链接
  static String build(BuildContext context, String? raw, {
    double? logicalWidth, double? logicalHeight,
    BoxFit fit = BoxFit.cover, int quality = 75,
    String format = 'auto', bool forceGatewayOnNative = false,
  }) {
    if (raw == null || raw.isEmpty || raw == '[Image]') return '';

    // 0. 免检通道：已经是 CDN 链接则直接放行 (防止 AppCachedImage 重复计算)
    if (raw.contains('/cdn-cgi/')) {
      return raw;
    }

    // 1. 本地/内存/Assets/Blob 资源直接放行
    if (raw.startsWith('file://') || raw.startsWith('assets/') ||
        raw.startsWith('blob:') || raw.contains('localhost')) {
      return raw;
    }

    // 2. 非 uploads 的绝对路径放行 (比如外部链接，或者是本地 absolute path)
    if (raw.startsWith('/') && !raw.contains('uploads/')) {
      return raw;
    }

    // 3. 清洗路径
    String cleanPath = formatToRelative(raw);
    final gw = gateway(useProd: kReleaseMode);

    // 4. 判定是否为上传的图片
    final String lowerPath = cleanPath.toLowerCase();
    final bool isVideo = lowerPath.endsWith('.mp4') || lowerPath.endsWith('.mov') ||
        lowerPath.endsWith('.avi') || lowerPath.endsWith('.m4v');

    // 只要包含 uploads/ 且不是视频，就视为图片，必须走 CDN
    final bool isUploadImage = cleanPath.contains('uploads/') && !isVideo;

    // 5. 构造 CDN 链接
    if (kIsWeb || forceGatewayOnNative || isUploadImage) {
      final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
      final double targetWidth = logicalWidth ?? 600;
      final w = (targetWidth * dpr).round();

      List<String> params = [
        'width=${min(w, 2048)}',
        'quality=$quality',
        'f=$format',
        // 核心修复：配合 BoxFit.cover，必须使用 scale-down 避免 Cloudflare 报错
        'fit=${fit == BoxFit.contain ? "contain" : "scale-down"}'
      ];

      return '$gw/cdn-cgi/image/${params.join(",")}/$cleanPath';
    }

    // 6. 兜底逻辑 (视频或非图片资源走直连)
    return cleanPath.startsWith('http') ? cleanPath : '$gw/$cleanPath';
  }
}