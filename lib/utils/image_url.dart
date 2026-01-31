import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class ImageUrl {
  static const String devGateway = 'https://dev.joyminis.com';
  static const String prodGateway = 'https://admin.joyminis.com';

  static const String devImgGateway = 'https://img.joyminis.com';
  static const String prodImgGateway = 'https://img.joyminis.com';

  static String gateway({bool useProd = false}) => useProd ? prodGateway : devGateway;
  static String imgGateway({bool useProd = false}) => useProd ? prodImgGateway : devImgGateway;

  static String formatToRelative(String? path) {
    if (path == null || path.isEmpty || path == '[Image]') return '';
    var res = path.trim();

    if (res.contains('uploads/')) {
      res = res.substring(res.indexOf('uploads/'));
    }

    while (res.startsWith('/')) res = res.substring(1);
    return res;
  }

  //  CHANGED: 视频也按 Web/Native 分流，Web 不直打 img（避免 CORS）
  static String buildVideo(String? raw) {
    if (raw == null || raw.isEmpty || raw == '[Image]') return '';
    final useProd = kReleaseMode;

    // Web: 用 gateway 同源；Native: 用 img 直连
    String base() => kIsWeb ? gateway(useProd: useProd) : imgGateway(useProd: useProd);

    if (raw.startsWith('http')) {
      // 如果是 img 域名，Web 也要换回 gateway
      if (raw.contains('img.joyminis.com')) {
        if (!kIsWeb) return raw;
        final rel = formatToRelative(raw);
        return rel.isEmpty ? raw : '${gateway(useProd: useProd)}/$rel';
      }

      final rel = formatToRelative(raw);
      return rel.isEmpty ? raw : '${base()}/$rel';
    }

    final rel = formatToRelative(raw);
    if (rel.isEmpty) return '';
    return '${base()}/$rel';
  }

  static String build(
      BuildContext context,
      String? raw, {
        double? logicalWidth,
        double? logicalHeight,
        BoxFit fit = BoxFit.cover,
        int quality = 75,
        String format = 'auto',
        bool forceGatewayOnNative = false,
      }) {
    if (raw == null || raw.isEmpty || raw == '[Image]') return '';

    if (raw.contains('/cdn-cgi/')) return raw;

    if (raw.startsWith('file://') ||
        raw.startsWith('assets/') ||
        raw.startsWith('blob:') ||
        raw.contains('localhost')) {
      return raw;
    }

    if (raw.startsWith('/') && !raw.contains('uploads/')) {
      return raw;
    }

    final String cleanPath = formatToRelative(raw);
    final bool useProd = kReleaseMode;

    final String gw = gateway(useProd: useProd);

    //  CHANGED: Web 走 gw（同源），Native 走 imgGw（绕开 nginx）
    final String imgGw = (kIsWeb || forceGatewayOnNative)
        ? gw
        : imgGateway(useProd: useProd);

    final String lowerPath = cleanPath.toLowerCase();
    final bool isVideo = lowerPath.endsWith('.mp4') ||
        lowerPath.endsWith('.mov') ||
        lowerPath.endsWith('.avi') ||
        lowerPath.endsWith('.m4v') ||
        lowerPath.endsWith('.m4a');

    final bool isUploadImage = cleanPath.contains('uploads/') && !isVideo;

    if (kIsWeb || forceGatewayOnNative || isUploadImage) {
      final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
      final double targetWidth = logicalWidth ?? 600;
      final w = (targetWidth * dpr).round();

      final params = <String>[
        'width=${min(w, 2048)}',
        'quality=$quality',
        'f=$format',
        'fit=${fit == BoxFit.contain ? "contain" : "scale-down"}',
      ];

      return '$imgGw/cdn-cgi/image/${params.join(",")}/$cleanPath';
    }

    return cleanPath.startsWith('http') ? cleanPath : '$gw/$cleanPath';
  }
}