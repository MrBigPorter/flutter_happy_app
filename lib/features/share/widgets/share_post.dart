import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/features/share/models/share_data.dart';
import 'package:flutter_app/utils/media/remote_url_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'package:flutter_app/ui/index.dart';

import 'save_poster_stub.dart'
if (dart.library.html) 'save_poster_web.dart';

class SharePost extends StatefulWidget {
  final ShareData data;

  const SharePost({super.key, required this.data,});

  @override
  State<SharePost> createState() => SharePostState();
}

class SharePostState extends State<SharePost> {
  final ScreenshotController _shot = ScreenshotController();

  // 核心优化 1：定义一个全局的 ImageProvider 来持有图片源
  ImageProvider? _posterImageProvider;

  @override
  void initState() {
    super.initState();
    // 初始化时，如果图片 URL 存在，就构建 NetworkImage
    if (widget.data.imageUrl != null) {
      _posterImageProvider = NetworkImage(
        RemoteUrlBuilder.fitAbsoluteUrl(widget.data.imageUrl!),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //  核心优化 2：给图片加“暖身锁” (precacheImage)
    // 在 UI 真正渲染前，让 Flutter 底层提前去下载并解码这张图片
    // 这样等下面 build() 跑起来的时候，图片已经在内存里了，实现“满血秒出”！
    if (_posterImageProvider != null) {
      precacheImage(_posterImageProvider!, context);
    }
  }

  // Capture the widget as an image file
  Future<XFile> captureToFile() async {
    final bytes = await _shot.capture(pixelRatio: 2.0);
    final tempDir = await getTemporaryDirectory();
    final path =
        '${tempDir.path}/share_poster_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = XFile.fromData(
      Uint8List.fromList(bytes as List<int>),
      name: 'share_poster.png',
      mimeType: 'image/png',
      path: path,
    );
    await file.saveTo(path);
    return XFile(file.path);
  }

  // Save the captured image to the device gallery
  Future<void> saveToGallery() async {
    final bytes = await _shot.capture(pixelRatio: 2.0);
    if (bytes == null) return;

    if (!kIsWeb) {
      try {
        // 1) 申请权限（Android/iOS）
        final has = await Gal.hasAccess();
        if (!has) {
          final ok = await Gal.requestAccess();
          if (!ok) {
            RadixToast.error('Permission denied');
            return;
          }
        }

        // 2) 保存到相册（bytes 版最适合你这种截图）
        await Gal.putImageBytes(bytes);

        RadixToast.success('Image saved to gallery');
      } on GalException catch (e) {
        RadixToast.error(e.type.message); // 更具体的错误原因
      } catch (e) {
        RadixToast.error('Failed to save image');
      }
    } else {
      // Web：下载（你原来的逻辑保持）
      downloadImageOnWeb(bytes);
    }
  }

  Future<void> sharePost() async {
    final file = await captureToFile();
    await Share.shareXFiles(
      [file],
      text: widget.data.combined,
      subject: widget.data.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: _shot,
      child: Stack(
        children: [
          Container(
            color: context.bgPrimary,
            width: 310.w,
            height: 350.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.grey[200], // 浅灰色底色，即使网极慢也有个兜底轮廓
                  width: 310.w,
                  height: 200.h,
                  //  核心优化 3：这里不再用 Image.network，而是使用提前缓存好的 Provider
                  child: _posterImageProvider == null
                      ? const SizedBox.shrink()
                      : Image(
                    image: _posterImageProvider!,
                    width: 310.w,
                    height: 200.h,
                    fit: BoxFit.cover,
                    // 核心体验提升 1：加入 Loading 加载圈
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child; // 加载完直接显示
                      return Center(
                        // 这里使用 iOS 风格的菊花转，显得更高级
                        child: CupertinoActivityIndicator(radius: 14.w),
                      );
                    },
                    // 核心体验提升 2：加载完成后的淡入动画 (防生硬闪现)
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                      // 如果秒命中缓存，直接显示，不要动画
                      if (wasSynchronouslyLoaded) return child;

                      // 否则，给它一个 400 毫秒的优雅淡入效果
                      return AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        child: child,
                      );
                    },
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(Icons.broken_image, color: Colors.grey[400], size: 32.w),
                    ),
                  ),
                ),
                SizedBox(
                  width: 200.w,
                  child:  Padding(
                    padding: EdgeInsets.only(top: 16.w, left: 16.w, right: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.data.title,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: context.textMd,
                            fontWeight: FontWeight.w800,
                            color: context.textSecondary700,
                            height: context.leadingMd,
                          ),
                        ),
                        SizedBox(height: 20.w),
                        Text(
                          widget.data.text ?? '',
                          maxLines: 3,
                          style: TextStyle(
                            fontSize: context.textXs,
                            color: context.textSecondary700,
                            height: context.leadingXs,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 8.w),
                        Text(
                          widget.data.subTitle ?? '',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: context.textXs,
                            color: context.textSecondary700,
                            height: context.leadingXs,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          Positioned(
            right: 16.w,
            bottom: 16.w,
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: context.bgBrandSecondary,
                borderRadius: BorderRadius.circular(8.w),
              ),
              child: QrImageView(
                data: widget.data.url,
                size: 80.w,
                backgroundColor: Colors.white,
              ),
            ),
          )
        ],
      ),
    );
  }
}