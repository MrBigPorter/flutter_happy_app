import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../models/chat_ui_model.dart';
import '../../../../utils/asset/asset_manager.dart';
import '../../providers/chat_room_provider.dart'; // 为了取缓存
import '../../../img/app_image.dart'; // 你的图片组件
import '../../photo_preview_page.dart'; // 预览页

class ImageMsgBubble extends StatelessWidget {
  final ChatUiModel message;

  const ImageMsgBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final double bubbleSize = 0.60.sw;
    final double dpr = MediaQuery.of(context).devicePixelRatio;
    final int cacheW = (bubbleSize * dpr).toInt();
    final timeStr = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(message.createdAt));

    // L1: Memory Cache (内存缓存)
    final String? sessionPath = ChatRoomController.getPathFromCache(message.id);

    return FutureBuilder<String?>(
      future: AssetManager.getFullPath(message.localPath, MessageType.image),
      builder: (context, snapshot) {
        final String? managerPath = snapshot.data;
        final activeLocalPath = sessionPath ?? managerPath;
        final bool hasLocalFile = activeLocalPath != null;
        final bool hasPreviewBytes = message.previewBytes != null && (message.previewBytes as Uint8List).isNotEmpty;

        Widget buildNetworkImage() {
          return AppCachedImage(
            message.content,
            width: bubbleSize,
            height: bubbleSize,
            fit: BoxFit.cover,
            enablePreview: true,
          );
        }

        return Hero(
          tag: message.id,
          child: GestureDetector(
            onTap: () => _openPreview(context, activeLocalPath),
            child: Container(
              width: bubbleSize,
              height: bubbleSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                color: Colors.grey[50],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Stack(
                  alignment: Alignment.center,
                  fit: StackFit.expand,
                  children: [
                    // L4: 网络图
                    buildNetworkImage(),

                    // L2: 模糊预览图 (Thumb Bytes)
                    if (hasPreviewBytes)
                      Image.memory(
                        message.previewBytes! as Uint8List,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),

                    // L3: 本地高清文件
                    if (hasLocalFile)
                      _buildLocalImage(
                        path: activeLocalPath!,
                        width: bubbleSize,
                        height: bubbleSize,
                        cacheW: cacheW,
                        fallback: buildNetworkImage,
                      ),

                    // 发送遮罩
                    if (message.status == MessageStatus.sending)
                      Container(
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        ),
                      ),

                    // 时间戳
                    Positioned(
                      right: 6.w,
                      bottom: 6.h,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          timeStr,
                          style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocalImage({
    required String path,
    required double width,
    required double height,
    required int cacheW,
    required Widget Function() fallback,
  }) {
    if (kIsWeb) {
      if (!path.startsWith('http') && !path.startsWith('blob:')) return fallback();
      return Image.network(
        path, width: width, height: height, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      );
    } else {
      return Image.file(
        File(path), width: width, height: height, fit: BoxFit.cover,
        cacheWidth: cacheW, gaplessPlayback: true,
        key: ValueKey("${message.id}_local"),
        errorBuilder: (_, __, ___) => fallback(),
      );
    }
  }

  void _openPreview(BuildContext context, String? localPath) {
    String finalSource = localPath ?? "";
    if (kIsWeb) {
      if (message.status == MessageStatus.success && message.content.isNotEmpty) finalSource = message.content;
    } else {
      if (localPath == null || !File(localPath).existsSync()) {
        if (message.content.isNotEmpty) finalSource = message.content;
      }
    }

    if (finalSource.isEmpty) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => PhotoPreviewPage(
          heroTag: message.id,
          imageSource: finalSource,
          thumbnailSource: finalSource,
          previewBytes: message.previewBytes,
        ),
      ),
    );
  }
}