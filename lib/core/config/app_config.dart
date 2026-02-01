import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  // =========================================================
  // 1. 读取编译参数 (--dart-define)
  // =========================================================

  static const String _flavorRaw = String.fromEnvironment(
      'FLAVOR',
      defaultValue: 'dev'
  );

  static const String _apiBaseRaw = String.fromEnvironment(
      'API_BASE',
      defaultValue: 'https://dev-api.joyminis.com'
    // 或者用本地调试: 'http://localhost:3000'
  );

  static const String _imgBaseRaw = String.fromEnvironment(
      'IMG_BASE',
      defaultValue: 'https://dev.joyminis.com'
    // 注意：Dev 环境默认指向网关代理，Prod环境才指向 img.joyminis.com
  );

  static const bool _logHttpRaw = bool.fromEnvironment(
      'LOG_HTTP',
      defaultValue: true
  );

  // =========================================================
  // 2. 公开 Getters (经过处理的)
  // =========================================================

  static String get flavor => _flavorRaw;
  static bool get logHttp => _logHttpRaw;
  static bool get isProd => _flavorRaw == 'prod';

  /// 获取处理过的 API 域名 (自动修正 Android 模拟器地址)
  static String get apiBaseUrl => _resolveLocalhost(_apiBaseRaw);

  /// 获取处理过的图片域名
  static String get imgBaseUrl => _resolveLocalhost(_imgBaseRaw);

  // =========================================================
  // 3. 工具方法：Android 模拟器 Localhost 修复
  // =========================================================
  static String _resolveLocalhost(String url) {
    // Web 端不需要处理，localhost 就是本机
    if (kIsWeb) return url;

    // 只有 Android 模拟器访问本机 localhost 需要转为 10.0.2.2
    if (Platform.isAndroid) {
      if (url.contains('localhost')) {
        return url.replaceFirst('localhost', '10.0.2.2');
      }
      if (url.contains('127.0.0.1')) {
        return url.replaceFirst('127.0.0.1', '10.0.2.2');
      }
    }
    return url;
  }
}