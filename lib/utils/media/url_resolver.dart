import 'package:flutter/widgets.dart';
import '../../core/config/app_config.dart';

import 'media_path.dart';
import 'remote_url_builder.dart';

class UrlResolver {
  static String getStaticMapUrl(double lat, double lng) {
    return "${AppConfig.apiBaseUrl}/api/v1/media/static-map?lat=$lat&lng=$lng";
  }

  static String resolveFile(String? path) {
    final t = MediaPath.classify(path);
    if (t == MediaPathType.empty) return '';

    // 本地文件直接返回
    if (MediaPath.isLocal(path)) return path!.trim();

    // 只有 uploads 或 http 才补全域名
    return RemoteUrlBuilder.toFull(path!.trim());
  }

  static String resolveVideo(String? path) {
    final t = MediaPath.classify(path);
    if (t == MediaPathType.empty) return '';

    final raw = path!.trim();
    if (MediaPath.isLocal(raw)) return raw;

    if (t == MediaPathType.http) {
      if (raw.contains('img.joyminis.com') && AppConfig.imgBaseUrl != 'https://img.joyminis.com') {
        return raw.replaceFirst('https://img.joyminis.com', AppConfig.imgBaseUrl);
      }
      return raw;
    }

    return RemoteUrlBuilder.toFull(raw);
  }

  static String resolveImage(
      BuildContext? context,
      String? path, {
        double? logicalWidth,
        double? logicalHeight,
        BoxFit fit = BoxFit.cover,
        int quality = 75,
        String format = 'auto',
        double pixelRatio = 2.0,
      }) {
    final t = MediaPath.classify(path);
    if (t == MediaPathType.empty) return '';

    final raw = path!.trim();

    //  双重保险：如果是本地/未知路径，直接返回原字符串，绝不进 CDN 逻辑
    if (MediaPath.isLocal(raw)) return raw; //

    if (raw.contains(RemoteUrlBuilder.cdnPrefix)) return raw;
    if (t == MediaPathType.http) return raw;

    // 只有 uploads/ 开头的路径才走这里
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