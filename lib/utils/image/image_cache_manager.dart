import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:synchronized/synchronized.dart';

class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;

  ImageCacheManager._internal() {
    // 只有在非 Web 环境下才初始化磁盘缓存，避免 path_provider 报错
    if (!kIsWeb) {
      _diskCacheManager = CacheManager(Config(
        _diskCacheKey,
        stalePeriod: _diskCacheStalePeriod,
        maxNrOfCacheObjects: _maxDiskCacheObjects,
        repo: JsonCacheInfoRepository(databaseName: _diskCacheKey),
        fileService: HttpFileService(),
      ));
      //debugPrint('[ImageCacheManager] L2 Disk Cache Initialized (Native)');
    } else {
      //debugPrint('[ImageCacheManager] Running on Web, L2 Disk Cache disabled');
    }
  }

  final _memoryCache = <String, _MemoryCacheEntry>{};
  final _memoryCacheLock = Lock();
  static const int _maxMemoryCacheSize = 100;
  static const int _maxMemoryCacheBytes = 100 * 1024 * 1024; // 100MB

  CacheManager? _diskCacheManager;
  static const String _diskCacheKey = 'lucky_image_cache';
  static const Duration _diskCacheStalePeriod = Duration(days: 7);
  static const int _maxDiskCacheObjects = 200;

  int _memoryHitCount = 0;
  int _diskHitCount = 0;
  int _totalRequestCount = 0;

  Future<void> initialize() async => debugPrint('[ImageCacheManager] Ready.');

  Future<Uint8List> getImageData(String url, {
    Map<String, String>? headers,
    bool skipMemoryCache = false,
    bool skipDiskCache = false,
  }) async {
    _totalRequestCount++;

    if (!skipMemoryCache) {
      final memoryData = await _getFromMemoryCache(url);
      if (memoryData != null) {
        _memoryHitCount++;
        return memoryData;
      }
    }

    if (!kIsWeb && !skipDiskCache) {
      final diskData = await _getFromDiskCache(url);
      if (diskData != null) {
        _diskHitCount++;
        _setToMemoryCache(url, diskData);
        return diskData;
      }
    }

    final networkData = await _fetchFromNetwork(url, headers: headers);

    if (!kIsWeb) unawaited(_setToDiskCache(url, networkData));
    _setToMemoryCache(url, networkData);

    return networkData;
  }

  Future<Uint8List> _fetchFromNetwork(String url, {Map<String, String>? headers}) async {
    try {
      if (kIsWeb) {
        debugPrint('[ImageCacheManager] Fetching image from network: $url');
        final request = await HttpFileService().get(url, headers: headers);

        // 【核心修复】：完整读取整个数据流，解决第二张图（大图）被截断的问题
        final List<int> allBytes = [];
        await for (final chunk in request.content) {
          allBytes.addAll(chunk);
        }
        final uint8List = Uint8List.fromList(allBytes);

        debugPrint('[ImageCacheManager] Raw data received: ${uint8List.length} bytes');

        // 【核心修复】: 将 50 字节检查改为只记录日志，不再抛出异常
        // 有些合法的图标/小图片可能小于 50 字节，不应该因此抛出异常
        if (uint8List.length < 50) {
          debugPrint('[ImageCacheManager] Warning: Data small ($url): ${uint8List.length} bytes');
          // 不再抛出异常，而是继续处理
        }

        if (uint8List.length > 20) {
          final head = String.fromCharCodes(uint8List.take(20));
          if (head.contains('<!DOC') || head.contains('<html') || head.contains('error')) {
            // 记录日志但继续返回数据，让上层解码器处理
            debugPrint('[ImageCacheManager] Warning: Possible HTML response ($url)');
            // 不再抛出异常，而是返回数据让上层处理
          }
        }

        debugPrint('[ImageCacheManager] Successfully fetched image data ($url): ${uint8List.length} bytes');
        return uint8List;
      } else {
        // ... 原生端逻辑保持不变
        final stream = _diskCacheManager!.getFileStream(url, headers: headers);
        final completer = Completer<Uint8List>();
        stream.listen(
              (fileInfo) { if (fileInfo is FileInfo) completer.complete(fileInfo.file.readAsBytes()); },
          onError: completer.completeError,
          cancelOnError: true,
        );
        return await completer.future;
      }
    } catch (e) {
      debugPrint('[ImageCacheManager] Network error: $e');
      rethrow;
    }
  }

  Future<Uint8List?> _getFromMemoryCache(String url) async => _memoryCacheLock.synchronized(() {
    final entry = _memoryCache[url];
    if (entry == null) return null;
    entry.lastAccessTime = DateTime.now().millisecondsSinceEpoch;
    return entry.data;
  });

  void _setToMemoryCache(String url, Uint8List data) => _memoryCacheLock.synchronized(() {
    if (_memoryCache.length >= _maxMemoryCacheSize) _cleanupMemoryCache();
    _memoryCache[url] = _MemoryCacheEntry(data: data, size: data.length, lastAccessTime: DateTime.now().millisecondsSinceEpoch);
  });

  void _cleanupMemoryCache() {
    final entries = _memoryCache.entries.toList()..sort((a, b) => a.value.lastAccessTime.compareTo(b.value.lastAccessTime));
    if (entries.isNotEmpty) _memoryCache.remove(entries.first.key);
  }

  int _calculateMemoryCacheSize() => _memoryCache.values.fold(0, (sum, entry) => sum + entry.size);
  Future<Uint8List?> _getFromDiskCache(String url) async {
    if (kIsWeb || _diskCacheManager == null) return null;
    try {
      final file = await _diskCacheManager!.getFileFromCache(url);
      return await file?.file.readAsBytes();
    } catch (e) { return null; }
  }
  Future<void> _setToDiskCache(String url, Uint8List data) async {
    if (kIsWeb || _diskCacheManager == null) return;
    try { await _diskCacheManager!.putFile(url, data); } catch (e) { }
  }

  Map<String, dynamic> getStats() => { 'total': _totalRequestCount, 'memoryHits': _memoryHitCount, 'isWeb': kIsWeb };
}

class _MemoryCacheEntry {
  final Uint8List data;
  final int size;
  int lastAccessTime;
  _MemoryCacheEntry({required this.data, required this.size, required this.lastAccessTime});
}