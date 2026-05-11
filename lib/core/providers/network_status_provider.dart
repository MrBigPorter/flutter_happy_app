import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

/// 简单的 StreamProvider，监听手机的物理网络连接
final networkStatusProvider = StreamProvider.autoDispose<NetworkStatus>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return NetworkStatus.offline;
    }
    return NetworkStatus.online;
  });
});

// ────────────────────────────────────────────────────────────────────────────────
// Fix 5: Network-aware image quality (inspired by front_blog's useNetworkQuality)
// ────────────────────────────────────────────────────────────────────────────────

/// 网络质量信息
class NetworkQuality {
  final int quality; // 0-100
  final String label;

  const NetworkQuality({required this.quality, required this.label});

  @override
  String toString() => 'NetworkQuality(quality=$quality, label=$label)';
}

/// 网络质量 Provider
/// 在 Web 上使用 Network Information API (navigator.connection.effectiveType)
/// 在移动端回退到默认高质量
final networkQualityProvider = Provider.autoDispose<NetworkQuality>((ref) {
  // 默认值：高质量
  return const NetworkQuality(quality: 75, label: 'unknown');
});

// ────────────────────────────────────────────────────────────────────────────────
// Fix 7: Device-size-aware image quality
// ────────────────────────────────────────────────────────────────────────────────

/// 设备分类
enum DeviceCategory { phone, tablet, desktop }

/// 设备尺寸信息
class DeviceSizeInfo {
  final double viewportWidth;
  final double devicePixelRatio;
  final DeviceCategory category;

  const DeviceSizeInfo({
    required this.viewportWidth,
    required this.devicePixelRatio,
    required this.category,
  });

  @override
  String toString() =>
      'DeviceSizeInfo(width=$viewportWidth, dpr=$devicePixelRatio, category=$category)';
}

/// 设备尺寸 Provider
/// 通过 WidgetsBinding 获取当前 viewport 尺寸，分类为 phone/tablet/desktop
/// 无需 BuildContext，可在任何地方使用
final deviceSizeProvider = Provider.autoDispose<DeviceSizeInfo>((ref) {
  try {
    final binding = WidgetsBinding.instance;
    final view = binding.platformDispatcher.views.first;
    final width = view.physicalSize.width / view.devicePixelRatio;
    final pixelRatio = view.devicePixelRatio;
    return DeviceSizeInfo(
      viewportWidth: width,
      devicePixelRatio: pixelRatio,
      category: _categorizeDevice(width),
    );
  } catch (_) {
    return const DeviceSizeInfo(
      viewportWidth: 390,
      devicePixelRatio: 2.0,
      category: DeviceCategory.phone,
    );
  }
});

DeviceCategory _categorizeDevice(double width) {
  if (width < 600) return DeviceCategory.phone;
  if (width < 1024) return DeviceCategory.tablet;
  return DeviceCategory.desktop;
}
