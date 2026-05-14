import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/utils/image/image_preloader.dart';
import 'package:flutter_app/utils/image/image_cache_manager.dart';
import 'package:flutter_app/utils/image/responsive_image_service.dart';
import 'package:flutter_app/utils/image/performance_monitor.dart';
import 'package:flutter_app/utils/image/static_image_preload_config.dart';

/// 图片优化系统统一初始化器
/// 支持无context初始化，用于应用冷启动时的预加载
class ImageOptimizationInit {
  static final ImageOptimizationInit _instance = ImageOptimizationInit._internal();
  factory ImageOptimizationInit() => _instance;
  ImageOptimizationInit._internal();

  bool _initialized = false;
  bool _coreInitialized = false; // 核心组件初始化状态（无需context）
  late final ImagePreloader preloader;
  late final ImageCacheManager cacheManager;
  late final ResponsiveImageService responsiveService;
  late final ImagePerformanceMonitor performanceMonitor;
  late final StaticImagePreloadManager staticPreloadManager;

  /// 核心初始化（无需BuildContext）
  /// 用于应用冷启动时的早期初始化
  Future<void> initializeCore() async {
    if (_coreInitialized) return;

    debugPrint('[ImageOptimizationInit] Starting core initialization...');
    
    performanceMonitor = ImagePerformanceMonitor();
    await performanceMonitor.initialize();
    
    cacheManager = ImageCacheManager();
    await cacheManager.initialize();
    
    responsiveService = ResponsiveImageService();
    await responsiveService.initialize();
    
    preloader = ImagePreloader();
    
    staticPreloadManager = StaticImagePreloadManager();
    await staticPreloadManager.initialize();
    
    _coreInitialized = true;
    debugPrint('[ImageOptimizationInit] Core initialization completed.');
  }

  /// 完整初始化（需要BuildContext）
  /// 用于有context时的完整初始化
  Future<void> initialize(BuildContext context) async {
    if (_initialized) return;

    // 确保核心组件已初始化
    if (!_coreInitialized) {
      await initializeCore();
    }

    _initialized = true;
    debugPrint('[ImageOptimizationInit] Full initialization completed.');
  }

  /// 预加载静态关键图片
  /// 在应用冷启动时调用，无需等待页面数据
  Future<void> preloadStaticImages(BuildContext context) async {
    if (!_coreInitialized) {
      debugPrint('[ImageOptimizationInit] Core not initialized, skipping static preload');
      return;
    }

    try {
      final urlsToPreload = staticPreloadManager.getUrlsToPreload();
      if (urlsToPreload.isEmpty) {
        return;
      }


      // 分批预加载，避免阻塞主线程
      final batchSize = 3;
      for (var i = 0; i < urlsToPreload.length; i += batchSize) {
        final batch = urlsToPreload.sublist(
          i,
          i + batchSize < urlsToPreload.length ? i + batchSize : urlsToPreload.length,
        );
        
        try {
          await preloader.preloadUrls(batch, context);
          
          // 标记为已预加载
          for (final url in batch) {
            staticPreloadManager.markAsPreloaded(url);
          }
          
          debugPrint('[ImageOptimizationInit] Preloaded batch ${i ~/ batchSize + 1}/${(urlsToPreload.length / batchSize).ceil()}');
        } catch (e) {
          debugPrint('[ImageOptimizationInit] Failed to preload batch: $e');
        }
        
        // 给主线程一些时间处理UI
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      debugPrint('[ImageOptimizationInit] Static images preload completed');
    } catch (e) {
      debugPrint('[ImageOptimizationInit] Static images preload failed: $e');
    }
  }

  /// 检查是否已初始化
  bool get isCoreInitialized => _coreInitialized;
  bool get isInitialized => _initialized;

  /// 【核心方法】统一 URL 生成入口
  String generateResponsiveUrl({
    required String originalUrl,
    required double width,
    required double height,
    bool allowUpscaling = false,
  }) {
    if (!_coreInitialized) {
      debugPrint('[ImageOptimizationInit] Warning: Core not initialized, returning original URL');
      return originalUrl;
    }

    return responsiveService.generateImageUrl(
      originalUrl: originalUrl,
      logicalWidth: width,
      logicalHeight: height,
      allowUpscaling: allowUpscaling,
    );
  }

  /// 预加载图片列表
  Future<void> preloadImages(List<String> urls, BuildContext context) async {
    if (!_coreInitialized) {
      debugPrint('[ImageOptimizationInit] Core not initialized, skipping preload');
      return;
    }
    
    await preloader.preloadUrls(urls, context);
  }

  /// 获取系统状态信息
  Map<String, dynamic> getSystemStatus() {
    return {
      'coreInitialized': _coreInitialized,
      'fullInitialized': _initialized,
      'cacheManager': cacheManager.getStats(),
      'staticPreload': staticPreloadManager.getStats(),
      'config': StaticImagePreloadConfig.getConfigInfo(),
    };
  }
}
