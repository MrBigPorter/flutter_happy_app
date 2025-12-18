// lib/utils/image_url.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class ImageUrl {
  static const String devGateway = 'http://dev.joyminis.com';
  static const String prodGateway = 'https://admin.joyminis.com';

  static String gateway({bool useProd = false}) => useProd ? prodGateway : devGateway;

  static String build(
      BuildContext context,
      String? raw, {
        double? logicalWidth,
        double? logicalHeight,
        BoxFit fit = BoxFit.cover,
        int quality = 75,
        String format = 'auto',
        bool forceGatewayOnNative = false,
        bool? useProdGateway,
      }) {
    if (raw == null || raw.trim().isEmpty) return '';
    var url = raw.trim();

    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    final useGateway = kIsWeb || forceGatewayOnNative;
    final gw = gateway(useProd: useProdGateway ?? kReleaseMode);

    // 1) 如果本身已经是 cdn-cgi/image（比如 admin 返回的），Web 也必须改成走网关域名
    if (url.contains('/cdn-cgi/image/')) {
      if (useGateway) {
        // 把原来的 scheme+host 替换成 gw，保证请求一定打到你的 nginx
        // 例：https://admin.joyminis.com/cdn-cgi/image/... -> http://dev.joyminis.com/cdn-cgi/image/...
        url = _replaceOriginWithGateway(url, gw);
      }
      return url;
    }

    // 2) 非 cdn-cgi：拼参数并包一层 /cdn-cgi/image
    if (!useGateway) return url;

    int? wPx = _toPx(logicalWidth, dpr);
    int? hPx = _toPx(logicalHeight, dpr);

    final params = <String>[];
    if (wPx != null) params.add('width=$wPx');
    if (hPx != null) params.add('height=$hPx');
    params.add('dpr=${_fmtDpr(dpr)}');
    params.add('quality=${quality.clamp(30, 95)}');
    params.add('fit=${_toCdnFit(fit)}');
    params.add('f=$format');

    return '$gw/cdn-cgi/image/${params.join(",")}/$url';
  }

  static String _replaceOriginWithGateway(String url, String gw) {
    // 如果是绝对 URL：替换成 gw
    // 如果不是绝对 URL：直接拼 gw
    final lower = url.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      final uri = Uri.parse(url);
      return '$gw${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
    }
    if (url.startsWith('/')) return '$gw$url';
    return '$gw/$url';
  }

  static int? _toPx(double? logical, double dpr) {
    if (logical == null || logical <= 0) return null;
    final px = (logical * dpr).round();
    return min(max(px, 1), 2048);
  }

  static String _fmtDpr(double dpr) {
    if (dpr <= 1.0) return '1';
    if (dpr <= 1.5) return '1.5';
    if (dpr <= 2.0) return '2';
    if (dpr <= 3.0) return '3';
    return '3';
  }

  static String _toCdnFit(BoxFit fit) {
    switch (fit) {
      case BoxFit.contain:
        return 'contain';
      case BoxFit.cover:
      default:
        return 'cover';
    }
  }
}