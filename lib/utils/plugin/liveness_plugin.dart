import 'package:flutter/services.dart';

class LivenessPlugin {
  // 🔑 语法点 1：定义频道 (Channel)
  // 口诀：这个字符串就是"电话号码"，Android/iOS 必须一字不差！
  // 建议格式：包名/功能名
  static const MethodChannel _channel = MethodChannel('com.joyminis.flutter_app/liveness');

  /// 对外暴露的方法：开始活体检测
  static Future<bool> start(String sessionId) async {
    try {
      print("Flutter: 准备呼叫原生端，SessionId: $sessionId");

      // 🔑 语法点 2：调用方法 (invokeMethod)
      // 参数 1："start" 是暗号 (Method Name)
      // 参数 2：Map 是要传的数据 (Arguments)
      // await 是必须的，因为跨端通信是异步的
      final bool result = await _channel.invokeMethod('start', {
        'sessionId': sessionId,
        'region': 'us-east-1'
      });

      return result; // 如果原生返回 true，这里就拿到 true

    } on PlatformException catch (e) {
      // 🔑 语法点 3：捕获原生抛出的错误 (result.error)
      print("Flutter: 原生端报错了 -> ${e.message}");
      return false;
    }
  }
}