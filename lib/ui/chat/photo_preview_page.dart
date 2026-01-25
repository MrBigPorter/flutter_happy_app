import 'dart:io';
import 'dart:typed_data'; //  必须引用，解决 Uint8List 报错
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

class PhotoPreviewPage extends StatelessWidget {
  final String heroTag;
  final String imageSource;       // 原图 (高清，用于最终显示)
  final String thumbnailSource;   // 缩略图路径 (备用)
  final Uint8List? previewBytes;  // 新增：微缩图字节流 (视觉占位核心)

  const PhotoPreviewPage({
    super.key,
    required this.heroTag,
    required this.imageSource,
    required this.thumbnailSource,
    this.previewBytes, // 接收 ChatUiModel 传来的 bytes
  });

  // 辅助方法：统一获取 Provider (网络或本地)
  ImageProvider _getProvider(String source) {
    if (kIsWeb) {
      // Web 端逻辑
      return NetworkImage(source);
    }

    // Mobile 端逻辑
    if (source.startsWith('http') || source.startsWith('https')) {
      return CachedNetworkImageProvider(source);
    } else {
      // 本地文件
      return FileImage(File(source));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. 准备高清原图 Provider
    final ImageProvider originalProvider = _getProvider(imageSource);

    // 2. 准备缩略图 Provider (用于 previewBytes 不存在时的备选)
    final ImageProvider thumbnailProvider = _getProvider(thumbnailSource);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // A. 核心浏览组件
          Center(
            child: PhotoView(
              imageProvider: originalProvider, // 目标：加载高清原图

              // 绑定 Hero 动画
              heroAttributes: PhotoViewHeroAttributes(tag: heroTag),

              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2.5,
              // 设为 true 防止在原图加载完成瞬间闪烁
              gaplessPlayback: true,

              //  核心魔法：渐进式加载 v2.4
              // 优先级：previewBytes (内存极速) > thumbnailSource (可能需要IO) > 转圈
              loadingBuilder: (context, event) {
                // 1. 第一优先级：如果有微缩图字节流，直接从内存渲染，0 IO 耗时
                if (previewBytes != null && previewBytes!.isNotEmpty) {
                  return Image.memory(
                    previewBytes!,
                    //  核心修改：加上这两行，强制撑满屏幕！
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                    // 可选：加个抗锯齿，让拉伸后的马赛克稍微柔和一点点
                    filterQuality: FilterQuality.low,
                    gaplessPlayback: true,
                  );
                }

                // 2. 第二优先级：加载缩略图 Provider
                return Image(
                  image: thumbnailProvider,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  // 如果缩略图本身也在加载(极少情况)，显示微弱的转圈
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white24),
                    );
                  },
                  errorBuilder: (_, __, ___) => const SizedBox(),
                );
              },

              //  错误显示
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image, color: Colors.white54, size: 50),
                      const SizedBox(height: 10),
                      const Text("image loading error", style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                );
              },
            ),
          ),

          // B. 关闭按钮 (左上角)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}