import 'dart:io';

import 'package:flutter/foundation.dart';

/// 统一入口：从构建参数读取
class Env {
  static const flavor   = String.fromEnvironment('FLAVOR',    defaultValue: 'dev');
  static const apiBase  = String.fromEnvironment('API_BASE',  defaultValue: 'http://10.0.2.2:3000'); // Android 模拟器本机
  static const logHttp  = bool.fromEnvironment('LOG_HTTP',    defaultValue: true);

  static String get apiBaseEffective {
    if(kIsWeb) return apiBase;
    if(apiBase.contains('localhost') || apiBase.contains('127.0.0.1')){
      if (Platform.isAndroid) return apiBase.replaceFirst('localhost', '10.0.2.2').replaceFirst('127.0.0.1', '10.0.2.2');
    }
    return apiBase;
  }
}