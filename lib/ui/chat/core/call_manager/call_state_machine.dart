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

final callStateMachineProvider = StateNotifierProvider<CallStateMachine, CallState>((ref) {
  final socketService = ref.read(socketServiceProvider);
  return CallStateMachine(socketService);
});

class CallStateMachine extends StateNotifier<CallState> with WidgetsBindingObserver {
  final SocketService _socketService;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final List<RTCIceCandidate> _iceCandidateQueue = [];

  Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun.miwifi.com:3478'},
    ],
  };

  bool _isAccepting = false;
  bool _isHangingUp = false;
  Timer? _timer;
  int _seconds = 0;

  CallStateMachine(this._socketService) : super(CallState.initial()) {
    WidgetsBinding.instance.addObserver(this);
    _fetchIceCredentials();
    _initSocketListeners();
    _initCallKitListeners();
  }

  void _initCallKitListeners() {
    CallKitService.instance.onAction('StateMachine', (event) {
      debugPrint("📱 [CallKit] 收到系统指令: ${event.action}");
      switch (event.action) {
        case 'answerCall':
          if (_isAccepting || state.status == CallStatus.connected) return;
          acceptCall();
          break;
        case 'endCall':
          if (_isHangingUp || state.status == CallStatus.idle) return;
          hangUp(emitEvent: true);
          break;
        case 'setMuted':
          toggleMute();
          break;
      }
    });
  }

  Future<void> startCall(String targetId, {bool isVideo = true}) async {
    if (state.status != CallStatus.idle || !mounted) return;
    final sessionId = const Uuid().v4();

    try {
      await _initLocalMedia(isVideo);
      await _createPeerConnection();

      final offer = await _peerConnection!.createOffer();

      //  修正 1：必须把【原封不动】的 offer 喂给本地，保证本地绝对不崩！
      await _peerConnection!.setLocalDescription(offer);

      //  修正 2：对发往网络的字符串动刀子，套上 VP8 护盾！
      final String tweakedSdp = _forceVP8(offer.sdp!);

      _socketService.socket?.emit(SocketEvents.callInvite, {
        'sessionId': sessionId,
        'targetId': targetId,
        'sdp': tweakedSdp, // 发送修改后的安全 SDP 给对方
        'mediaType': isVideo ? 'video' : 'audio',
      });

      if (mounted) {
        state = state.copyWith(
          status: CallStatus.dialing,
          sessionId: sessionId,
          targetId: targetId,
          isVideoMode: isVideo,
          floatOffset: Offset(240.w, 100.h),
        );
      }
    } catch (e) {
      debugPrint("❌ [StateMachine] 拨号失败: $e");
      hangUp(emitEvent: false);
    }
  }

  void onIncomingInvite(CallEvent event) {
    if ((state.status != CallStatus.idle && state.sessionId != event.sessionId) ||
        state.status == CallStatus.ended) {
      _timer?.cancel();
      _isAccepting = false;
      _isHangingUp = false;
      state = CallState.initial();
    }

    if (state.status != CallStatus.idle) return;

    state = state.copyWith(
      status: CallStatus.ringing,
      sessionId: event.sessionId,
      targetId: event.senderId,
      targetName: event.senderName,
      targetAvatar: event.senderAvatar,
      isVideoMode: event.isVideo,
      remoteSdp: event.rawData['sdp']?.toString(),
    );
  }

  Future<void> acceptCall() async {
    if (state.status != CallStatus.ringing || _isAccepting || !mounted) return;
    _isAccepting = true;

    final localRenderer = RTCVideoRenderer();
    await localRenderer.initialize();
    final remoteRenderer = RTCVideoRenderer();
    await remoteRenderer.initialize();

    state = state.copyWith(
      status: CallStatus.connected,
      localRenderer: localRenderer,
      remoteRenderer: remoteRenderer,
    );

    Future<void> setupWebRTCFlow() async {
      try {
        await _initLocalMedia(state.isVideoMode);
        await _createPeerConnection();

        final incomingSdp = state.remoteSdp;
        if (incomingSdp != null && incomingSdp.isNotEmpty) {
          await _peerConnection!.setRemoteDescription(RTCSessionDescription(incomingSdp, 'offer'));
          _flushIceCandidateQueue();
        } else {
          hangUp();
          return;
        }

        final answer = await _peerConnection!.createAnswer();

        //  修正 3：原汁原味的 answer 留给自己用
        await _peerConnection!.setLocalDescription(answer);

        //  修正 4：魔改后的 SDP 发给对方
        final String tweakedSdp = _forceVP8(answer.sdp!);

        _socketService.socket?.emit(SocketEvents.callAccept, {
          'sessionId': state.sessionId,
          'targetId': state.targetId,
          'sdp': tweakedSdp, // 发送修改后的 SDP
        });

        await _enableBackgroundMode();
        _startTimer();
        state = state.copyWith(floatOffset: Offset(1.sw - 120.w, 60.h));
      } catch (e) {
        debugPrint("❌ [StateMachine] WebRTC 建立失败: $e");
        hangUp();
      } finally {
        _isAccepting = false;
      }
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint(" [StateMachine] iOS 极速启动媒体流...");
      await setupWebRTCFlow();
    } else {
      debugPrint("🤖 [StateMachine] Android 延迟 1 秒启动...");
      Future.delayed(const Duration(milliseconds: 1000), () async {
        if (mounted && state.status == CallStatus.connected) {
          await setupWebRTCFlow();
        } else {
          _isAccepting = false;
        }
      });
    }
  }

  void hangUp({bool emitEvent = true}) async {
    if (_isHangingUp || state.status == CallStatus.idle || state.status == CallStatus.ended || !mounted) return;

    _isHangingUp = true;
    _timer?.cancel();
    _isAccepting = false;

    state = state.copyWith(status: CallStatus.ended);

    if (emitEvent && state.sessionId != null) {
      _socketService.socket?.emit(SocketEvents.callEnd, {
        'sessionId': state.sessionId, 'targetId': state.targetId, 'reason': 'hangup',
      });
      await CallArbitrator.instance.markSessionAsEnded(state.sessionId!);
      await CallArbitrator.instance.lockGlobalCooldown();
    }

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && FlutterBackground.isBackgroundExecutionEnabled) {
        FlutterBackground.disableBackgroundExecution();
      }
      OverlayManager.instance.hide();
      CallKitService.instance.endCall(state.sessionId ?? '');
      CallKitService.instance.clearAllCalls();
    } catch (_) {}

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
        _iceCandidateQueue.clear();
      } catch (_) {} finally {
        _isHangingUp = false;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && state.status == CallStatus.ended) {
            state = CallState.initial();
          }
        });
      }
    });
  }

  void _initSocketListeners() {
    final socket = _socketService.socket;

    socket?.on(SocketEvents.callAccept, (data) async {
      if (data['sessionId'] != state.sessionId || state.status == CallStatus.ended || _isHangingUp) return;
      if (_peerConnection?.signalingState == RTCSignalingState.RTCSignalingStateStable) return;

      try {
        final answerSdp = data['sdp'];
        await _peerConnection?.setRemoteDescription(RTCSessionDescription(answerSdp, 'answer'));
        _flushIceCandidateQueue();

        state = state.copyWith(
          status: CallStatus.connected,
          remoteSdp: answerSdp,
        );
        await _enableBackgroundMode();
        _startTimer();
        state = state.copyWith(floatOffset: Offset(1.sw - 120.w, 60.h));
      } catch (e) {
        debugPrint("❌ [StateMachine] 应用 Answer SDP 失败: $e");
      }
    });

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

    socket?.on(SocketEvents.callEnd, (data) {
      if (data['sessionId'] == state.sessionId) hangUp(emitEvent: false);
    });
  }

  Future<void> _initLocalMedia(bool isVideo) async {
    try {
      await Helper.setSpeakerphoneOn(isVideo);
    } catch (_) {}

    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': isVideo ? { 'facingMode': 'user' } : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    //  终极自愈护盾：如果画板是空的，立刻当场新建！
    // 这完美解决了 iOS 打电话出去时没有初始化画板导致的黑屏问题！
    RTCVideoRenderer localRen = state.localRenderer ?? RTCVideoRenderer();
    RTCVideoRenderer remoteRen = state.remoteRenderer ?? RTCVideoRenderer();

    if (state.localRenderer == null) await localRen.initialize();
    if (state.remoteRenderer == null) await remoteRen.initialize();

    localRen.srcObject = _localStream;

    // 更新状态，绑定画板
    state = state.copyWith(
      localRenderer: localRen,
      remoteRenderer: remoteRen,
      isCameraOff: !isVideo,
    );
  }

  Future<void> _createPeerConnection() async {
    await _ensureIceServersReady();
    _peerConnection = await createPeerConnection(_iceServers);

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    _peerConnection?.onIceConnectionState = (state) {
      debugPrint(" [ICE State] 变更为: $state");
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        hangUp(emitEvent: true);
      }
    };

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

    _peerConnection?.onAddStream = (MediaStream stream) {
      debugPrint("🎥 [StateMachine] onAddStream: 拿到完整流，视频轨数量: ${stream.getVideoTracks().length}");
      if (!mounted) return;
      state.remoteRenderer?.srcObject = stream;
      state = state.copyWith(duration: "00:00 ");
    };

    _peerConnection?.onTrack = (event) {
      debugPrint("🎥 [StateMachine] onTrack 触发: ${event.track.kind}");
      if (!mounted) return;

      if (event.streams.isNotEmpty) {
        state.remoteRenderer?.srcObject = event.streams[0];
        state = state.copyWith(duration: "00:00  ");
      } else {
        MediaStream? currentStream = state.remoteRenderer?.srcObject;
        if (currentStream != null) {
          currentStream.addTrack(event.track);
          state.remoteRenderer?.srcObject = currentStream;
          state = state.copyWith(duration: "00:00   ");
        }
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
      notificationTitle: "Lucky IM Call",
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

  // 终极核武器：修改 SDP 字符串，强行禁用硬件 H264，回退到极其稳定的 VP8 软解！
  String _forceVP8(String sdp) {
    return sdp.replaceAll('H264/90000', 'DISABLED-H264/90000');
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