import 'dart:io';
import 'package:flutter/foundation.dart'; // 🚀 必须引入 kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:google_api_availability/google_api_availability.dart';
import '../../../app/page/id_scan_page.dart';
import '../camera_helper.dart';

import 'web_liveness_iframe_stub.dart'
if (dart.library.html) 'web_liveness_iframe.dart';

class LivenessService {
  static const MethodChannel _channel = MethodChannel('com.porter.joyminis/liveness');

  static Future<bool?> start(BuildContext context, String sessionId) async {
    // -----------------------------------------------------------
    //  Web logic is completely separate and self-contained, using a dialog with an iframe to host the React app. This avoids any Platform checks or native code execution in the web environment, preventing crashes and ensuring a smooth user experience.
    // -----------------------------------------------------------
    if (kIsWeb) {
      debugPrint(" Web invironment: Launching web-based liveness check UI...");

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false, //  force user to complete or fail the check before closing
        builder: (ctx) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                WebLivenessIframe(sessionId: sessionId),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.of(ctx).pop(false), //  用户主动关闭视图，视为验证失败
                  ),
                ),
              ],
            )
          ),
        ),
      );

      return result ?? false;
    }

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
      debugPrint("活体检测失败: $e");
      return false;
    }
  }

  static Future<String?> scanDocument(BuildContext context) async {
    //  核心防爆：Web 端绝对不能碰 Platform，直接跳到网页相机 UI！
    if (kIsWeb) {
      debugPrint("Web 环境：调起网页版相机 UI...");
      return await _switchToFlutterScanner(context);
    }

    if (kDebugMode && !await _isPhysicalDevice()) return "mock_image_path.jpg";
    if (!await CameraHelper.ensureCameraPermission(context)) return null;

    try {
      if (Platform.isAndroid) {
        final availability = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
        if (availability != GooglePlayServicesAvailability.success) {
          return await _switchToFlutterScanner(context);
        }
      }

      final String? rawPath = await _channel.invokeMethod('scanDocument');
      if (rawPath != null && rawPath.isNotEmpty) {
        return rawPath.replaceFirst('file://', '').replaceFirst('content://', '');
      }
      return null;
    } on PlatformException catch (_) {
      return await _switchToFlutterScanner(context);
    } catch (e) {
      debugPrint(" 扫描过程发生未知异常: $e");
      return await _switchToFlutterScanner(context);
    }
  }

  static Future<String?> _switchToFlutterScanner(BuildContext context) async {
    final camera = await CameraHelper.getBackCamera();
    return await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (c) => IDScanPage(cameraDescription: camera)),
    );
  }

  static Future<bool> _isPhysicalDevice() async {
    if (kIsWeb) return false;
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) return (await deviceInfo.androidInfo).isPhysicalDevice;
      if (Platform.isIOS) return (await deviceInfo.iosInfo).isPhysicalDevice;
    } catch (_) {}
    return true;
  }
}