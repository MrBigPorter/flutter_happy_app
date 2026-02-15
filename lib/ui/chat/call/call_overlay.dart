import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CallOverlay extends StatefulWidget {
  final bool isVideo; // 是视频还是语音
  final String? targetAvatar; // 对方头像
  final String duration; // 通话时长 (e.g. "05:21")
  final RTCVideoRenderer? remoteRenderer; // 视频渲染器
  final VoidCallback onTap; // 点击恢复全屏

  const CallOverlay({
    super.key,
    required this.isVideo,
    this.targetAvatar,
    this.duration = "00:00",
    this.remoteRenderer,
    required this.onTap,
  });

  @override
  State<CallOverlay> createState() => _CallOverlayState();
}

class _CallOverlayState extends State<CallOverlay> {
  @override
  Widget build(BuildContext context) {
    //  重要：Overlay 里的组件默认没有 Material 上下文
    // 必须包裹 Material，否则文字会有黄色下划线，且没有波纹效果
    return Material(
      color: Colors.transparent,
      elevation: 8,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: 90.w,  // 悬浮窗宽度
          height: 120.h, // 悬浮窗高度
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white24, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          // 裁剪圆角
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11.r),
            child: widget.isVideo
                ? _buildVideoContent()
                : _buildAudioContent(),
          ),
        ),
      ),
    );
  }

  /// 📹 视频模式 UI
  Widget _buildVideoContent() {
    // 1. 如果有视频流，显示视频
    if (widget.remoteRenderer != null && widget.remoteRenderer!.textureId != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          RTCVideoView(
            widget.remoteRenderer!,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            mirror: false,
          ),
          // 视频模式下，底部也显示一个小时间，方便看
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Text(
                widget.duration,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        ],
      );
    }

    // 2. 没视频流，显示头像占位
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.targetAvatar != null)
          CachedNetworkImage(
            imageUrl: widget.targetAvatar!,
            fit: BoxFit.cover,
          )
        else
          Container(color: Colors.grey[800], child: Icon(Icons.person, color: Colors.white)),

        Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
      ],
    );
  }

  /// 📞 语音模式 UI
  Widget _buildAudioContent() {
    return Container(
      color: const Color(0xFF4CD964), // iOS 风格的通话绿
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 顶部：正在通话图标
          Icon(Icons.phone_in_talk, color: Colors.white, size: 24.sp),
          SizedBox(height: 8.h),

          // 中间：时间
          Text(
            widget.duration,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()], // 等宽数字，防止跳动
            ),
          ),
          SizedBox(height: 4.h),

          // 底部：提示文字
          Text(
            "Tap to return",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 8.sp,
            ),
          ),
        ],
      ),
    );
  }
}