import 'dart:io';
import 'package:flutter/foundation.dart'; // 用于 kIsWeb
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// 统一返回的数据模型
class DeviceFingerprint {
  final String deviceId;    // 唯一标识 (Web端是生成的，App端是物理的)
  final String deviceModel; // 设备型号 (如 iPhone 15 / Chrome 120)
  final String platform;    // 平台名称 (ios/android/web)

  DeviceFingerprint({
    required this.deviceId,
    required this.deviceModel,
    required this.platform,
  });

  @override
  String toString() => '[$platform] $deviceModel ($deviceId)';
}

class DeviceUtils {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  // 内存缓存，避免每次请求都去读硬件/IO，提升性能
  static DeviceFingerprint? _cache;

  /// 【核心方法】外部只调这个
  static Future<DeviceFingerprint> getFingerprint() async {
    // 1. 如果有缓存，直接返回
    if (_cache != null) return _cache!;

    String deviceId = '';
    String deviceModel = '';
    String platform = '';

    try {
      if (kIsWeb) {
        // ============ Web 环境 ============
        platform = 'web';
        deviceId = await _getWebUniqueId();

        WebBrowserInfo webInfo = await _deviceInfoPlugin.webBrowserInfo;
        deviceModel = '${webInfo.browserName.name} on ${webInfo.platform}';

      } else {
        // ============ Native App 环境 ============
        // 1. 获取硬件 ID
        deviceId = await FlutterUdid.consistentUdid;

        // 2. 获取型号
        if (Platform.isAndroid) {
          platform = 'android';
          AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
          deviceModel = '${androidInfo.brand} ${androidInfo.model}';
        } else if (Platform.isIOS) {
          platform = 'ios';
          IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
          deviceModel = iosInfo.utsname.machine;
        } else {
          platform = 'other';
          deviceModel = 'Unknown Device';
        }
      }
    } catch (e) {
      // 兜底处理，防止风控模块崩溃导致 App 不可用
      deviceId = 'error-uuid-${const Uuid().v4()}';
      deviceModel = 'Error Device';
      platform = kIsWeb ? 'web-error' : 'native-error';
    }

    // 写入缓存
    _cache = DeviceFingerprint(
      deviceId: deviceId,
      deviceModel: deviceModel,
      platform: platform,
    );

    return _cache!;
  }

  /// Web 端专用：获取持久化 UUID
  static Future<String> _getWebUniqueId() async {
    const key = 'x_lucky_device_id';
    final prefs = await SharedPreferences.getInstance();

    // 尝试读取
    String? uuid = prefs.getString(key);

    // 如果没有（新设备/清空缓存），生成一个新的并保存
    if (uuid == null || uuid.isEmpty) {
      uuid = 'web-${const Uuid().v4()}';
      await prefs.setString(key, uuid);
    }

    return uuid;
  }
}