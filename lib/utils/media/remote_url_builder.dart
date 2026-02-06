import 'dart:math';
import 'package:flutter/widgets.dart';
import '../../core/config/app_config.dart';
import 'media_path.dart';

class RemoteUrlBuilder {
  static const String cdnPrefix = '/cdn-cgi/image/';

  /// http(s) -> 原样返回
  static String toFull(String remotePath) {
    final p = remotePath.trim();
    if (p.isEmpty) return '';

    if (MediaPath.isHttp(p)) return p;

    final key = MediaPath.normalizeRemoteKey(p);
    return '${AppConfig.imgBaseUrl}/$key';
  }

  /// 仅对远端资源生成 CDN URL（注意：这里不判断本地）
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
    final finalW = min(w, 2048);

    final fitMode = fit == BoxFit.contain ? "contain" : "scale-down";
    final params = 'width=$finalW,quality=$quality,f=$format,fit=$fitMode';

    //  保持你现有写法：同域路径 /cdn-cgi/image/.../<key>
    return '${AppConfig.imgBaseUrl}$cdnPrefix$params/$key';
  }
}