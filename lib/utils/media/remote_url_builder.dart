import 'dart:math';
import 'package:flutter/widgets.dart';
import '../../core/config/app_config.dart'; //  确保这里引用了你的 AppConfig
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
  // 直接替换 imageCdn 方法
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

    // 1. 这里的 DPR 必须是整数阶梯，防止 3.75 这种碎数字
    double dpr = (context != null) ? MediaQuery.of(context).devicePixelRatio : 3.0;
    if (dpr > 2.5) {
      dpr = 3.0;
    } else {
      dpr = 2.0;
    }

    // 2. 核心：不论 UI 传什么，宽度强行锁定为 240 或 480
    // 这样 Preloader 和 UI 就再也不可能产生第三种宽度参数了
    int targetW = (logicalWidth != null && logicalWidth > 300) ? 480 : 240;

    // 3. 最终物理像素：240*3=720 或 480*3=1440
    int finalW = (targetW * dpr).toInt();

    // 4. 强制 Fit 模式 (这个不对齐也必死)
    String fitParam = (fit == BoxFit.contain) ? "contain" : "scale-down";

    final params = 'width=$finalW,quality=75,f=auto,fit=$fitParam';
    return '${AppConfig.imgBaseUrl}${RemoteUrlBuilder.cdnPrefix}$params/$key';
  }
}