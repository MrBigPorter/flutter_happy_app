import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat_ui_model.dart';
import '../../photo_preview_page.dart';
import '../../../img/app_image.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';

class ImageMsgBubble extends StatelessWidget {
  final ChatUiModel message;

  const ImageMsgBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // 列表页显示的宽度
    const double bubbleWidth = 240;
    final Map<String, dynamic> meta = message.meta ?? {};
    //  2. 计算宽高比：防止图片加载前高度为 0 导致列表抖动
    final double w = (meta['w'] ?? meta['width'] ?? 1.0).toDouble();
    final double h = (meta['h'] ?? meta['height'] ?? 1.0).toDouble();
    final double aspectRatio = (w / h).clamp(0.5, 2.0); // 限制比例，防止长图太长

    final timeStr = DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(message.createdAt),
    );

    // 逻辑：优先用 localPath，但如果 AppImage 发现文件不在了，它会自动处理
    final source = message.localPath ?? message.content;

    return GestureDetector(
      onTap: () => _openPreview(context, source),
      child: Container(
        width: bubbleWidth,
        height: bubbleWidth / aspectRatio,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // 图片显示
              Hero(
                tag: 'img_${message.id}',
                child: AppCachedImage(
                  source,
                  width: bubbleWidth, //  4. 显式传宽，配合 Preloader
                  height: bubbleWidth / aspectRatio, // 显式传高
                  fit: BoxFit.cover,

                  //  传这些是为了防闪烁和占位
                  previewBytes: message.previewBytes,
                  metadata: meta,

                  enablePreview: false, // 点击由外层接管
                ),
              ),

              // 发送中 Loading
              if (message.status == MessageStatus.sending)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                ),

              // 失败图标
              if (message.status == MessageStatus.failed)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Icon(Icons.error_outline, color: Colors.red, size: 30),
                    ),
                  ),
                ),

              // 时间
              Positioned(
                right: 6, bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    timeStr,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPreview(BuildContext context, String source) {
    // 计算远程 URL 备用（万一本地路径坏了，预览页也能加载）
    final remoteUrl = UrlResolver.resolveImage(context, message.content);

    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => PhotoPreviewPage(
          heroTag: 'img_${message.id}',
          imageSource: source, // 这里传列表当前的 source，保证 Hero 动画连贯
          cachedThumbnailUrl: remoteUrl, // 告诉预览页真正的远程地址
          previewBytes: message.previewBytes, // 传内存小图，用于大图加载前的模糊过渡
          metadata: message.meta,
        ),
      ),
    );
  }
}