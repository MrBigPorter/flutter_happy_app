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
        double? pixelRatio, // 去掉默认值 2.0，改为空
      }) {
    final t = MediaPath.classify(path);
    if (t == MediaPathType.empty) return '';

    String raw = path!.trim();

    // 1. 本地文件直接返回
    if (MediaPath.isLocal(raw)) return raw;

    // 2. 如果已经是经过 CDN 处理的路径，直接返回
    if (raw.contains(RemoteUrlBuilder.cdnPrefix)) return raw;

    // 如果是完整的 http 链接，检查是否属于我们自己的图片服务器
    if (t == MediaPathType.http) {
      if (raw.contains(AppConfig.imgBaseUrl)) {
        // 如果是自家域名，说明我们需要对其进行 CDN 缩放处理
        String oldRaw = raw;
        // 将 "https://img.joyminis.com/uploads/..." 还原为 "uploads/..."
        raw = raw.replaceFirst('${AppConfig.imgBaseUrl}/', '');
      } else {
        // 外部域名链接（如百度、腾讯图片），我们无法用自己的 CDN 缩放，原样返回
        return raw;
      }
    }

    final double effectivePR = pixelRatio ??
        (context != null ? MediaQuery.of(context).devicePixelRatio : 2.0);

    // 3. 统一交给 CDN 处理器
    final String finalUrl = RemoteUrlBuilder.imageCdn(
      context,
      raw,
      logicalWidth: logicalWidth,
      fit: fit,
      quality: quality,
      format: format,
      pixelRatio: effectivePR,
    );


    return finalUrl;
  }
}