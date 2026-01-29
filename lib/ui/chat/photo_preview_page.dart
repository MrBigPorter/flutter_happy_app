import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/foundation.dart';
import '../../utils/image_url.dart';

class PhotoPreviewPage extends StatelessWidget {
  final String heroTag;
  final String imageSource;       // 原始 Key (uploads/...)
  final String? cachedThumbnailUrl; //  列表页正在显示的完整 URL (width=497那个)
  final Uint8List? previewBytes;  // 内存微缩图
  final int? memW, memH;

  const PhotoPreviewPage({
    super.key,
    required this.heroTag,
    required this.imageSource,
    this.cachedThumbnailUrl,
    this.previewBytes,
    this.memW,
    this.memH,
  });

  /// 获取高清图 Provider (生成 width=1080 或 750 的大图链接)
  ImageProvider _getHighResProvider(BuildContext context, String source) {
    // 这里的 logicalWidth 决定了你请求的大图尺寸
    final String finalPath = ImageUrl.build(
        context,
        source,
        logicalWidth: 1080, // 这里请求高清图
        quality: 85
    );

    if (finalPath.startsWith('blob:') || (kIsWeb && finalPath.startsWith('http') && !finalPath.contains('cdn-cgi'))) {
      return NetworkImage(finalPath);
    }

    if (!kIsWeb && (finalPath.startsWith('/') || finalPath.startsWith('file://'))) {
      return FileImage(File(finalPath.replaceFirst('file://', '')));
    }

    return CachedNetworkImageProvider(finalPath);
  }

  @override
  Widget build(BuildContext context) {
    // 1. 准备高清图源
    final ImageProvider originalProvider = _getHighResProvider(context, imageSource);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: PhotoView(
              imageProvider: originalProvider,
              heroAttributes: PhotoViewHeroAttributes(tag: heroTag),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2.5,
              gaplessPlayback: true,

              loadingBuilder: (context, event) {

                // A. 如果有列表页传过来的 URL (width=497)，立刻显示它！
                // 因为这个 URL 在列表页已经下载过了，内存里有，所以是 0 延迟秒开。
                if (cachedThumbnailUrl != null) {
                  return CachedNetworkImage(
                    imageUrl: cachedThumbnailUrl!, //  严禁修改这个 URL，必须和列表页一模一样
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain, // 保持比例，铺满屏幕
                    // 如果连小图都没加载完（极少见），再显示菊花
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white24),
                    ),
                    errorWidget: (context, url, error) => const SizedBox(),
                  );
                }

                // B. 如果没有 URL，试着显示 previewBytes (内存微缩图)
                if (previewBytes != null && previewBytes!.isNotEmpty) {
                  return Image.memory(
                    previewBytes!,
                    width: double.infinity, height: double.infinity,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  );
                }

                // C. 啥都没有，只能转菊花
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white24),
                );
              },

              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image, color: Colors.white54, size: 50),
              ),
            ),
          ),

          // 关闭按钮
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black26,
                child: Icon(Icons.close, color: Colors.white, size: 24),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}