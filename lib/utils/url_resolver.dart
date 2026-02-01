import 'dart:math';
import 'package:flutter/widgets.dart';
import '../core/config/app_config.dart';

class UrlResolver {
  static const String _cdnPrefix = '/cdn-cgi/image/';
  static const String _uploadsDir = 'uploads/';

  /// 生成静态地图快照 URL
  static String getStaticMapUrl(double lat, double lng) {
    // it's the stream API endpoint, which generates a static map image based on lat/lng
    return "${AppConfig.apiBaseUrl}/api/v1/media/static-map?lat=$lat&lng=$lng";
  }

  /// =================================================================
  /// 1. 通用文件解析 -> 走资源域名
  /// =================================================================
  static String resolveFile(String? path) {
    if (_isEmpty(path)) return '';
    if (_shouldIgnore(path!)) return path;

    final cleanPath = _normalizePath(path);
    return '${AppConfig.imgBaseUrl}/$cleanPath';
  }

  /// =================================================================
  /// 2. 视频解析 -> 走资源域名
  /// =================================================================
  static String resolveVideo(String? path) {
    if (_isEmpty(path)) return '';

    // 纠错：如果后端返回了绝对路径(http开头)，且包含 joyminis 域名，
    // 强制替换为当前环境配置的 imgBaseUrl，确保环境统一
    if (path!.startsWith('http')) {
      if (path.contains('joyminis.com')) {
        // 简单粗暴：只要是我们的域名，就把域名部分换成当前的 imgBaseUrl
        // 这样 Dev 环境就会被修正为 dev 域名，Prod 修正为 img 域名
        // 这里做个简单正则替换或者直接由调用方保证 path 是相对路径更好
        // 为防止误伤，这里仅处理 img 域名的替换
        if (path.contains('img.joyminis.com') && AppConfig.imgBaseUrl != 'https://img.joyminis.com') {
          return path.replaceFirst('https://img.joyminis.com', AppConfig.imgBaseUrl);
        }
      }
      return path;
    }

    return '${AppConfig.imgBaseUrl}/${_normalizePath(path)}';
  }

  /// =================================================================
  /// 3. 图片解析 -> 无条件走 CDN
  /// =================================================================
  static String resolveImage(
      BuildContext? context,
      String? path,
      {
        double? logicalWidth,
        double? logicalHeight,
        BoxFit fit = BoxFit.cover,
        int quality = 75,
        String format = 'auto',
        bool forceGatewayOnNative = false,
        double pixelRatio = 2.0,
      }) {
    if (_isEmpty(path)) return '';

    // 如果已经是完整链接(非uploads)或者是本地文件，直接返回
    if (_shouldIgnore(path!)) {
      if (path.contains(_cdnPrefix)) return path; // 已经拼过参数了
      return path;
    }

    final cleanPath = _normalizePath(path);
    final String baseUrl = AppConfig.imgBaseUrl;


    double dpr = pixelRatio;
    if (context != null) {
      dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? pixelRatio;
    }

    final targetW = logicalWidth ?? 600;
    final w = (targetW * dpr).round();
    final finalW = min(w, 2048);

    final fitMode = fit == BoxFit.contain ? "contain" : "scale-down";
    final params = 'width=$finalW,quality=$quality,f=$format,fit=$fitMode';

    return '$baseUrl$_cdnPrefix$params/$cleanPath';
  }

  // --- Helpers ---
  static bool _isEmpty(String? s) => s == null || s.trim().isEmpty || s == '[Image]' || s == '[File]';

  static bool _shouldIgnore(String path) {
    return path.startsWith('http') ||
        path.startsWith('blob:') ||
        path.startsWith('file://') ||
        path.startsWith('assets/') ||
        path.contains('localhost');
  }

  static String _normalizePath(String path) {
    var res = path.trim();
    if (res.contains(_uploadsDir)) {
      res = res.substring(res.indexOf(_uploadsDir));
    }
    while (res.startsWith('/')) res = res.substring(1);
    return res;
  }
}