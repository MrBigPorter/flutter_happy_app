import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../utils/overlay_manager.dart';
import '../core/call_manager/call_state_machine.dart';
import '../models/call_state_model.dart';

class CallOverlay extends ConsumerStatefulWidget {
  final bool isVideo;
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
    // 1. Listen for state changes to trigger self-destruction when the call ends
    ref.listen(callStateMachineProvider, (previous, next) {
      if (next.status == CallStatus.ended) {
        OverlayManager.instance.hide();
      }
    });

    // 2. Watch the call state machine for UI updates
    final state = ref.watch(callStateMachineProvider);

    final duration = state.duration;
    final remoteRenderer = state.remoteRenderer;

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
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11.r),
            child: widget.isVideo
                ? _buildVideoContent(remoteRenderer, duration)
                : _buildAudioContent(duration),
          ),
        ),
      ),
    );
  }

  /// Build content for video call mode (Mini-Player)
  Widget _buildVideoContent(RTCVideoRenderer? renderer, String duration) {
    if (renderer != null && renderer.textureId != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          RTCVideoView(
            renderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            mirror: false,
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                duration,
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

    // Fallback to avatar if video renderer is unavailable
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
          Container(
            color: Colors.grey[800],
            child: const Icon(Icons.person, color: Colors.white),
          ),

        Positioned(
          bottom: 10, left: 0, right: 0,
          child: Text(
            duration,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 12.sp),
          ),
        ),
      ],
    );
  }

  /// Build content for audio call mode
  Widget _buildAudioContent(String duration) {
    return Container(
      color: const Color(0xFF4CD964), // iOS-style green for active calls
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone_in_talk, color: Colors.white, size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            duration,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            "Tap to return",
            style: TextStyle(color: Colors.white70, fontSize: 8.sp),
          ),
        ],
      ),
    );
  }
}