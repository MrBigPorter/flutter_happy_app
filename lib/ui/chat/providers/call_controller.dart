
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/call_state_model.dart';

// 定义 Provider,持久化
final callControllerProvider = StateNotifierProvider<CallController, CallState>((ref) {
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
    // 1. 停止计时器
    _timer?.cancel();

    // 1. 先把要销毁的对象暂存起来
    final oldLocal = state.localRenderer;
    final oldRemote = state.remoteRenderer;

    // 2. 立即更新 State，把渲染器置空！
    // 这一步会触发 UI 重建。UI 发现 renderer 是 null，就会移除 RTCVideoView 组件。
    state = state.copyWith(
      status: CallStatus.ended,
      localRenderer: null,
      remoteRenderer: null,
    );

    // 3. UI 脱钩后，再安全销毁对象
    // 使用 Future.microtask 确保当前帧绘制完成后再销毁，万无一失
    Future.microtask(() async {
      try {
        oldLocal?.srcObject = null;
        await oldLocal?.dispose();

        oldRemote?.srcObject = null;
        await oldRemote?.dispose();
      } catch (e) {
        debugPrint("Renderer dispose error: $e");
      }
    });
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
    // 只有当 State 里还持有渲染器时，才去销毁它
    // 如果 hangUp 已经运行过，这里 state.localRenderer 应该是 null，就不会重复销毁
    final local = state.localRenderer;
    final remote = state.remoteRenderer;

    if (local != null) {
      local.srcObject = null;
      local.dispose();
    }
    if (remote != null) {
      remote.srcObject = null;
      remote.dispose();
    }
    super.dispose();
  }
}