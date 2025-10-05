import 'package:collection/collection.dart';
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
/// - [raw]: The raw JSON data (should be a List)
/// - [fromJson]: A function that converts a Map to an object of type T
/// - Returns: A List of objects of type T

List<T> parseList<T>(
  dynamic raw,
  T Function(Map<String, dynamic> json) fromJson,
) {
  final list = raw as List;
  return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
}


/// Find the index of an item in a list that matches all key-value pairs in the target map
/// - [list]: The list to search through
/// - [value]: (Optional) Direct value to compare
/// - [where]: (Optional) A map of key-value pairs to match against each item's
/// - [test]: (Optional) A custom test function that takes an item and returns a boolean
/// - Returns: The index of the first matching item, or -1 if no match is found
/// - Note: If multiple criteria are provided, the priority is: test > value > where
/// - Example:
/// ```dart
/// final index = findIndex(users, where: {'id': 123, 'name':
/// 'John'});
/// final index2 = findIndex(users, value: targetUser);
/// final index3 = findIndex(users, test: (user) => user.id == 123);
/// ```
int findIndex<T>(List<T> list, T target){
  return list.indexWhere((item){
    /// If target is a Map, check if all key-value pairs match
    if (item == target) return true;

    /// Custom test function not provided in this version, but can be added if needed
    if(item is Map && target is Map){
      return MapEquality().equals(item, target);
    }

    /// Fallback: try to compare using toJson if available
    try{
      final itemMap = (item as dynamic).toJson() as Map<String, dynamic>;
      final targetMap = (target as dynamic).toJson() as Map<String, dynamic>;
      return const MapEquality().equals(itemMap, targetMap);
    }catch(_){
      return false;
    }
  });
}


/// 根据平台决定是否走代理：
/// - Web：走 http://127.0.0.1:5173/proxy?url=...
/// - iOS/Android：直接用原图（移动端没有浏览器 CORS 限制）
/// Decide whether to use a proxy based on the platform:
String proxied(String imageUrl, {String base = 'http://127.0.0.1:5173'}) {
  if (!kIsWeb) return imageUrl;
  return '$base/proxy?url=${Uri.encodeComponent(imageUrl)}';
}
