import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/features/share/models/share_data.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../ui/toast/radix_toast.dart';


class SharePost extends StatefulWidget {
  final ShareData data;

  const SharePost({super.key, required this.data,});

  @override
  State<SharePost> createState() => SharePostState();
}

class SharePostState extends State<SharePost> {
   final ScreenshotController _shot = ScreenshotController();

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
    // ImageGallerySaver requires Uint8List
    final result = await ImageGallerySaver.saveImage(
      Uint8List.fromList(bytes),
      quality: 95,
      name: 'share_poster_${DateTime.now().millisecondsSinceEpoch}',
    );
    if (result['isSuccess'] == true) {
      RadixToast.success( 'Image saved to gallery');
    } else {
      RadixToast.error('Failed to save image');
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
            width: 310.w,
            height: 350.w,
            color: context.bgPrimary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.grey[200],
                  width: 310.w,
                  height: 200.w,
                  child: widget.data.imageUrl == null
                      ? const SizedBox.shrink()
                      : Image.network(
                          widget.data.imageUrl!,
                          width: 310.w,
                          height: 200.w,
                          fit: BoxFit.cover,
                        ),
                ),
                Padding(
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
