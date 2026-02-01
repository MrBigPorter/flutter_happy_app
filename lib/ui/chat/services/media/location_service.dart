import 'package:flutter/foundation.dart'; // 用于 debugPrint
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// 获取当前位置 (包含权限处理)
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 检查位置服务是否启用
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // 检查权限状态
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // 抛出带有特定关键字的错误，以便 UI 层捕获并弹窗
      return Future.error('Location permissions are permanently denied.');
    }

    // 获取高精度位置 (locationSettings 可选配置，提升速度或精度)
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// 逆地理编码 (经纬度 -> 文字地址)
  static Future<String> getAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        lat,
        lng,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;

        //  2. 优化：判断是否在中国境内 (简单判断)
        // 如果是国外地址，用逗号分隔；如果是国内，直接拼接
        bool isChina = (place.country == 'China' || place.isoCountryCode == 'CN');

        final List<String?> parts = [
          place.administrativeArea, // 省/直辖市 (e.g. 北京市)
          place.locality,           // 市 (e.g. 北京市 - 有时省市会重复，下面处理)
          place.subLocality,        // 区 (e.g. 朝阳区)
          place.thoroughfare,       // 街道 (e.g. 建国路)
          place.name                // 具体点 (e.g. 腾讯大厦)
        ];

        //  3. 智能去重与拼接
        // Set 用于去重，但为了保持顺序，我们手动过滤
        List<String> finalParts = [];
        for (var part in parts) {
          if (part != null && part.isNotEmpty && !finalParts.contains(part)) {
            finalParts.add(part);
          }
        }

        if (isChina) {
          // 中文模式：无缝拼接 "北京市朝阳区建国路"
          return finalParts.join('');
        } else {
          // 英文模式：逗号分隔 "San Francisco, CA, USA"
          return finalParts.join(', ');
        }
      }
    } catch (e) {
      debugPrint("Geocoding failed: $e");
    }

    // 兜底：如果解析失败，返回经纬度简写
    return "${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";
  }
}