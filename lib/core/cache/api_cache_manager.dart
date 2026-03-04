import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 全局 API JSON 缓存管理器 (基于 Hive)
/// 架构定位：Core/Infrastructure Layer
class ApiCacheManager {
  static const String _boxName = 'app_api_cache_box';
  static late Box _box;

  /// 1. 初始化引擎
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    debugPrint(' [ApiCacheManager] Hive Cache Box Opened.');
  }


  /// 2. 写入缓存
  /// [key] 接口的唯一标识，如 'home_banners'
  /// [data] 可以是 List 或 Map (通常是 toJson() 后的结果)
  static Future<void> setCache(String key, dynamic data) async {
    try {
      // 为了绝对的类型安全，统一转成 JSON String 存储。
      // 虽然 Hive 支持存 Map，但在 Flutter 强类型下，存 String 再 decode 是最稳妥防崩溃的
      final String jsonString = jsonEncode(data);
      await _box.put(key, jsonString);
    } catch (e) {
      debugPrint(' [ApiCacheManager] Set Cache Error: $e');
    }
  }

  /// 3. 读取缓存 (极速瞬间返回)
  static dynamic getCache(String key) {
    try {
      final String? jsonString = _box.get(key);
      if (jsonString != null && jsonString.isNotEmpty) {
        return jsonDecode(jsonString);
      }
      return null;
    } catch (e) {
      debugPrint(' [ApiCacheManager] Get Cache Error: $e');
      return null;
    }
  }

  /// 4. 清理特定缓存 (如下拉刷新想强制清空时可用)
  static Future<void> removeCache(String key) async {
    await _box.delete(key);
  }

  /// 5. 清空所有接口缓存 (退出登录时调用)
  static Future<void> clearAll() async {
    await _box.clear();
  }
}