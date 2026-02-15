
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/call_state_model.dart';

// 定义 Provider
final callControllerProvider = StateNotifierProvider.autoDispose<CallController, CallState>((ref) {
  return CallController();
});

class CallController extends StateNotifier<CallState> {
  Timer? _timer;
  int _seconds = 0;

  CallController() : super(const CallState()) {
    _initRenderers();
  }

  // --- 初始化逻辑 ---
  Future<void> _initRenderers() async {
    // 模拟初始化 WebRTC 渲染器
    final local = RTCVideoRenderer();
    final remote = RTCVideoRenderer();
    await local.initialize();
    await remote.initialize();

    state = state.copyWith(
      localRenderer: local,
      remoteRenderer: remote,
      // 初始化悬浮窗位置
      floatOffset: Offset(240.w, 100.h),
    );
  }

  // --- 业务动作 (Action) ---

  void acceptCall() {
    // 实际逻辑：发送 socket 'call_accept'，建立 PeerConnection
    state = state.copyWith(status: CallStatus.connected);
    _startTimer();

    // 接通时重置悬浮窗位置
    state = state.copyWith(floatOffset: Offset(1.sw - 120.w, 60.h));
  }

  void hangUp() {
    // 实际逻辑：发送 socket 'call_end'，关闭 PeerConnection
    _timer?.cancel();
    // 释放渲染器资源
    state.localRenderer?.dispose();
    state.remoteRenderer?.dispose();
    state = state.copyWith(status: CallStatus.ended);
  }

  void toggleMute() {
    // 实际逻辑：localStream.getAudioTracks()[0].enabled = !muted
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void toggleCamera() {
    // 实际逻辑：localStream.getVideoTracks()[0].enabled = !off
    state = state.copyWith(isCameraOff: !state.isCameraOff);
  }

  void toggleSpeaker() {
    // 实际逻辑：Helper.setSpeakerphoneOn(bool)
    state = state.copyWith(isSpeakerOn: !state.isSpeakerOn);
  }

  void updateFloatOffset(Offset newOffset) {
    state = state.copyWith(floatOffset: newOffset);
  }

  // --- 内部辅助 ---
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds++;
      final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
      final seconds = (_seconds % 60).toString().padLeft(2, '0');
      state = state.copyWith(duration: "$minutes:$seconds");
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    state.localRenderer?.dispose();
    state.remoteRenderer?.dispose();
    super.dispose();
  }
}