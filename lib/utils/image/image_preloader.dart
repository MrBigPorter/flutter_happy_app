import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/utils/image/image_cache_manager.dart';

/// 图片预加载器
/// 【修复】统一使用 ImageCacheManager 写入缓存，与 OptimizedImage 读取同一套缓存，
/// 预热数据对 OptimizedImage 真正有效（不再是写 CachedNetworkImage 缓存而渲染走另一套）。
class ImagePreloader {
  static final ImagePreloader _instance = ImagePreloader._internal();
  factory ImagePreloader() => _instance;
  ImagePreloader._internal();

  final Set<String> _preloadedUrls = {};
  static const int _maxConcurrentPreloads = 3;

  /// 预加载一批 URL 到 ImageCacheManager（内存 + 磁盘）。
  /// [context] 保留以兼容现有调用方，当前实现不再需要它。
  Future<void> preloadUrls(List<String> urls, BuildContext context) async {
    if (urls.isEmpty) return;

    final urlsToPreload = urls.where((u) => u.isNotEmpty && !_preloadedUrls.contains(u)).toList();
    if (urlsToPreload.isEmpty) return;

    final cacheManager = ImageCacheManager();
    final semaphore = _Semaphore(_maxConcurrentPreloads);
    final futures = <Future>[];

    for (final url in urlsToPreload) {
      futures.add(semaphore.run(() async {
        try {
          // 直接写入 ImageCacheManager —— OptimizedImage 读的就是这套缓存
          await cacheManager.getImageData(url);
          _preloadedUrls.add(url);
        } catch (_) {}
      }));
    }
    await Future.wait(futures);
  }

  Future<void> preloadCriticalPath(BuildContext context) async => debugPrint('[ImagePreloader] preloadCriticalPath: no static assets configured.');
  Map<String, dynamic> getStats() => {'preloadedCount': _preloadedUrls.length};
}

class _Semaphore {
  final int _max;
  int _current = 0;
  final _queue = <Completer<void>>[];
  _Semaphore(this._max);

  Future<T> run<T>(Future<T> Function() task) async {
    while (_current >= _max) {
      final c = Completer<void>();
      _queue.add(c);
      await c.future;
    }
    _current++;
    try { return await task(); } finally {
      _current--;
      if (_queue.isNotEmpty) _queue.removeAt(0).complete();
    }
  }
}