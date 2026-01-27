import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/chat_ui_model.dart';
import '../../../../utils/asset/asset_manager.dart';
import '../../../img/app_image.dart';

class VideoMsgBubble extends StatelessWidget {
  final ChatUiModel message;

  const VideoMsgBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // 1. 获取元数据 (宽高、时长)
    final meta = message.meta ?? {};
    final int w = meta['w'] ?? 16;
    final int h = meta['h'] ?? 9;

    // 限制比例，防止过长或过扁
    final double aspectRatio = (w / h).clamp(0.6, 1.8);
    final double maxWidth = 0.6.sw; // 气泡最大宽度
    final double height = maxWidth / aspectRatio;

    // 时长格式化
    final int durationSec = meta['duration'] ?? 0;
    final String durationStr = _formatDuration(durationSec);

    // 封面图源 (可能是本地路径，也可能是 URL)
    final String thumbSource = meta['thumb'] ?? "";
    final String videoSource = message.localPath ?? message.content;

    return GestureDetector(
      onTap: () {
        debugPrint("▶️ Play video: $videoSource");
        // TODO: 这里跳转到你的 VideoPlayerPage
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: maxWidth,
          height: height,
          color: Colors.black12, // 还没加载出来时的底色
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. 封面图层
              _buildThumbnail(thumbSource, maxWidth, height),

              // 2. 遮罩层 (让白色播放按钮更明显)
              Container(color: Colors.black26),

              // 3. 播放按钮
              Center(
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 30.sp),
                ),
              ),

              // 4. 时长角标
              Positioned(
                bottom: 8.h,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    durationStr,
                    style: TextStyle(color: Colors.white, fontSize: 10.sp),
                  ),
                ),
              ),

              // 5. 发送中的转圈圈
              if (message.status == MessageStatus.sending)
                Positioned(
                  top: 8.h,
                  left: 8.w,
                  child: SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String source, double w, double h) {
    if (source.isEmpty) return const SizedBox.shrink();

    // 如果是网络图
    if (source.startsWith('http')) {
      return AppCachedImage(
        source,
        width: w,
        height: h,
        fit: BoxFit.cover,
      );
    }

    // 如果是本地图，需要 AssetManager 解析路径
    return FutureBuilder<String?>(
      future: AssetManager.getFullPath(source, MessageType.image),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          if (kIsWeb) {
            return Image.network(snapshot.data!, width: w, height: h, fit: BoxFit.cover);
          }
          return Image.file(File(snapshot.data!), width: w, height: h, fit: BoxFit.cover);
        }
        return const SizedBox.shrink();
      },
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}