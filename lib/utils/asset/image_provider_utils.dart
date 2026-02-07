import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// CHANGED: 条件导入：Web 不会编译 dart:io
import 'image_provider_utils_stub.dart'
if (dart.library.io) 'image_provider_utils_io.dart';

/// CHANGED: 统一图片请求头（让 CF 更稳返回 webp/avif，且不再是 Dart UA）
/// 注意：headers 不是必须，但对你排查“CF 到底返回什么”非常有帮助
Map<String, String> buildImgHeaders() {
  if (kIsWeb) return const {};

  // 只要 Accept 就够用了（f=auto 时关键）
  final headers = <String, String>{
    'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
  };

  // 可选：给一个更像浏览器的 UA（不是硬要求）
  // 这里不用 dart:io 的 Platform，避免 Web 编译问题
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      headers['User-Agent'] =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) '
          'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 '
          'Mobile/15E148 Safari/604.1';
      break;
    case TargetPlatform.android:
      headers['User-Agent'] =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
          'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36';
      break;
    default:
    // 其他平台不强行伪装
      break;
  }

  return headers;
}

/// CHANGED: 获取本地文件 ImageProvider（Web 下永远返回 null）
ImageProvider? tryBuildFileImageProvider(String source) {
  return tryBuildFileImageProviderImpl(source);
}