import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/core/providers/network_status_provider.dart';
import 'package:flutter_app/utils/media/remote_url_builder.dart';

class ResponsiveImageService {
  static final ResponsiveImageService _instance = ResponsiveImageService._internal();
  factory ResponsiveImageService() => _instance;
  ResponsiveImageService._internal();

  double? _devicePixelRatio;

  Future<void> initialize() async {
    final binding = WidgetsFlutterBinding.ensureInitialized();
    _devicePixelRatio = binding.platformDispatcher.views.first.devicePixelRatio;
  }

  String generateImageUrl({
    required String originalUrl,
    required double logicalWidth,
    required double logicalHeight,
    String? qualityPreset = 'medium',
    bool allowUpscaling = false,
    Map<String, String>? additionalParams,
    DeviceCategory? deviceCategory, // NEW: 设备感知的宽度阶梯
  }) {
    if (originalUrl.isEmpty) return originalUrl;

    // 检查URL是否已经包含CDN处理参数
    if (_isAlreadyOptimized(originalUrl)) {
      return originalUrl;
    }

    final uri = Uri.tryParse(originalUrl);
    if (uri == null) {
      return originalUrl;
    }

    // 设备感知的宽度阶梯（Fix 7）
    // 不同设备类别使用不同的宽度阶梯，避免手机请求过大图片、桌面请求过小图片
    double targetW = _computeTargetWidth(logicalWidth, deviceCategory);

    final dpr = _devicePixelRatio ?? 2.0;

    // 计算物理像素尺寸
    int finalW = (targetW * dpr).toInt();
    int finalH = (logicalHeight * dpr).toInt();

    // 限制最小尺寸
    if (finalW < 100) finalW = 100;
    if (finalH > 0 && finalH < 100) finalH = 100;

    // 根据qualityPreset调整质量参数
    String quality = '80';
    if (qualityPreset == 'high') quality = '90';
    else if (qualityPreset == 'low') quality = '60';
    else if (qualityPreset == 'original') quality = '100';

    final options = <String>[
      'width=$finalW',
      if (finalH > 0) 'height=$finalH',
      'fit=cover',
      'f=auto',
      'quality=$quality'
    ];

    final optionsStr = options.join(',');
    final path = uri.path.startsWith('/') ? uri.path : '/${uri.path}';

    final optimizedUrl = '${uri.scheme}://${uri.host}${RemoteUrlBuilder.cdnPrefix}$optionsStr$path';
    
    return optimizedUrl;
  }

  /// 根据设备分类计算目标宽度（逻辑像素上限）
  /// 返回 capped 后的 logicalWidth，后续会乘以 DPR 得到物理像素
  /// 不同设备类别有不同的上限，避免手机请求过大图片
  double _computeTargetWidth(double logicalWidth, DeviceCategory? deviceCategory) {
    final category = deviceCategory ?? DeviceCategory.phone;

    // 各设备类别的逻辑像素宽度上限
    // 这些值会被乘以 DPR 得到最终的 CDN width 参数
    double maxLogicalWidth;
    switch (category) {
      case DeviceCategory.phone:
        maxLogicalWidth = 480; // 手机最大 480 逻辑像素（3x DPR = 1440 物理像素）
        break;
      case DeviceCategory.tablet:
        maxLogicalWidth = 720; // 平板最大 720 逻辑像素
        break;
      case DeviceCategory.desktop:
        maxLogicalWidth = 1080; // 桌面最大 1080 逻辑像素
        break;
    }

    return min(logicalWidth, maxLogicalWidth);
  }

  /// 检查URL是否已经被优化处理过
  bool _isAlreadyOptimized(String url) {
    if (url.contains(RemoteUrlBuilder.cdnPrefix)) {
      return true;
    }
    
    final cdnPatterns = [
      '/cdn-cgi/image/',
      'cdn-cgi/image/',
      'fit=cover',
      'f=auto',
      'quality=',
      'width=',
      'height='
    ];
    
    int patternCount = 0;
    for (final pattern in cdnPatterns) {
      if (url.contains(pattern)) {
        patternCount++;
      }
    }
    
    return patternCount >= 2;
  }
}