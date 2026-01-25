import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/core/models/page_request.dart';


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

/// Parse a paginated response into a PageResult object
/// - [raw]: The raw JSON data (should be a Map with pagination info)
/// - [fromJson]: A function that converts a Map to an object of type T
/// - Returns: A PageResult containing a list of objects of type T and pagination details
/// - Expected JSON structure:
/// ```json
/// {
///  "list": [ ... ], // List of items
///  "total": 100, // Total number of items
///  "current": 1, // Current page number
///  "count": 10, // Number of items in the current page
///  "size": 10 // Page size
///  }
/// ```
PageResult<T> parsePageResponse<T>(
  dynamic raw,
  T Function(Map<String, dynamic> json) fromJson,
) {
  final map = raw as Map<String, dynamic>;
  return PageResult<T>(
    list: parseList<T>(map['list'], fromJson),
    total: map['total'] ?? 0,
    page: map['page'] ?? 1,
    count: map['count'] ?? 0,
    pageSize: map['pageSize'] ?? 10,
  );
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
String proxied(String imageUrl) {
  return imageUrl;
}

/// View related utilities
/// - view: The current FlutterView
/// - mq: MediaQueryData from the current view
/// - statusBarHeight: Height of the status bar
/// - bottomBarHeight: Height of the bottom bar (e.g., home indicator area)
/// - dpr: Device pixel ratio
/// - logicalSize: Logical size of the view (in logical pixels)
/// Usage:
/// ```dart
/// final statusBarHeight = ViewUtils.statusBarHeight;
/// final dpr = ViewUtils.dpr;
/// final logicalSize = ViewUtils.logicalSize;
/// ```
class ViewUtils {
  static FlutterView get view => PlatformDispatcher.instance.implicitView ?? PlatformDispatcher.instance.views.first;
  static MediaQueryData get mq => MediaQueryData.fromView(view);

  static double get statusBarHeight => mq.padding.top;
  static double get bottomBarHeight => mq.padding.bottom;
  static double get dpr => view.devicePixelRatio;
  static Size get logicalSize => view.physicalSize / dpr;
}


/// Bind a ScrollController to track scroll progress (0.0 to 1.0)
/// - [ctl]: The ScrollController to bind
/// - Returns: A tuple containing:
///  - progress: A ValueNotifier'<'double'>' that updates with scroll progress
///  - unbind: A VoidCallback to unbind the listener and dispose the notifier
///  Usage:
///  final (progress, unbind) = bindScrollProgress(scrollController);
///  // Use progress.value to get current scroll progress
///  // Call unbind() when done to clean up
///  ```
({ValueNotifier<double> progress, VoidCallback unbind}) bindScrollProgress(ScrollController ctl){
  final progress = ValueNotifier<double>(0.0);

  void onScroll(){
    if(!ctl.hasClients) return;
    final pos = ctl.position;
    final p = (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);
    progress.value = p;
  }

  ctl.addListener(onScroll);
  onScroll();

  return (
    progress: progress,
    unbind: (){
      ctl.removeListener(onScroll);
      progress.dispose();
    }
  );
}


/// Get platform-specific scroll physics
/// - [alwaysScrollable]: Whether the scroll view should always be scrollable
/// - Returns: Appropriate ScrollPhysics for the current platform
/// Usage:
/// final physics = platformScrollPhysics(alwaysScrollable: true);
/// ```
ScrollPhysics platformScrollPhysics({bool alwaysScrollable = true, bool webBounce = true,}) {
  ScrollPhysics base;
  if(kIsWeb){
    base = webBounce ? const BouncingScrollPhysics() : const ClampingScrollPhysics();
  } else {
    switch (defaultTargetPlatform){
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        base = const BouncingScrollPhysics();
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        base = const ClampingScrollPhysics();
        break;
      }
  }

  return alwaysScrollable ? const AlwaysScrollableScrollPhysics().applyTo(base) : base;
}


/// JSON number conversion utilities
class JsonNumConverter {
  static double toDouble(Object? v, {double fallback = 0}) {
    if (v == null) return fallback;

    if (v is num) return v.toDouble();
    if (v is String) {
      return double.tryParse(v) ?? fallback;
    }
    return fallback;
  }

  static int toInt(Object? v, {int fallback = 0}) {
    if (v == null) return fallback;

    if (v is int) return v;
    if (v is num) return v.toInt();

    if (v is String) {
      final asInt = int.tryParse(v);
      if (asInt != null) return asInt;

      final asDouble = double.tryParse(v);
      if (asDouble != null) return asDouble.toInt();
    }
    return fallback;
  }
}

/// Pagination utilities
/// - totalPages: Calculate total number of pages given total items and page size
/// - hasMore: Determine if there are more pages available
int totalPages(int total, int pageSize) => (total / pageSize).ceil();
bool hasMore(int total, int page, int pageSize){
  final pages = totalPages(total, pageSize);
  return page < pages;
}

int timeToInt(dynamic v) {
  if (v == null) return DateTime.now().millisecondsSinceEpoch;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is DateTime) return v.millisecondsSinceEpoch;
  if (v is String) {
    final n = int.tryParse(v);
    if (n != null) return n;
    final dt = DateTime.tryParse(v);
    if (dt != null) return dt.millisecondsSinceEpoch;
  }
  // 兜底：别把奇怪对象写进 DB
  return DateTime.now().millisecondsSinceEpoch;
}