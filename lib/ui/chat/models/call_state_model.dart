import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum CallStatus { idle, dialing, ringing, connected, ended }

class CallState {
  // --- 1. Core Lifecycle Status ---
  final CallStatus status;

  // --- 2. Business Metadata ---
  final String? sessionId;
  final String? targetId;
  final String? targetName;
  final String? targetAvatar;
  final String? remoteSdp; // Stores the remote Offer or Answer SDP string

  // --- 3. Hardware & Media Control State ---
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isCameraOff;
  final bool isVideoMode;
  final String duration; // Formatted time string, e.g., "00:00"

  // --- 4. Rendering & UI Overlay State ---
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

  /// Architectural Defense: Reset to initial state.
  /// Called during hangup to ensure no stale data remains in the state machine.
  factory CallState.initial() {
    return const CallState(
      status: CallStatus.idle,
    );
  }

  // Immutable copy method for Riverpod state updates
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