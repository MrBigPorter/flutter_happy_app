import 'dart:math';
import 'package:flutter/widgets.dart';
import '../../core/config/app_config.dart'; // 👈 确保这里引用了你的 AppConfig
import 'media_path.dart';

class RemoteUrlBuilder {
  // Cloudflare 或其他 CDN 的处理前缀
  static const String cdnPrefix = '/cdn-cgi/image/';

  /// 将相对路径转为完整 URL
  /// uploads/xxx.jpg -> https://api.com/uploads/xxx.jpg
  static String toFull(String remotePath) {
    final p = remotePath.trim();
    if (p.isEmpty) return '';

    // 如果已经是 http 开头，直接返回
    if (MediaPath.isHttp(p)) return p;

    final key = MediaPath.normalizeRemoteKey(p);
    // 拼接域名 (AppConfig.imgBaseUrl 最好不要带结尾斜杠，或者这里做个判断)
    return '${AppConfig.imgBaseUrl}/$key';
  }

  /// 生成带 CDN 参数的 URL
  static String imageCdn(
      BuildContext? context,
      String remotePath, {
        double? logicalWidth,
        BoxFit fit = BoxFit.cover,
        int quality = 75,
        String format = 'auto',
        double pixelRatio = 2.0,
      }) {
    final key = MediaPath.normalizeRemoteKey(remotePath);
    if (key.isEmpty) return '';

    double dpr = pixelRatio;
    if (context != null) {
      dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? pixelRatio;
    }

    final targetW = logicalWidth ?? 600;
    final w = (targetW * dpr).round();
    // 限制最大宽度，防止请求过大图片
    final finalW = min(w, 2048);

    final fitMode = fit == BoxFit.contain ? "contain" : "scale-down";
    final params = 'width=$finalW,quality=$quality,f=$format,fit=$fitMode';

    // 拼接：BaseUrl + CDN前缀 + 参数 + Key
    return '${AppConfig.imgBaseUrl}$cdnPrefix$params/$key';
  }
}