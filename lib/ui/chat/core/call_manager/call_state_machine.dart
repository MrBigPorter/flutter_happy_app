import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/chat/core/call_manager/storage/call_arbitrator.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/constants/socket_events.dart';
import 'package:flutter_app/core/services/socket/socket_service.dart';

import '../../../../core/providers/socket_provider.dart';
import '../../../../utils/overlay_manager.dart';
import '../../models/call_event.dart';
import '../../models/call_state_model.dart';
import '../../services/callkit_service.dart';

// 暴露给全 App 使用的唯一 Provider
final callStateMachineProvider = StateNotifierProvider<CallStateMachine, CallState>((ref) {
  final socketService = ref.read(socketServiceProvider);
  return CallStateMachine(socketService);
});

class CallStateMachine extends StateNotifier<CallState> with WidgetsBindingObserver {
  final SocketService _socketService;

  // --- WebRTC 引擎核心变量 ---
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final List<RTCIceCandidate> _iceCandidateQueue = [];
  String? _remoteSdpStr;

  Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun.miwifi.com:3478'},
    ],
  };

  // --- 状态流转锁 ---
  bool _isAccepting = false;
  bool _isHangingUp = false;
  Timer? _timer;
  int _seconds = 0;

  CallStateMachine(this._socketService) : super(CallState.initial()) {
    WidgetsBinding.instance.addObserver(this);
    _fetchIceCredentials();
    _initSocketListeners();
  }

  /// ----------------------------------------------------------------
  /// 动作 1：主叫发起通话 (Dialing)
  /// ----------------------------------------------------------------
  Future<void> startCall(String targetId, {bool isVideo = true}) async {
    //  铁律：只有空闲状态才能向外拨号
    if (state.status != CallStatus.idle || !mounted) return;

    final sessionId = const Uuid().v4();

    try {
      await _initLocalMedia(isVideo);
      await _createPeerConnection();

      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      // 发送信令
      _socketService.socket?.emit(SocketEvents.callInvite, {
        'sessionId': sessionId,
        'targetId': targetId,
        'sdp': offer.sdp,
        'mediaType': isVideo ? 'video' : 'audio',
      });

      // 状态流转：Idle -> Dialing
      if (mounted) {
        state = state.copyWith(
          status: CallStatus.dialing,
          sessionId: sessionId,
          targetId: targetId,
          isVideoMode: isVideo,
          floatOffset: Offset(240.w, 100.h),
        );
        debugPrint("📞 [StateMachine] 状态流转: Idle -> Dialing (Session: $sessionId)");
      }
    } catch (e) {
      debugPrint(" [StateMachine] 拨号失败: $e");
      hangUp(emitEvent: false);
    }
  }

  /// ----------------------------------------------------------------
  /// 动作 2：收到外来呼叫 (由 CallDispatcher 安检通过后调用)
  /// ----------------------------------------------------------------
  void onIncomingInvite(CallEvent event) {
    //  铁律：只有空闲状态，才能响铃！
    if (state.status != CallStatus.idle) {
      debugPrint(" [StateMachine] 拦截：当前状态 ${state.status}，拒绝进入 Ringing");
      return;
    }

    // 缓存对方发来的 SDP，等接听时再用
    _remoteSdpStr = event.rawData['sdp'];

    // 状态流转：Idle -> Ringing
    state = state.copyWith(
      status: CallStatus.ringing,
      sessionId: event.sessionId,
      targetId: event.senderId,
      targetName: event.senderName,
      targetAvatar: event.senderAvatar,
      isVideoMode: event.isVideo,
    );
    debugPrint("🔔 [StateMachine] 状态流转: Idle -> Ringing (Session: ${event.sessionId})");
  }

  /// ----------------------------------------------------------------
  /// 动作 3：接听通话 (Accept)
  /// ----------------------------------------------------------------
  Future<void> acceptCall() async {
    //  铁律：只有在响铃中，才能接听！
    if (state.status != CallStatus.ringing || _isAccepting || !mounted) return;
    _isAccepting = true;

    // 状态流转：Ringing -> Connected
    state = state.copyWith(status: CallStatus.connected);
    debugPrint(" [StateMachine] 状态流转: Ringing -> Connected");

    try {
      await _initLocalMedia(state.isVideoMode);
      await _createPeerConnection();

      if (_remoteSdpStr != null) {
        await _peerConnection!.setRemoteDescription(RTCSessionDescription(_remoteSdpStr!, 'offer'));
        _flushIceCandidateQueue();
      }

      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      _socketService.socket?.emit(SocketEvents.callAccept, {
        'sessionId': state.sessionId,
        'targetId': state.targetId,
        'sdp': answer.sdp,
      });

      await _enableBackgroundMode();
      _startTimer();
      state = state.copyWith(floatOffset: Offset(1.sw - 120.w, 60.h));
    } catch (e) {
      debugPrint(" [StateMachine] 接听失败: $e");
      hangUp();
    } finally {
      _isAccepting = false;
    }
  }

  /// ----------------------------------------------------------------
  /// 动作 4：挂断通话 (HangUp)
  /// ----------------------------------------------------------------
  void hangUp({bool emitEvent = true}) async {
    //  铁律：如果已经空闲或已经结束，绝不重复执行挂断
    if (_isHangingUp || state.status == CallStatus.idle || state.status == CallStatus.ended || !mounted) return;
    _isHangingUp = true;
    _timer?.cancel();

    debugPrint( "[StateMachine] 执行挂断清理流程...");

    // 1. 状态锁定为 Ended
    state = state.copyWith(status: CallStatus.ended);

    // 2. 本地发出挂断指令
    if (emitEvent && state.sessionId != null) {
      _socketService.socket?.emit(SocketEvents.callEnd, {
        'sessionId': state.sessionId, 'targetId': state.targetId, 'reason': 'hangup',
      });
      // 写入死亡名单，开启无敌金身
      await CallArbitrator.instance.markSessionAsEnded(state.sessionId!);
      await CallArbitrator.instance.lockGlobalCooldown();
    }

    // 3. 清理系统原生资源
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && FlutterBackground.isBackgroundExecutionEnabled) {
        FlutterBackground.disableBackgroundExecution();
      }
      OverlayManager.instance.hide();
      CallKitService.instance.endCall(state.sessionId ?? '');
      CallKitService.instance.clearAllCalls();
    } catch (_) {}

    // 4. 清理 WebRTC 流
    final oldLocal = state.localRenderer;
    final oldRemote = state.remoteRenderer;

    state = state.copyWith(localRenderer: null, remoteRenderer: null, duration: "00:00");

    Future.microtask(() async {
      try {
        _localStream?.getTracks().forEach((track) => track.stop());
        await _localStream?.dispose();
        _localStream = null;
        await _peerConnection?.close();
        await _peerConnection?.dispose();
        _peerConnection = null;
        if (oldLocal != null) await oldLocal.dispose();
        if (oldRemote != null) await oldRemote.dispose();
      } catch (_) {} finally {
        _isHangingUp = false;
        // ⭐️ 终极失忆大法：2秒后彻底清空状态，回归纯净 Idle
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && state.status == CallStatus.ended) {
            state = CallState.initial();
            debugPrint("♻️ [StateMachine] 资源回收完毕，系统已回归 Idle");
          }
        });
      }
    });
  }


  /// ================================================================
  /// 内部 WebRTC 与流媒体引擎支持逻辑 (保持你原有的逻辑不变)
  /// ================================================================

  void _initSocketListeners() {
    final socket = _socketService.socket;

    // A. 对方同意接听
    socket?.on(SocketEvents.callAccept, (data) async {
      if (data['sessionId'] != state.sessionId) return;

      final sdp = RTCSessionDescription(data['sdp'], 'answer');
      await _peerConnection?.setRemoteDescription(sdp);
      _flushIceCandidateQueue();

      state = state.copyWith(status: CallStatus.connected);
      await _enableBackgroundMode();
      _startTimer();
      state = state.copyWith(floatOffset: Offset(1.sw - 120.w, 60.h));
    });

    // B. 对方发来打洞数据
    socket?.on(SocketEvents.callIce, (data) async {
      if (data['sessionId'] != state.sessionId) return;

      dynamic rawCandidate = data['candidate'];
      String actualCandidateStr = rawCandidate is Map ? (rawCandidate['candidate'] ?? "") : rawCandidate.toString();

      final candidate = RTCIceCandidate(actualCandidateStr, data['sdpMid'], data['sdpMLineIndex']);

      if (_peerConnection?.getRemoteDescription() == null) {
        _iceCandidateQueue.add(candidate);
      } else {
        await _peerConnection?.addCandidate(candidate);
      }
    });

    // C. 对方挂断
    socket?.on(SocketEvents.callEnd, (data) {
      if (data['sessionId'] == state.sessionId) {
        hangUp(emitEvent: false);
      }
    });
  }

  Future<void> _initLocalMedia(bool isVideo) async {
    try {
      await Helper.setSpeakerphoneOn(isVideo);
    } catch (_) {}

    final Map<String, dynamic> mediaConstraints = {
      'audio': { 'echoCancellation': true, 'noiseSuppression': true, 'autoGainControl': true },
      'video': isVideo ? { 'facingMode': 'user', 'width': {'ideal': 640}, 'height': {'ideal': 480}, 'frameRate': {'ideal': 30} } : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    final localRenderer = RTCVideoRenderer();
    await localRenderer.initialize();
    localRenderer.srcObject = _localStream;

    final remoteRenderer = RTCVideoRenderer();
    await remoteRenderer.initialize();

    state = state.copyWith(localRenderer: localRenderer, remoteRenderer: remoteRenderer);
  }

  Future<void> _createPeerConnection() async {
    await _ensureIceServersReady();
    _peerConnection = await createPeerConnection(_iceServers);

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    _peerConnection?.onIceCandidate = (candidate) {
      if (!mounted || state.targetId == null) return;
      _socketService.socket?.emit(SocketEvents.callIce, {
        'sessionId': state.sessionId,
        'targetId': state.targetId,
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    _peerConnection?.onTrack = (event) {
      if (!mounted) return;
      if (event.streams.isNotEmpty) {
        state.remoteRenderer?.srcObject = event.streams[0];
        state = state.copyWith(remoteRenderer: state.remoteRenderer);
      }
    };
  }

  Future<void> _fetchIceCredentials() async {
    try {
      final result = await Api.chatIceServers();
      final List<Map<String, dynamic>> iceConfig = [];
      for (var item in result) {
        final Map<String, dynamic> map = item.toJson();
        map.removeWhere((key, value) => value == null || value == "");
        iceConfig.add(map);
      }
      if (iceConfig.isNotEmpty) _iceServers = { 'iceServers': iceConfig };
    } catch (_) {}
  }

  Future<void> _ensureIceServersReady() async {
    final firstServer = _iceServers['iceServers']?.first;
    if (firstServer['username'] == null || firstServer['username'].isEmpty) {
      await _fetchIceCredentials();
    }
  }

  void _flushIceCandidateQueue() {
    if (_iceCandidateQueue.isEmpty || _peerConnection?.getRemoteDescription() == null) return;
    for (var candidate in _iceCandidateQueue) {
      _peerConnection?.addCandidate(candidate);
    }
    _iceCandidateQueue.clear();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds++;
      final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
      final seconds = (_seconds % 60).toString().padLeft(2, '0');
      if (state.status == CallStatus.connected) {
        state = state.copyWith(duration: "$minutes:$seconds");
      } else {
        timer.cancel();
      }
    });
  }

  Future<bool> _enableBackgroundMode() async {
    if (defaultTargetPlatform == TargetPlatform.iOS || kIsWeb) return true;
    final androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "Joyminis Call",
      notificationText: "Call in progress...",
      notificationImportance: AndroidNotificationImportance.normal,
      notificationIcon: const AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
    );
    if (await FlutterBackground.initialize(androidConfig: androidConfig)) {
      return await FlutterBackground.enableBackgroundExecution();
    }
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (_localStream == null) return;
    final videoTracks = _localStream!.getVideoTracks();
    if (videoTracks.isEmpty) return;
    if (appState == AppLifecycleState.paused || appState == AppLifecycleState.hidden) {
      videoTracks[0].enabled = false;
    } else if (appState == AppLifecycleState.resumed) {
      if (!state.isCameraOff) videoTracks[0].enabled = true;
    }
  }

  // --- UI 控制辅助方法 ---
  void toggleMute() {
    if (_localStream != null && _localStream!.getAudioTracks().isNotEmpty) {
      bool enabled = !_localStream!.getAudioTracks()[0].enabled;
      _localStream!.getAudioTracks()[0].enabled = enabled;
      state = state.copyWith(isMuted: !enabled);
    }
  }

  void toggleCamera() {
    if (_localStream != null && _localStream!.getVideoTracks().isNotEmpty) {
      bool enabled = !_localStream!.getVideoTracks()[0].enabled;
      _localStream!.getVideoTracks()[0].enabled = enabled;
      state = state.copyWith(isCameraOff: !enabled);
    }
  }

  void toggleSpeaker() async {
    if (kIsWeb) return;
    try {
      bool newStatus = !state.isSpeakerOn;
      await Helper.setSpeakerphoneOn(newStatus);
      state = state.copyWith(isSpeakerOn: newStatus);
    } catch (_) {}
  }

  void updateFloatOffset(Offset newOffset) {
    state = state.copyWith(floatOffset: newOffset);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _socketService.socket?.off(SocketEvents.callAccept);
    _socketService.socket?.off(SocketEvents.callIce);
    _socketService.socket?.off(SocketEvents.callEnd);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}