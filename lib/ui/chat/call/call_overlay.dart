import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../utils/overlay_manager.dart';
import '../models/call_state_model.dart';
import '../providers/call_controller.dart';

class CallOverlay extends ConsumerStatefulWidget {
  final bool isVideo; // 初始配置可以传
  final String? targetAvatar;
  final VoidCallback onTap;

  const CallOverlay({
    super.key,
    required this.isVideo,
    this.targetAvatar,
    required this.onTap,
  });

  @override
  ConsumerState<CallOverlay> createState() => _CallOverlayState();
}

class _CallOverlayState extends ConsumerState<CallOverlay> {
  @override
  Widget build(BuildContext context) {

    // 1. 监听状态变化 (用于自动关闭)
    // 这里的逻辑是：一旦监听到状态变为 ended，立刻关闭悬浮窗
    ref.listen(callControllerProvider, (previous, next) {
      if (next.status == CallStatus.ended) {
        OverlayManager.instance.hide(); // 关掉自己
      }
    });

    //  核心：在这里监听状态！
    // 只要 Controller 里的 duration 变了，这个 build 就会重新跑一次
    final state = ref.watch(callControllerProvider);

    // 从 state 中获取动态数据
    final duration = state.duration;
    final remoteRenderer = state.remoteRenderer;

    // 如果想要更精准的视频/语音判断，也可以直接读 state
    // final isVideoMode = !state.isCameraOff;

    return Material(
      color: Colors.transparent,
      elevation: 8,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: 90.w,
          height: 120.h,
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11.r),
            // 根据传入的配置或实时状态判断显示内容
            child: widget.isVideo
                ? _buildVideoContent(remoteRenderer, duration)
                : _buildAudioContent(duration),
          ),
        ),
      ),
    );
  }

  /// 视频模式 UI
  Widget _buildVideoContent(RTCVideoRenderer? renderer, String duration) {
    // 1. 如果有视频流，显示视频
    if (renderer != null && renderer.textureId != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          RTCVideoView(
            renderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            mirror: false,
          ),
          // 视频模式下，底部显示时间
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Text(
                duration, // 这里现在是实时的
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
            errorWidget: (context, url, error) => Container(color: Colors.grey[800]),
          )
        else
          Container(color: Colors.grey[800], child: Icon(Icons.person, color: Colors.white)),

        // 可以显示 Loading 或者直接显示时间
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Text(
            duration,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 12.sp),
          ),
        ),
      ],
    );
  }

  /// 📞 语音模式 UI
  Widget _buildAudioContent(String duration) {
    return Container(
      color: const Color(0xFF4CD964),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone_in_talk, color: Colors.white, size: 24.sp),
          SizedBox(height: 8.h),

          // 中间：时间
          Text(
            duration,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(height: 4.h),

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