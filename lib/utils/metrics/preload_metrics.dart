import 'dart:developer' as dev;

class PreloadMetrics {
  static final Set<String> _recordedIds = {};
  //  新增：存储预加载器发出的所有 URL，用于 UI 侧比对
  static final Set<String> _preloadedUrls = {};

  static int totalPreloads = 0;
  static int cacheHits = 0;
  static int cacheMisses = 0;

  // 1. 当 Preloader 启动时调用
  static void markAsPreloaded(String url) {
    _preloadedUrls.add(url);
    totalPreloads++;
  }

  // 2. 当 UI 渲染命中时
  static void recordHit(String url) {
    if (_recordedIds.contains(url)) return;
    _recordedIds.add(url);
    cacheHits++;
  }

  // 3. 当 UI 渲染未命中时 (这是调研的核心)
  static void recordMiss(String url, {double? reqWidth}) {
    if (_recordedIds.contains(url)) return;
    _recordedIds.add(url);
    cacheMisses++;
  }

  static double get hitRate => (cacheHits + cacheMisses) == 0 ? 0.0 : (cacheHits / (cacheHits + cacheMisses)) * 100;

  //  记得在进入聊天室或切换会话时清除，否则缓存的 ID 会干扰下一次统计
  static void reset() {
    _recordedIds.clear();
    _preloadedUrls.clear();
    totalPreloads = 0;
    cacheHits = 0;
    cacheMisses = 0;
  }
}