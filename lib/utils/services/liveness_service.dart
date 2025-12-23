import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class LivenessService {
  // 1. 定义通信频道
  static const MethodChannel _channel = MethodChannel('com.joyminis.flutter_app/liveness');

  static Future<bool> _requestCameraPermission() async {
    // 1. 获取当前状态
    var status = await Permission.camera.status;

    // 2. 如果还没请求过，或者受限，发起请求
    if (status.isDenied || status.isLimited) {
      // 这里的 request() 才是真正弹窗的时刻！
      // 注意：iOS 必须在 Podfile 配置 PERMISSION_CAMERA=1 才会弹窗
      status = await Permission.camera.request();
    }

    // 3. 永久拒绝 (用户之前点过“不允许”)
    if (status.isPermanentlyDenied) {
      print("❌ 用户永久拒绝了相机权限，正在跳转设置页...");
      // 帮用户跳到设置页
      await openAppSettings();
      return false;
    }

    if (!status.isGranted) {
      print("❌ 相机权限未获得");
      return false;
    }

    return true;
  }

  /// 对外暴露的方法：开始活体检测
  static Future<bool?> start(String sessionId) async {
    final bool hasPermission = await _requestCameraPermission();

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