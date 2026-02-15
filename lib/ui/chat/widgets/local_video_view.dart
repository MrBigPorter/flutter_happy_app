
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class LocalVideoView extends StatelessWidget {
  final RTCVideoRenderer? renderer; // WebRTC 渲染器 (可能为空)
  final bool mirror;

  const LocalVideoView({
    super.key,
    this.renderer,
    this.mirror = true, // 本地摄像头默认镜像
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100.w,
      height: 150.h,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white24, width: 1), // 细边框防背景融合
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11.r), // 略小于外框
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // 1. 如果有渲染器且有纹理，显示视频
    if (renderer != null && renderer!.textureId != null) {
      return RTCVideoView(
        renderer!,
        mirror: mirror,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      );
    }

    // 2. 否则显示占位符 (调试用)
    return Container(
      color: Colors.grey[900],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off, color: Colors.white54, size: 30.sp),
          SizedBox(height: 4.h),
          Text(
            "Me",
            style: TextStyle(color: Colors.white54, fontSize: 10.sp),
          ),
        ],
      ),
    );
  }
}