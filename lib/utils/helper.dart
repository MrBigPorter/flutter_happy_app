import 'package:flutter/foundation.dart';

/// check if an object is null or empty
extension NullOrEmpty on Object? {
  bool get isNullOrEmpty => switch (this) {
    null => true,

    /// ""、"   "、"0" 都算空 empty String or "0" is considered empty
    String s => s.trim().isEmpty || int.tryParse(s.trim()) == 0,

    /// <= 0 视为无效时间戳 <= 0 is considered invalid timestamp
    num n => n <= 0,

    /// List、Set、Map 都有 isEmpty 方法 List, Set and Map all have isEmpty method
    Iterable i => i.isEmpty,
    Map m => m.isEmpty,
    _ => false,
  };

  bool get isNotNullOrEmpty => !isNullOrEmpty;
}

/// Parse a list of JSON objects into a list of Dart objects using the provided fromJson function
List<T> parseList<T>(
  dynamic raw,
  T Function(Map<String, dynamic> json) fromJson,
) {
  final list = raw as List;
  return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
}

/// 根据平台决定是否走代理：
/// - Web：走 http://127.0.0.1:5173/proxy?url=...
/// - iOS/Android：直接用原图（移动端没有浏览器 CORS 限制）
/// Decide whether to use a proxy based on the platform:
String proxied(String imageUrl, {String base = 'http://127.0.0.1:5173'}) {
  if (!kIsWeb) return imageUrl;
  return '$base/proxy?url=${Uri.encodeComponent(imageUrl)}';
}
