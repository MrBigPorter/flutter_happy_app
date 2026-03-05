import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 全局 API JSON 缓存管理器 (支持 Web WASM 双端融合)
/// 架构定位：Core/Infrastructure Layer
class ApiCacheManager {
  static const String _boxName = 'app_api_cache_box';
  static Box? _box;
  static SharedPreferences? _prefs;

  /// 1. 初始化引擎
  static Future<void> init() async {
    if (kIsWeb) {
      //  Web 端 (WASM) 专用：完美避开 Hive 崩溃，使用 SP 替代
      _prefs = await SharedPreferences.getInstance();
      debugPrint(' [ApiCacheManager] Web SharedPreferences Cache Opened.');
    } else {
      //  手机端：继续使用高性能的 Hive
      await Hive.initFlutter();
      _box = await Hive.openBox(_boxName);
      debugPrint(' [ApiCacheManager] Hive Cache Box Opened.');
    }
  }

  /// 2. 写入缓存
  static Future<void> setCache(String key, dynamic data) async {
    try {
      final String jsonString = jsonEncode(data);
      if (kIsWeb) {
        // Web 端加上前缀隔离，防止覆盖其他业务数据
        await _prefs?.setString('${_boxName}_$key', jsonString);
      } else {
        await _box?.put(key, jsonString);
      }
    } catch (e) {
      debugPrint(' [ApiCacheManager] Set Cache Error: $e');
    }
  }

  /// 3. 读取缓存 (极速瞬间返回)
  static dynamic getCache(String key) {
    try {
      final String? jsonString = kIsWeb
          ? _prefs?.getString('${_boxName}_$key')
          : _box?.get(key);

      if (jsonString != null && jsonString.isNotEmpty) {
        return jsonDecode(jsonString);
      }
      return null;
    } catch (e) {
      debugPrint(' [ApiCacheManager] Get Cache Error: $e');
      return null;
    }
  }

  /// 4. 清理特定缓存
  static Future<void> removeCache(String key) async {
    if (kIsWeb) {
      await _prefs?.remove('${_boxName}_$key');
    } else {
      await _box?.delete(key);
    }
  }

  /// 5. 清空所有接口缓存 (退出登录时调用)
  static Future<void> clearAll() async {
    if (kIsWeb) {
      // Web 端：只清除 API 相关的 keys，绝不影响用户登录状态 (Token)
      final keys = _prefs?.getKeys() ?? {};
      for (String key in keys) {
        if (key.startsWith(_boxName)) {
          await _prefs?.remove(key);
        }
      }
    } else {
      await _box?.clear();
    }
  }
}