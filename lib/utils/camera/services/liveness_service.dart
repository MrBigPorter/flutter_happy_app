import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:google_api_availability/google_api_availability.dart';
import '../../../app/page/id_scan_page.dart';
import '../camera_helper.dart';

class LivenessService {
  static const MethodChannel _channel = MethodChannel('com.porter.joyminis/liveness');

  /// 👤 活体检测
  static Future<bool?> start(BuildContext context, String sessionId) async {
    if (kDebugMode && !await _isPhysicalDevice()) return true;
    if (!await CameraHelper.ensureCameraPermission(context)) return false;

    try {
      final result = await _channel.invokeMethod('start', {
        'sessionId': sessionId,
        'region': 'us-east-1',
      });
      if (result is Map) return result['success'] == true;
      return false;
    } catch (e) {
      debugPrint("❌ 活体检测失败: $e");
      return false;
    }
  }

  /// 📸 文档扫描
  static Future<String?> scanDocument(BuildContext context) async {
    if (kDebugMode && !await _isPhysicalDevice()) return "mock_image_path.jpg";
    if (!await CameraHelper.ensureCameraPermission(context)) return null;

    try {
      // 1. Android GMS 环境初步预检
      if (Platform.isAndroid) {
        final availability = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
        debugPrint("Google Play Services: $availability");

        // 如果明确不支持，直接跳转自定义拍照页
        if (availability != GooglePlayServicesAvailability.success) {
          return await _switchToFlutterScanner(context);
        }
      }

      // 2. 尝试调用原生扫描 (在华为海外版上，这里极大概率会抛出 PlatformException)
      debugPrint("🚀 正在调起原生高级扫描...");
      final String? rawPath = await _channel.invokeMethod('scanDocument');

      // 3. 处理返回路径（兼容 file:// 前缀）
      if (rawPath != null && rawPath.isNotEmpty) {
        final cleanPath = rawPath.replaceFirst('file://', '').replaceFirst('content://', '');
        debugPrint("✅ 扫描成功: $cleanPath");
        return cleanPath;
      }
      return null;

    } on PlatformException catch (e) {
      // 🛡️ 关键处理：针对华为海外版“假支持”的降级逻辑
      // 捕获到原生代码中的 SCAN_INIT_FAILED 或任何初始化失败
      debugPrint("⚠️ 原生扫描不可用 (华为海外版兼容性): ${e.code}");
      debugPrint("🔄 自动切换至 Flutter 自定义拍照...");
      return await _switchToFlutterScanner(context);

    } catch (e) {
      debugPrint("❌ 扫描过程发生未知异常: $e");
      return await _switchToFlutterScanner(context); // 保底方案
    }
  }

  /// 🔄 统一跳转：Flutter 自定义拍照页面
  static Future<String?> _switchToFlutterScanner(BuildContext context) async {
    final camera = await CameraHelper.getBackCamera();
    return await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (c) => IDScanPage(cameraDescription: camera),
      ),
    );
  }

  /// 🔍 真机检测逻辑
  static Future<bool> _isPhysicalDevice() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) return (await deviceInfo.androidInfo).isPhysicalDevice;
      if (Platform.isIOS) return (await deviceInfo.iosInfo).isPhysicalDevice;
    } catch (_) {}
    return true;
  }
}