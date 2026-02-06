import 'package:flutter/widgets.dart';
import '../../core/config/app_config.dart';

//  CHANGED: 引入两个新模块
import 'media_path.dart';
import 'remote_url_builder.dart';

class UrlResolver {
  /// 生成静态地图快照 URL
  static String getStaticMapUrl(double lat, double lng) {
    return "${AppConfig.apiBaseUrl}/api/v1/media/static-map?lat=$lat&lng=$lng";
  }

  /// =================================================================
  /// 1. 通用文件解析 -> 走资源域名
  /// =================================================================
  static String resolveFile(String? path) {
    final t = MediaPath.classify(path);
    if (t == MediaPathType.empty) return '';

    //  CHANGED: 本地/特殊路径直接返回
    if (MediaPath.isLocal(path)) return path!.trim();

    //  CHANGED: 远端补全成完整 URL（uploads/.. 或 relative）
    return RemoteUrlBuilder.toFull(path!.trim());
  }

  /// =================================================================
  /// 2. 视频解析 -> 走资源域名
  /// =================================================================
  static String resolveVideo(String? path) {
    final t = MediaPath.classify(path);
    if (t == MediaPathType.empty) return '';

    final raw = path!.trim();

    //  CHANGED: 本地/特殊路径直接返回
    if (MediaPath.isLocal(raw)) return raw;

    //  CHANGED: http 原样返回（保留你原逻辑的“绝对链接不动”）
    if (t == MediaPathType.http) {
      // 你原来的 joyminis 域名修正逻辑也可以继续放这里（可选）
      if (raw.contains('img.joyminis.com') && AppConfig.imgBaseUrl != 'https://img.joyminis.com') {
        return raw.replaceFirst('https://img.joyminis.com', AppConfig.imgBaseUrl);
      }
      return raw;
    }

    //  CHANGED: uploads/relative -> 补全域名
    return RemoteUrlBuilder.toFull(raw);
  }

  /// =================================================================
  /// 3. 图片解析 -> 走 CDN（仅远端）
  /// =================================================================
  static String resolveImage(
      BuildContext? context,
      String? path, {
        double? logicalWidth,
        double? logicalHeight,
        BoxFit fit = BoxFit.cover,
        int quality = 75,
        String format = 'auto',
        bool forceGatewayOnNative = false,
        double pixelRatio = 2.0,
      }) {
    final t = MediaPath.classify(path);
    if (t == MediaPathType.empty) return '';

    final raw = path!.trim();

    //  CHANGED: 本地/特殊路径原样返回（永不走 CDN）
    if (MediaPath.isLocal(raw)) return raw;

    //  CHANGED: 已经是 cdn-cgi 拼好的，直接返回（避免重复拼参）
    if (raw.contains(RemoteUrlBuilder.cdnPrefix)) return raw;

    //  CHANGED: http 直接返回（保持你原行为：不二次套网关）
    if (t == MediaPathType.http) return raw;

    //  CHANGED: uploads/relative -> 生成 CDN URL（同域 key）
    return RemoteUrlBuilder.imageCdn(
      context,
      raw,
      logicalWidth: logicalWidth,
      fit: fit,
      quality: quality,
      format: format,
      pixelRatio: pixelRatio,
    );
  }
}