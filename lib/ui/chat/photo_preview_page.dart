import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

class PhotoPreviewPage extends StatelessWidget {
  final String heroTag;
  final String imageSource;     // 原图 (高清，用于最终显示)
  final String thumbnailSource; //  缩略图 (低清，用于占位/快速显示)

  const PhotoPreviewPage({
    super.key,
    required this.heroTag,
    required this.imageSource,
    required this.thumbnailSource,
  });

  //  辅助方法：统一获取 Provider (网络或本地)
  ImageProvider _getProvider(String source) {
    if (kIsWeb) {
      // 不管是 blob: 还是 http:，统统用 NetworkImage！
      // 1. 解决 blob 不能存库的问题
      // 2. 解决 1MB+ 大图存 IndexedDB 导致黑屏/卡死的问题
      return NetworkImage(source);
    }

    // 2. Mobile 端
    if (source.startsWith('http') || source.startsWith('https')) {
      return CachedNetworkImageProvider(source);
    } else {
      // 本地文件
      return FileImage(File(source));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. 准备两个 Provider
    final ImageProvider originalProvider = _getProvider(imageSource);
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
              // ️ 设为 true 防止在原图加载完成瞬间闪烁
              gaplessPlayback: true,

              // 核心魔法：渐进式加载
              // 在原图下载过程中，显示“缩略图”而不是转圈！
              loadingBuilder: (context, event) {
                return Image(
                  image: thumbnailProvider,
                  fit: BoxFit.contain, // 必须和 PhotoView 默认行为一致
                  gaplessPlayback: true,// 防止闪烁
                  // 如果缩略图本身也在加载(极少情况)，显示微弱的转圈
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white24),
                    );
                  },
                  // 如果缩略图加载失败(极少情况)，显示空
                  errorBuilder: (_, __, ___) => const SizedBox(),
                );
              },

              // ❌ 错误显示
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image, color: Colors.white54, size: 50),
                      const SizedBox(height: 10),
                      const Text("原图加载失败", style: TextStyle(color: Colors.white54)),
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