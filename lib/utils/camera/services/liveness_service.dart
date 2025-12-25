import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/utils/camera/camera_helper.dart';
import 'package:permission_handler/permission_handler.dart';

class LivenessService {
  // 1. 定义通信频道
  static const MethodChannel _channel = MethodChannel('com.joyminis.flutter_app/liveness');

  /// 对外暴露的方法：开始活体检测
  static Future<bool?> start(BuildContext context,String sessionId) async {
    final bool hasPermission = await CameraHelper.ensureCameraPermission(context);

    if (!hasPermission) {
      return false;
    }

    try {
      print("🚀 权限已获取，正在调起原生 AWS 界面...");

      final result = await _channel.invokeMethod('start', {
        'sessionId': sessionId,
        'region': 'us-east-1'
      });

      // 5. 解析结果
      // 安全转换：先转为 Map<dynamic, dynamic> 再取值
      if (result != null && result is Map) {
        final Map<dynamic, dynamic> data = result;
        final bool isSuccess = data['success'] == true; // 防止 null 导致 crash

        if (isSuccess) {
          print("🎉 原生采集完成，sessionId: ${data['sessionId']}");
        } else {
          String? error = data['error'];
          print("⚠️ 检测失败或取消：$error");
        }
        return isSuccess;
      }

      return false;

    } on PlatformException catch (e) {
      print("❌ 调用原生失败 (PlatformException): ${e.message}");
      return false;
    } catch (e) {
      print("❌ 发生未知错误: $e");
      return false;
    }
  }
}