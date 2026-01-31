import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class ImageUrl {
  // =========================
  //  CHANGED 1) 网关拆分：API 网关 vs 图片网关
  // 你原来 prodGateway = admin.joyminis.com 这会让“图片域名”混进后台域名
  // =========================

  /// 业务/前端 网关（如果你还有地方需要拼业务链接）
  static const String devGateway = 'https://dev.joyminis.com';
  static const String prodGateway = 'https://admin.joyminis.com';

  ///  图片/CDN 网关（重点：让 /cdn-cgi/image 永远走 img 域名）
  static const String devImgGateway = 'https://img.joyminis.com';
  static const String prodImgGateway = 'https://img.joyminis.com';

  static String gateway({bool useProd = false}) => useProd ? prodGateway : devGateway;

  ///  CHANGED：专门给图片用的网关
  static String imgGateway({bool useProd = false}) => useProd ? prodImgGateway : devImgGateway;

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

  /// 构建 CDN 链接
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

    // 0) 免检通道：已经是 CDN 链接则直接放行（避免重复套娃）
    if (raw.contains('/cdn-cgi/')) {
      return raw;
    }

    // 1) 本地/内存/Assets/Blob/localhost 资源直接放行
    if (raw.startsWith('file://') ||
        raw.startsWith('assets/') ||
        raw.startsWith('blob:') ||
        raw.contains('localhost')) {
      return raw;
    }

    // 2) 非 uploads 的绝对路径放行
    // （外部链接 / 非你们资源，别动它）
    if (raw.startsWith('/') && !raw.contains('uploads/')) {
      return raw;
    }

    // 3) 清洗成相对路径：uploads/...
    final String cleanPath = formatToRelative(raw);

    //  CHANGED 2) 注意这里：图片格式化要用 img 网关，不要用 admin/dev 网关
    final bool useProd = kReleaseMode;
    final String imgGw = imgGateway(useProd: useProd);
    final String gw = gateway(useProd: useProd); // 业务兜底用（比如你要拼非图片资源）

    // 4) 判定视频
    final String lowerPath = cleanPath.toLowerCase();
    final bool isVideo = lowerPath.endsWith('.mp4') ||
        lowerPath.endsWith('.mov') ||
        lowerPath.endsWith('.avi') ||
        lowerPath.endsWith('.m4v') ||
        lowerPath.endsWith('.m4a');

    // 只要包含 uploads/ 且不是视频，就视为图片，必须走 CDN
    final bool isUploadImage = cleanPath.contains('uploads/') && !isVideo;

    // 5) 构造 CDN 链接（图片格式化）
    if (kIsWeb || forceGatewayOnNative || isUploadImage) {
      final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
      final double targetWidth = logicalWidth ?? 600;
      final w = (targetWidth * dpr).round();

      // 你原来没用 logicalHeight，这里先不动（保持最小改动）
      final params = <String>[
        'width=${min(w, 2048)}',
        'quality=$quality',
        'f=$format',
        // 保持你的策略不变
        'fit=${fit == BoxFit.contain ? "contain" : "scale-down"}',
      ];

      //  CHANGED 3) 关键：cdn-cgi/image 走 imgGw
      return '$imgGw/cdn-cgi/image/${params.join(",")}/$cleanPath';
    }

    // 6) 兜底：视频或非图片资源走直连（这里仍然可以走业务 gw）
    // 你也可以改成对 uploads 视频走 imgGw，但这里先不乱动
    return cleanPath.startsWith('http') ? cleanPath : '$gw/$cleanPath';
  }
}