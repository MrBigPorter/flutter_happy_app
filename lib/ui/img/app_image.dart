import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// 如果需要骨架屏效果，推荐引入 shimmer 包: flutter pub add shimmer
 import 'package:shimmer/shimmer.dart';
import '../../utils/image_url.dart';

class AppCachedImage extends StatelessWidget {
  final String? src;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? radius;

  /// 图片优化
  final int quality;
  final String format;
  final bool forceGatewayOnNative;

  /// UI
  final Color placeholderColor;
  final Widget? placeholder;
  final Widget? error;

  /// 交互
  final bool enablePreview; // 是否开启点击预览

  const AppCachedImage(
      this.src, {
        super.key,
        this.width,
        this.height,
        this.fit = BoxFit.cover,
        this.radius,
        this.quality = 75,
        this.format = 'auto',
        this.forceGatewayOnNative = false,
        this.placeholderColor = const Color(0xFFF5F5F5), // 稍微调亮一点
        this.placeholder,
        this.error,
        this.enablePreview = false,
      });

  @override
  Widget build(BuildContext context) {
    // 1. 判空兜底
    if (src == null || src!.isEmpty) {
      return _wrapper(_ph(width, height));
    }


    // 2. 识别图片类型
    final isNetwork = src!.startsWith('http');
    final isAsset = src!.startsWith('assets/');
    final isFile = !isNetwork && !isAsset; // 假设非网络非asset就是本地路径

    //  1. 把计算逻辑提出来，让大家都能用
    // 计算像素密度，用于指定解码大小
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    // 如果外部没传宽，就给个默认限制 (比如 1080)，防止解太大
    final int? memW = (width == null) ? null : (width! * dpr).round();
    final int? memH = (height == null) ? null : (height! * dpr).round();

    Widget imageWidget;

    if (isNetwork) {
      // --- 网络图片逻辑 (保持你原有的优秀逻辑) ---
      final url = ImageUrl.build(
        context,
        src,
        logicalWidth: width,
        logicalHeight: height,
        fit: fit,
        quality: quality,
        format: format,
        forceGatewayOnNative: forceGatewayOnNative,
      );

      imageWidget = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        // 内存缓存优化
        memCacheWidth: memW,
        memCacheHeight: memH,
        // 磁盘缓存优化 (通常和内存一样，或者稍大一点)
        maxWidthDiskCache: memW,
        maxHeightDiskCache: memH,

        //1. 设置淡入时间为 0 (防止因为 ID 变化导致的淡入闪烁)
        fadeOutDuration: Duration.zero,
        fadeInDuration: Duration.zero,

        // 这里的 placeholder 改用骨架屏会更好看
        placeholder: (_, __) => placeholder ?? _buildShimmer(width, height),
        errorWidget: (_, __, ___) => error ?? _err(width, height),
      );
    } else if (isAsset) {
      // --- Asset 图片 ---
      imageWidget = Image.asset(
        src!,
        width: width,
        height: height,
        cacheWidth: memW,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => error ?? _err(width, height),
      );
    } else {
      //  修复点：如果是 Web，本地路径其实是 Blob URL，直接当网络图加载即可
      if (kIsWeb) {
        imageWidget = Image.network(
          src!,
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
          cacheWidth: memW,
          errorBuilder: (_, __, ___) => error ?? _err(width, height),
        );
      }else{
        // --- 本地 File 图片 (用于相册选图预览) ---
        final file = File(src!);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            width: width,
            height: height,
            // 这能让 50MB 的内存占用瞬间降到 1MB，列表滑动如丝般顺滑
            cacheWidth: memW,
            fit: fit,
            gaplessPlayback: true,//这会让 Flutter 在重新构建组件时，继续显示旧的纹理，直到新的解码完成
            errorBuilder: (_, __, ___) => error ?? _err(width, height),
          );
        } else {
          imageWidget = _err(width, height);
        }
      }

    }

    return _wrapper(imageWidget);
  }

  // 统一包装：圆角 + 点击事件
  Widget _wrapper(Widget child) {
    Widget res = child;

    // 圆角
    if (radius != null) {
      res = ClipRRect(borderRadius: radius!, child: res);
    }

    // 点击预览 (简单的逻辑，复杂项目可以用 photo_view 包)
    if (enablePreview && src != null && src!.isNotEmpty) {
      res = GestureDetector(
        onTap: () {
          // TODO: 调用全局的图片预览路由
          // Navigator.push(context, MaterialPageRoute(builder: (_) => PhotoViewPage(url: src!)));
          print("点击预览: $src");
        },
        child: res,
      );
    }

    return res;
  }

  //  骨架屏效果 (如果没有 shimmer 包，就用灰色块代替)
  Widget _buildShimmer(double? w, double? h) {
    return Container(
      width: w,
      height: h,
      color: placeholderColor,
      // 如果引入了 shimmer 包，打开下面的代码:
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(color: Colors.white),
      ),
    );
  }

  Widget _ph(double? w, double? h) => Container(
    width: w,
    height: h,
    color: placeholderColor,
    alignment: Alignment.center,
    child: Icon(Icons.image, color: Colors.grey[400], size: 20),
  );

  Widget _err(double? w, double? h) => Container(
    width: w,
    height: h,
    color: placeholderColor,
    alignment: Alignment.center,
    child: Icon(Icons.broken_image_rounded, color: Colors.grey[400], size: 24),
  );
}