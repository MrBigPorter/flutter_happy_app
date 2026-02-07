import 'dart:developer' as dev;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../utils/asset/image_provider_utils.dart';

//  CHANGED: 引入统一路径判断工具
import 'package:flutter_app/utils/media/media_path.dart';
import 'package:flutter_app/utils/asset/asset_manager.dart';

import '../../utils/media/media_exporter.dart';

class PhotoPreviewPage extends StatelessWidget {
  final String heroTag;
  final String imageSource; // 高清大图地址（原始 source：可能是 /uploads 或本地路径）
  final String? cachedThumbnailUrl; // 列表页的缩略图（尽量传 CDN url）
  final Uint8List? previewBytes; // 上传时的内存图（最快）
  final Map<String, dynamic>? metadata;

  static final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]);

  const PhotoPreviewPage({
    super.key,
    required this.heroTag,
    required this.imageSource,
    this.cachedThumbnailUrl,
    this.previewBytes,
    this.metadata,
  });

  // CHANGED: 统一 headers（让 iOS/Android 不再是 Dart UA）
  static final Map<String, String> _imgHeaders = buildImgHeaders();

  ImageProvider _getHighResProvider(BuildContext context, String source) {
    final src = source.trim();

    //  第一步：先通过 AssetManager 获取真正的运行路径
    // 它会自动处理：如果是 chat_images/ 开头，会加上沙盒前缀；如果是 http 开头，保持不变
    final String runtimePath = AssetManager.getRuntimePath(src);

    //  第二步：对转正后的路径进行分类
    final type = MediaPath.classify(runtimePath);

    dev.log(' [PhotoPreview] 原始: $src -> 运行路径: $runtimePath', name: 'IMAGE_LOADER');
    dev.log(' [PhotoPreview] 识别类型: $type', name: 'IMAGE_LOADER');

    // 1) 处理本地绝对路径（runtimePath 现在是以 / 开头的了）
    if (type == MediaPathType.localAbs || runtimePath.startsWith('/')) {
      final fileProvider = tryBuildFileImageProvider(runtimePath);
      if (fileProvider != null) {
        dev.log(' [PhotoPreview] 加载本地文件', name: 'IMAGE_LOADER');
        return fileProvider;
      }
    }

    // 2) 处理其它已知类型
    if (type == MediaPathType.blob) return NetworkImage(runtimePath);
    if (type == MediaPathType.asset) return AssetImage(runtimePath);

    // 3) 处理网络图片
    final finalUrl = UrlResolver.resolveImage(
      context,
      src, // 这里用原始 src，因为 UrlResolver 内部可能需要 uploads/ 前缀
      logicalWidth: MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio,
      quality: 85,
    );

    dev.log(' [PhotoPreview] 最终解析 URL: $finalUrl', name: 'IMAGE_LOADER');
    return CachedNetworkImageProvider(finalUrl, headers: _imgHeaders);
  }
  Widget _buildLowResPlaceholder() {
    double? aspectRatio;
    // 必须有 metadata 才能预先撑开大小
    if (metadata != null && metadata!['width'] != null && metadata!['height'] != null) {
      aspectRatio = (metadata!['width'] as num).toDouble() / (metadata!['height'] as num).toDouble();
    }

    Widget? imageWidget;

    //  1. 内存图永远第一优先级
    if (previewBytes != null && previewBytes!.isNotEmpty) {
      imageWidget = Image.memory(previewBytes!, fit: BoxFit.contain, gaplessPlayback: true);
    }

    //  2. 占位图必须用列表页已经加载成功的那个 480px URL
    // 不要用 imageSource，因为它的尺寸 key 跟列表页对不上
    if (imageWidget == null && cachedThumbnailUrl != null && cachedThumbnailUrl!.isNotEmpty) {
      imageWidget = Image(
        image: CachedNetworkImageProvider(
          cachedThumbnailUrl!.trim(),
          //  极其重要：确认你的 AppCachedImage 列表页是否带了 headers？
          // 如果列表页没带，这里也绝对不能带 _imgHeaders！
          // headers: _imgHeaders,
        ),
        fit: BoxFit.contain,
        gaplessPlayback: true,
      );
    }

    //  3. 如果是本地图，也要确保路径一致
    if (imageWidget == null) {
      final type = MediaPath.classify(imageSource);
      if (type == MediaPathType.localAbs || imageSource.startsWith('chat_')) {
        final runtimePath = AssetManager.getRuntimePath(imageSource);
        final localProvider = tryBuildFileImageProvider(runtimePath);
        if (localProvider != null) {
          imageWidget = Image(image: localProvider, fit: BoxFit.contain, gaplessPlayback: true);
        }
      }
    }

    return SizedBox.expand(
      child: Container(
        color: Colors.black, // 保证底色是黑的
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 有了 aspectRatio，即使高清图没来，这里也会瞬间撑满全屏
              if (imageWidget != null)
                aspectRatio != null
                    ? AspectRatio(aspectRatio: aspectRatio, child: imageWidget)
                    : imageWidget,

              // 只要大图没加载完，这个圈就一直转（盖在缩略图上面）
              const CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.bgPrimary,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:  Icon(Icons.save_alt, color: context.textPrimary900, size: 24.sp,),
              title:  Text('save to gallery',style: TextStyle(fontSize: 14.sp, color: context.textPrimary900),),
               onTap: () async {
                 Navigator.pop(context);
                 final ok = await MediaExporter.saveImage(context, imageSource);
                 if (context.mounted) {
                   RadixToast.info(ok ? 'Saved to gallery' : 'Save failed');
                 }
              },
            ),
            ListTile(
              leading:  Icon(Icons.share, color: context.textPrimary900, size: 24.sp,),
              title:  Text('share image',style: TextStyle(fontSize: 14.sp, color: context.textPrimary900)),
              onTap: () async {
                Navigator.pop(context);
                await MediaExporter.shareImage(context, imageSource);
              },
            ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final double safeTop = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. 底层大图
          Center(
            child: PhotoView(
              imageProvider: _getHighResProvider(context, imageSource),
              heroAttributes: PhotoViewHeroAttributes(tag: heroTag),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2.5,
              gaplessPlayback: true,
              loadingBuilder: (_, __) => _buildLowResPlaceholder(),
              errorBuilder: (_, __, ___) => _buildLowResPlaceholder(),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
          ),

          // 2. 右上角：更多操作（保存/分享）
          Positioned(
            top: safeTop + 12, // 增加一点边距
            right: 12,
            child: _buildCircleButton(
              icon: Icons.more_vert,
              onPressed: () => _showActionSheet(context),
            ),
          ),

          // 3. 左上角：关闭
          Positioned(
            top: safeTop + 12,
            left: 12,
            child: _buildCircleButton(
              icon: Icons.close,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 40,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.black38, // 半透明黑，保证白色背景下可见
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.white, size: size * 0.6),
        onPressed: onPressed,
      ),
    );
  }
}
