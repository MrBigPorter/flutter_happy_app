import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_app/core/providers/network_status_provider.dart';
import 'package:flutter_app/utils/image/image_cache_manager.dart';
import 'package:flutter_app/utils/image/performance_monitor.dart';
import 'package:flutter_app/utils/image/responsive_image_service.dart';

/// 全局 LRU 缓存：解码后的 blurhash data URL
/// 避免在 Tab 切换时重复解码（灵感来自 front_blog 的 blurhashCache）
final Map<String, String> _blurhashCache = {};
const int _blurhashCacheMax = 100;

String? _getCachedBlurhash(String hash) => _blurhashCache[hash];
void _setCachedBlurhash(String hash, String dataUrl) {
  if (_blurhashCache.length >= _blurhashCacheMax) {
    // LRU eviction: remove first entry
    final key = _blurhashCache.keys.first;
    _blurhashCache.remove(key);
  }
  _blurhashCache[hash] = dataUrl;
}

/// 优化图片组件 - 封装新的图片缓存系统
/// 功能：集成四级缓存、性能监控、响应式图片服务
///
/// BlurHash 渲染模式（灵感来自 front_blog）：
/// - BlurHash 作为 overlay 渲染在图片之上（不是 placeholder）
/// - 图片始终以全透明度渲染在底层
/// - 图片加载完成后，BlurHash overlay 以 300ms 淡出
/// - 消除 placeholder → 图片切换时的闪烁
class OptimizedImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableMonitoring;
  final String componentName;
  final String? qualityPreset;
  final bool enableResponsive;
  final Map<String, dynamic>? metadata;
  final String? blurhash;
  final int? networkQuality; // 0-100, from networkQualityProvider (Fix 5)
  final DeviceCategory? deviceCategory; // from deviceSizeProvider (Fix 7)

  const OptimizedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.enableMonitoring = true,
    this.componentName = 'OptimizedImage',
    this.qualityPreset = 'medium',
    this.enableResponsive = true,
    this.metadata,
    this.blurhash,
    this.networkQuality,
    this.deviceCategory,
  });

  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage> {
  late String _optimizedUrl;
  late ImageCacheManager _cacheManager;
  // late ImagePerformanceMonitor _performanceMonitor;
  String? _eventId;
  DateTime? _startTime;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isImageLoaded = false; // NEW: for blurhash overlay fade-out
  Uint8List? _imageData;

  @override
  void initState() {
    super.initState();
    _cacheManager = ImageCacheManager();
    // _performanceMonitor = ImagePerformanceMonitor();
    _setupAndLoad(widget.url);
  }

  @override
  void didUpdateWidget(OptimizedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.width != widget.width ||
        oldWidget.height != widget.height) {
      _setupAndLoad(widget.url);
    }
  }

  /// 生成优化 URL 并开始加载
  void _setupAndLoad(String url) {
    // 生成优化后的URL
    _optimizedUrl = url;
    if (widget.enableResponsive && widget.width != null && widget.width! > 0) {
      try {
        // 计算最终 quality：结合 qualityPreset、networkQuality、deviceCategory
        String effectiveQuality = widget.qualityPreset ?? 'medium';
        if (widget.networkQuality != null || widget.deviceCategory != null) {
          effectiveQuality = _computeEffectiveQuality(
            preset: effectiveQuality,
            networkQuality: widget.networkQuality,
            deviceCategory: widget.deviceCategory,
          );
        }

        _optimizedUrl = ResponsiveImageService().generateImageUrl(
          originalUrl: url,
          logicalWidth: widget.width!,
          logicalHeight: widget.height ?? widget.width! * 0.75,
          qualityPreset: effectiveQuality,
          allowUpscaling: false,
          deviceCategory: widget.deviceCategory,
        );
      } catch (e) {
        debugPrint('[OptimizedImage] Responsive URL generation failed: $e');
      }
    }

    // 重置状态
    _imageData = null;
    _hasError = false;
    _isImageLoaded = false;

    // 开始性能监控
    if (widget.enableMonitoring) {
      _startTime = DateTime.now();
      // _eventId = _performanceMonitor.startImageLoad(
      //   url: _optimizedUrl,
      //   component: widget.componentName,
      //   source: ImageLoadSource.network,
      //   metadata: {
      //     'width': widget.width,
      //     'height': widget.height,
      //     'fit': widget.fit.toString(),
      //     'originalUrl': url,
      //     'optimizedUrl': _optimizedUrl,
      //   },
      // );
    }

    _loadImage();
  }

  /// 计算最终质量：取 networkQuality 和 deviceCategory 中更保守的值
  String _computeEffectiveQuality({
    required String preset,
    int? networkQuality,
    DeviceCategory? deviceCategory,
  }) {
    // 预设基础值
    int baseQuality;
    switch (preset) {
      case 'high':
        baseQuality = 90;
        break;
      case 'low':
        baseQuality = 60;
        break;
      case 'original':
        baseQuality = 100;
        break;
      case 'medium':
      default:
        baseQuality = 80;
        break;
    }

    // 设备分类限制
    int deviceLimit = 100;
    if (deviceCategory != null) {
      switch (deviceCategory) {
        case DeviceCategory.phone:
          deviceLimit = 80;
          break;
        case DeviceCategory.tablet:
          deviceLimit = 85;
          break;
        case DeviceCategory.desktop:
          deviceLimit = 90;
          break;
      }
    }

    // 网络质量限制
    final int networkLimit = networkQuality ?? 100;

    // 取三者中最保守的
    final int finalQuality = [
      baseQuality,
      deviceLimit,
      networkLimit,
    ].reduce(min);

    // 映射回 qualityPreset 字符串
    if (finalQuality >= 90) return 'high';
    if (finalQuality >= 70) return 'medium';
    return 'low';
  }

  Future<void> _loadImage() async {
    if (_optimizedUrl.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      final imageData = await _cacheManager.getImageData(
        _optimizedUrl,
        skipMemoryCache: false,
        skipDiskCache: false,
      );
      
      if (mounted) {
        setState(() {
          _imageData = imageData;
          _isLoading = false;
          // 标记图片已加载，触发 blurhash overlay 淡出
          _isImageLoaded = true;
        });
        
        // 记录成功
        if (widget.enableMonitoring && _eventId != null && _startTime != null) {
          final duration = DateTime.now().difference(_startTime!);
          // _performanceMonitor.recordLoadSuccess(
          //   eventId: _eventId!,
          //   loadDuration: duration,
          //   byteSize: imageData.length,
          //   cacheLevel: ImageCacheLevel.memory,
          // );
        }
      }
    } catch (e) {
      debugPrint('[OptimizedImage] Failed to load image:');
      debugPrint('  URL: $_optimizedUrl');
      debugPrint('  Original URL: ${widget.url}');
      debugPrint('  Error: $e');
      
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          // 即使加载失败，也标记为已加载（隐藏 blurhash overlay）
          _isImageLoaded = true;
        });
        
        if (widget.enableMonitoring && _eventId != null && _startTime != null) {
          final duration = DateTime.now().difference(_startTime!);
          // _performanceMonitor.recordLoadFailure(
          //   eventId: _eventId!,
          //   error: e.toString(),
          //   loadDuration: duration,
          // );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget container = Container(
      width: widget.width,
      height: widget.height,
      decoration: widget.borderRadius != null
          ? BoxDecoration(
              borderRadius: widget.borderRadius,
            )
          : null,
      child: _buildContent(),
    );
    
    if (widget.borderRadius != null) {
      container = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: container,
      );
    }
    
    return container;
  }

  Widget _buildContent() {
    // 如果有 blurhash，使用 overlay 模式（front_blog 风格）
    if (widget.blurhash != null && widget.blurhash!.isNotEmpty) {
      return _buildBlurhashOverlayContent();
    }

    // 无 blurhash：传统模式
    if (_isLoading) {
      return widget.placeholder ?? _buildDefaultPlaceholder();
    }
    
    if (_hasError) {
      return widget.errorWidget ?? _buildDefaultErrorWidget();
    }
    
    if (_imageData != null) {
      return Image.memory(
        _imageData!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('[OptimizedImage] Image decode error: $error');
          return widget.errorWidget ?? _buildDefaultErrorWidget();
        },
      );
    }
    
    return widget.placeholder ?? _buildDefaultPlaceholder();
  }

  /// front_blog 风格的 BlurHash overlay 模式
  /// - 图片始终渲染在底层（全透明度）
  /// - BlurHash 作为 overlay 渲染在图片之上
  /// - 图片加载完成后，BlurHash 以 300ms 淡出
  Widget _buildBlurhashOverlayContent() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 底层：始终渲染图片（如果有）
        // 注意：不传 width/height，因为 Stack(fit: StackFit.expand) 已强制约束
        if (_imageData != null)
          Image.memory(
            _imageData!,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          )
        else
          // 图片未加载时显示灰色背景
          Container(color: Colors.grey[200]),

        // 上层：BlurHash overlay（淡出效果）
        if (!_isImageLoaded)
          AnimatedOpacity(
            opacity: _isImageLoaded ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            onEnd: () {
              // 淡出完成后，可以移除 blurhash widget（可选）
              if (mounted) setState(() {});
            },
            child: BlurHash(
              hash: widget.blurhash!,
              imageFit: widget.fit,
              color: Colors.grey.shade200,
            ),
          ),
      ],
    );
  }

  /// 默认占位符
  Widget _buildDefaultPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
    );
  }

  /// 默认错误组件
  Widget _buildDefaultErrorWidget() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey[400],
          size: min(widget.width ?? 40, widget.height ?? 40) * 0.5,
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (widget.enableMonitoring && _eventId != null && _startTime != null) {
      final duration = DateTime.now().difference(_startTime!);
      if (duration > const Duration(seconds: 10) && _isLoading) {
        // _performanceMonitor.recordLoadFailure(
        //   eventId: _eventId!,
        //   error: 'Image load timeout (${duration.inSeconds}s)',
        //   loadDuration: duration,
        // );
      }
    }
    
    super.dispose();
  }
}

/// 优化图片组件的便捷工厂方法
class OptimizedImageFactory {
  /// 创建轮播图优化的图片组件
  static Widget banner({
    required String url,
    required double width,
    required double height,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    String? blurhash,
    int? networkQuality,
    DeviceCategory? deviceCategory,
  }) {
    return OptimizedImage(
      url: url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      borderRadius: borderRadius,
      componentName: 'SwiperBanner',
      qualityPreset: 'medium',
      enableResponsive: true,
      blurhash: blurhash,
      networkQuality: networkQuality,
      deviceCategory: deviceCategory,
    );
  }

  /// 创建商品图片优化的图片组件
  static Widget product({
    required String url,
    required double width,
    double? height,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(4.0)),
    String? blurhash,
    int? networkQuality,
    DeviceCategory? deviceCategory,
  }) {
    return OptimizedImage(
      url: url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      borderRadius: borderRadius,
      componentName: 'ProductImage',
      qualityPreset: 'medium',
      enableResponsive: true,
      blurhash: blurhash,
      networkQuality: networkQuality,
      deviceCategory: deviceCategory,
    );
  }

  /// 创建头像优化的图片组件
  static Widget avatar({
    required String url,
    required double size,
    int? networkQuality,
    DeviceCategory? deviceCategory,
  }) {
    return ClipOval(
      child: OptimizedImage(
        url: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        componentName: 'Avatar',
        qualityPreset: 'low',
        enableResponsive: true,
        networkQuality: networkQuality,
        deviceCategory: deviceCategory,
      ),
    );
  }

  /// 创建图标优化的图片组件
  static Widget icon({
    required String url,
    required double size,
    Color? backgroundColor,
  }) {
    return Container(
      width: size,
      height: size,
      color: backgroundColor,
      child: OptimizedImage(
        url: url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        componentName: 'Icon',
        qualityPreset: 'original',
        enableResponsive: false,
      ),
    );
  }
}

/// 优化图片组件的配置
class OptimizedImageConfig {
  static const BoxFit defaultFit = BoxFit.cover;
  static const String defaultComponentName = 'OptimizedImage';
  static const String defaultQualityPreset = 'medium';
  static const bool defaultEnableMonitoring = true;
  static const bool defaultEnableResponsive = true;

  static const Map<String, OptimizedImageTypeConfig> typeConfigs = {
    'banner': OptimizedImageTypeConfig(
      qualityPreset: 'high',
      enableResponsive: true,
      fit: BoxFit.cover,
    ),
    'product': OptimizedImageTypeConfig(
      qualityPreset: 'medium',
      enableResponsive: true,
      fit: BoxFit.cover,
    ),
    'avatar': OptimizedImageTypeConfig(
      qualityPreset: 'low',
      enableResponsive: true,
      fit: BoxFit.cover,
    ),
    'icon': OptimizedImageTypeConfig(
      qualityPreset: 'original',
      enableResponsive: false,
      fit: BoxFit.contain,
    ),
  };
}

/// 优化图片类型配置
class OptimizedImageTypeConfig {
  final String qualityPreset;
  final bool enableResponsive;
  final BoxFit fit;

  const OptimizedImageTypeConfig({
    required this.qualityPreset,
    required this.enableResponsive,
    required this.fit,
  });
}
