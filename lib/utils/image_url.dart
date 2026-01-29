import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class ImageUrl {
  static const String devGateway = 'http://dev.joyminis.com';
  static const String prodGateway = 'https://admin.joyminis.com';

  static String gateway({bool useProd = false}) => useProd ? prodGateway : devGateway;

  static String formatToRelative(String? path) {
    if (path == null || path.isEmpty || path == '[Image]') return '';
    var res = path.trim();
    if (!res.startsWith('http')) return res;
    final domains = [prodGateway, devGateway, 'https://admin.joyminis.com', 'https://img.joyminis.com'];
    for (var d in domains) {
      if (res.startsWith(d)) {
        res = res.replaceFirst(d, '');
        break;
      }
    }
    if (res.contains('uploads/')) res = res.substring(res.indexOf('uploads/'));
    while (res.startsWith('/')) res = res.substring(1);
    return res;
  }

  static String build(BuildContext context, String? raw, {
    double? logicalWidth, double? logicalHeight,
    BoxFit fit = BoxFit.cover, int quality = 75,
    String format = 'auto', bool forceGatewayOnNative = false,
  }) {
    if (raw == null || raw.isEmpty || raw == '[Image]') return '';

    // 1. 本地/内存资源直接放行，绝不加域名
    if (raw.startsWith('file://') ||
        raw.startsWith('assets/') ||
        raw.startsWith('blob:') ||
        raw.startsWith('/') || // 以 / 开头的绝对路径通常是本地文件
        raw.contains('localhost')) {
      return raw;
    }

    // 2. 清洗路径 (去掉已有的域名，保留 uploads/...)
    final cleanPath = formatToRelative(raw);

    // 3. 准备网关
    final gw = gateway(useProd: kReleaseMode);

    // 4. Web 端或强制模式：走 Cloudflare/Nginx 图片处理
    if (kIsWeb || forceGatewayOnNative) {
      final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
      final w = logicalWidth != null ? (logicalWidth * dpr).round() : null;

      List<String> params = [];
      if (w != null) params.add('width=${min(w, 2048)}');
      params.add('quality=$quality');
      params.add('f=$format');
      params.add('fit=${fit == BoxFit.contain ? "contain" : "cover"}');

      return '$gw/cdn-cgi/image/${params.join(",")}/$cleanPath';
    }

    // 5. 默认模式：直接拼上网关 (这是你缺失的逻辑！)
    // 只要代码走到这里，cleanPath 就是 uploads/chat/...，必须加上 gw 变成 http://...
    return '$gw/$cleanPath';
  }
}