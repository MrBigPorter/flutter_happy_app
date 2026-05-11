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

  /// 专门用于给完整的绝对路径（如商品图）插入 Cloudflare 缩放参数
  static String fitAbsoluteUrl(
      String fullUrl, {
        int? width,
        int? height,
        String fit = 'cover', // cover(裁剪填满) 或 scale-down(等比缩小)
      }) {
    if (fullUrl.trim().isEmpty) return fullUrl;

    // 如果已经被处理过，直接返回防重复拼接
    if (fullUrl.contains('/cdn-cgi/image/')) return fullUrl;

    try {
      final uri = Uri.parse(fullUrl);

      // 组装 Cloudflare 的处理参数
      List<String> options = [];
      if (width != null) options.add('width=$width');
      if (height != null) options.add('height=$height');
      options.add('fit=$fit');
      options.add('f=auto'); // 自动转换为 webp 等高效格式
      options.add('quality=80');

      final optionsStr = options.join(',');

      // 重新拼装：https://img.joyminis.com + /cdn-cgi/image/参数 + /images/xxx.png
      return '${uri.scheme}://${uri.host}/cdn-cgi/image/$optionsStr${uri.path}';
    } catch (e) {
      debugPrint('图片 URL 解析失败: $e');
      return fullUrl; // 兜底：如果出错就返回原图
    }
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

    // 2. 设备感知的宽度上限：手机最大 480 逻辑像素，平板 720，桌面 1080
    // 避免手机请求 1440px 的大图
    double maxLogicalWidth = 480; // 默认手机上限
    if (logicalWidth != null) {
      // 根据 logicalWidth 粗略判断设备类别
      if (logicalWidth > 1024) {
        maxLogicalWidth = 1080; // 桌面
      } else if (logicalWidth > 600) {
        maxLogicalWidth = 720; // 平板
      }
      // 取 logicalWidth 和设备上限中较小的值
      logicalWidth = min(logicalWidth, maxLogicalWidth);
    } else {
      logicalWidth = maxLogicalWidth;
    }

    // 3. 最终物理像素
    int finalW = (logicalWidth! * dpr).toInt();
    if (finalW < 100) finalW = 100;

    // 4. 强制 Fit 模式
    String fitParam = (fit == BoxFit.contain) ? "contain" : "scale-down";

    final params = 'width=$finalW,quality=$quality,f=auto,fit=$fitParam';
    return '${AppConfig.imgBaseUrl}${RemoteUrlBuilder.cdnPrefix}$params/$key';
  }
}