import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum CallStatus { dialing, ringing, connected, ended }

class CallState {
  final CallStatus status;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isCameraOff;
  final bool isVideoMode;
  final String duration; // "00:00"

  // WebRTC 渲染器 (UI 需要用到)
  final RTCVideoRenderer? localRenderer;
  final RTCVideoRenderer? remoteRenderer;

  // 悬浮窗位置 (纯 UI 状态，也可以放这里)
  final Offset floatOffset;

  const CallState({
    this.status = CallStatus.dialing,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.isCameraOff = false,
    this.isVideoMode = true,
    this.duration = "00:00",
    this.localRenderer,
    this.remoteRenderer,
    this.floatOffset = const Offset(20, 100), // 默认位置
  });

  // 复制方法 (用于 Riverpod 更新状态)
  CallState copyWith({
    CallStatus? status,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isCameraOff,
    bool? isVideoMode,
    String? duration,
    RTCVideoRenderer? localRenderer,
    RTCVideoRenderer? remoteRenderer,
    Offset? floatOffset,
  }) {
    return CallState(
      status: status ?? this.status,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isCameraOff: isCameraOff ?? this.isCameraOff,
      isVideoMode: isVideoMode ?? this.isVideoMode,
      duration: duration ?? this.duration,
      localRenderer: localRenderer ?? this.localRenderer,
      remoteRenderer: remoteRenderer ?? this.remoteRenderer,
      floatOffset: floatOffset ?? this.floatOffset,
    );
  }
}