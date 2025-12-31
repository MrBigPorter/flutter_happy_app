import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraHelper {
  // 只负责搞定权限 (权限关)
  /// 检查并请求相机权限。
  /// 如果用户永久拒绝，会自动弹窗引导去设置。
  /// 返回: true (有权限), false (无权限/被拒绝)
  static Future<bool> ensureCameraPermission(BuildContext context) async {
    // 1. 获取当前状态
    var status = await Permission.camera.status;

    // 2. 如果还没请求过，或者受限，发起请求
    if (status.isDenied || status.isLimited) {
      status = await Permission.camera.request();
    }

    // 3. 永久拒绝 (用户之前点过“不允许”)
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showOpenSettingsDialog(context);
      }
      return false;
    }
    return status.isGranted;
  }

  // 只负责搞定硬件 (硬件关)
  /// 获取后置摄像头 (不负责查权限，假设你已经有权限了)
  /// 返回: CameraDescription? (找不到返回 null)
  static Future<CameraDescription?> getBackCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return null;

      // 找后置摄像头,没有就返回第一个
      return cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
    } catch (e) {
      return null;
    }
  }

  // 方法三：一键组合拳 (懒人专用)
  /// 先查权限，再拿相机，一步到位。
  static Future<CameraDescription?> pickBackCamera(BuildContext context) async {
    // 1. 先搞定权限
    final hasPermission = await ensureCameraPermission(context);
    if (!hasPermission) return null;

    // 2. 再拿摄像头
    return await getBackCamera();
  }

// 私有辅助方法：弹窗引导
  static void _showOpenSettingsDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Camera permission required'),
          content: const Text('Please go to the settings page and enable camera permissions to continue using the relevant functions.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              child: const Text('Go to Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
