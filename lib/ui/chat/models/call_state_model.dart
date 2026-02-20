import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum CallStatus { idle, dialing, ringing, connected, ended }

class CallState {
  // --- 1. 核心状态 ---
  final CallStatus status;

  // --- 2. 业务元数据 (Metadata) [新增] ---
  final String? sessionId;
  final String? targetId;
  final String? targetName;
  final String? targetAvatar;
  final String? remoteSdp; // [新增] 存储远端发来的 Offer 或 Answer SDP

  // --- 3. 硬件控制状态 ---
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isCameraOff;
  final bool isVideoMode;
  final String duration; // "00:00"

  // --- 4. 渲染与 UI ---
  final RTCVideoRenderer? localRenderer;
  final RTCVideoRenderer? remoteRenderer;
  final Offset floatOffset;

  const CallState({
    this.status = CallStatus.idle,
    this.sessionId,
    this.targetId,
    this.targetName,
    this.targetAvatar,
    this.remoteSdp,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.isCameraOff = false,
    this.isVideoMode = true,
    this.duration = "00:00",
    this.localRenderer,
    this.remoteRenderer,
    this.floatOffset = const Offset(20, 100),
  });

  /// 架构防御点：一键恢复初始状态（挂断时调用，保证没有任何脏数据残留）
  factory CallState.initial() {
    return const CallState(
      status: CallStatus.idle,
      // 所有元数据自然变为 null
    );
  }

  // 复制方法 (用于 Riverpod 更新状态)
  CallState copyWith({
    CallStatus? status,
    String? sessionId,
    String? targetId,
    String? targetName,
    String? targetAvatar,
      String? remoteSdp,
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
      sessionId: sessionId ?? this.sessionId,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      targetAvatar: targetAvatar ?? this.targetAvatar,
      remoteSdp: remoteSdp ?? this.remoteSdp,
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