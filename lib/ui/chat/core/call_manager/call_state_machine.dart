import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/chat/core/call_manager/signaling_manager.dart';
import 'package:flutter_app/ui/chat/core/call_manager/webrtc_manager.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_app/core/providers/socket_provider.dart';
import 'package:flutter_app/utils/overlay_manager.dart';
import 'package:flutter_app/ui/chat/models/call_event.dart';
import 'package:flutter_app/ui/chat/models/call_state_model.dart';
import 'package:flutter_app/ui/chat/core/call_manager/callkit_service.dart';
import 'media_manager.dart';
import 'storage/call_arbitrator.dart';

final callStateMachineProvider =
StateNotifierProvider<CallStateMachine, CallState>((ref) {
  final socketService = ref.read(socketServiceProvider);
  return CallStateMachine(socketService);
});

class CallStateMachine extends StateNotifier<CallState>
    with WidgetsBindingObserver {
  late final SignalingManager _signaling;
  late final dynamic _socketService;
  final MediaManager _media = MediaManager();
  final WebRTCManager _webrtc = WebRTCManager();

  bool _isAccepting = false;
  bool _isHangingUp = false;
  bool _isCaller = false;
  bool _isRestartingIce = false;

  Timer? _timer;
  Timer? _iceDisconnectTimer;
  DateTime? _callStartTime;

  CallStateMachine(socketService) : super(CallState.initial()) {
    _socketService = socketService;
    _signaling = SignalingManager(socketService);
    WidgetsBinding.instance.addObserver(this);

    _media.onSpeakerStateChanged = (bool isSpeakerOn) {
      if (!mounted) return;
      state = state.copyWith(isSpeakerOn: isSpeakerOn);
      debugPrint("📢 [StateMcachine] 收到底层硬件路由变更通知，UI 状态已同步为外放: $isSpeakerOn");
    };

    _initSocketListeners();
    _initCallKitListeners();
  }

  void _initCallKitListeners() {
    CallKitService.instance.onAction('StateMachine', (event) {
      final incomingSessionId = event.data?['id']?.toString();

      if (event.action == 'answerCall' &&
          !_isAccepting &&
          state.status != CallStatus.connected) {
        acceptCall();
      }

      if (event.action == 'endCall') {
        // ️ 终极防误杀护盾启动！
        // 如果当前是通话中，并且刚好检测到 AirPods 刚被放回（2秒内有硬件变动）
        if (state.status == CallStatus.connected && _media.isDeviceJustChanged) {
          debugPrint(" [StateMachine] 检测到 AirPods 刚放回，精准拦截 iOS 系统的误挂断指令！");
          return; //  直接拦截，绝不执行下面的 hangUp！
        }

        // 正常的挂断逻辑（比如你按了红色的挂断按钮，或者对方挂断）
        if (!_isHangingUp && state.status != CallStatus.idle) {
          if (incomingSessionId == state.sessionId) {
            hangUp(emitEvent: true);
          }
        }
      }

      if (event.action == 'setMuted') toggleMute();
    });
  }

  // ================= 核心流程：拨打 =================
  Future<void> startCall(String targetId, {bool isVideo = true}) async {
    if (_isHangingUp) {
      debugPrint(" [StateMachine] 正在清理上一个通话底层硬件，请稍后重试拨打...");
      return;
    }

    if (state.status != CallStatus.idle) {
      debugPrint(" [StateMachine] 拨号前发现状态机遗留异常 (${state.status})，强行复位！");
      _resetStateFlags();
      state = CallState.initial();
    }

    if (!mounted) return;
    final sessionId = const Uuid().v4();

    try {
      _isCaller = true;

      await _media.configureAudioSession(isVideo, () => state.isMuted);

      final localRenderer = RTCVideoRenderer();
      final remoteRenderer = RTCVideoRenderer();

      await Future.wait([
        localRenderer.initialize(),
        remoteRenderer.initialize(),
      ]);

      await _media.initLocalMedia(isVideo, localRenderer, remoteRenderer);

      _bindWebRTCEvents();
      await _webrtc.createConnection(_media.localStream);

      // 🎯 核心修复 1：必须在生成 SDP 之前，先把 targetId 记入账本！
      // 否则 WebRTC 引擎拿到网络 IP 后，发现没有 targetId，会把 IP 丢弃！
      if (mounted) {
        state = state.copyWith(
          status: CallStatus.dialing,
          sessionId: sessionId,
          targetId: targetId,
          isVideoMode: isVideo,
          localRenderer: localRenderer,
          remoteRenderer: remoteRenderer,
          floatOffset: Offset(240.w, 100.h),
        );
      }

      // 记完账，再生成 SDP（此时会瞬间触发 onIceCandidate）
      final tweakedSdp = await _webrtc.createOfferAndSetLocal();
      _signaling.emitInvite(
        sessionId: sessionId,
        targetId: targetId,
        sdp: tweakedSdp,
        isVideo: isVideo,
      );

    } catch (e) {
      debugPrint("❌ [StateMachine] 拨号严重失败: $e");
      hangUp(emitEvent: false);
    }
  }

  void onIncomingInvite(CallEvent event) async {
    if (event.rawData['isRenegotiation'] == true &&
        state.sessionId == event.sessionId &&
        state.status == CallStatus.connected) {
      debugPrint("🔄 [ICE Restart] 在 Invite 推送通道拦截到重协商信令...");
      try {
        await _webrtc.setRemoteDescription(event.rawData['sdp'], 'offer');

        final answer = await _webrtc.peerConnection!.createAnswer();
        await _webrtc.peerConnection!.setLocalDescription(answer);

        _signaling.emitAccept(
          sessionId: state.sessionId!,
          targetId: state.targetId!,
          sdp: answer.sdp!,
          isRenegotiation: true,
        );
        debugPrint("✅ [ICE Restart] 被叫方已成功回复 Answer！");

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _webrtc.flushIceCandidateQueue();
        });
      } catch (e) {
        debugPrint("❌ [ICE Restart] 协商失败: $e");
      }
      return;
    }

    if (state.status == CallStatus.ended ||
        (state.status != CallStatus.idle && state.sessionId != event.sessionId)) {
      debugPrint("🧹 [StateMachine] 检测到新来电，正在物理强制清理旧 Session: ${state.sessionId}");
      _resetStateFlags();
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
    _isCaller = false;

    final localRenderer = RTCVideoRenderer();
    final remoteRenderer = RTCVideoRenderer();
    await Future.wait([
      localRenderer.initialize(),
      remoteRenderer.initialize(),
    ]);

    state = state.copyWith(
      status: CallStatus.connected,
      localRenderer: localRenderer,
      remoteRenderer: remoteRenderer,
      duration: "00:00",
    );

    Future<void> setupWebRTCFlow() async {
      try {
        await _media.configureAudioSession(
          state.isVideoMode,
              () => state.isMuted,
        );

        await _media.initLocalMedia(
          state.isVideoMode,
          localRenderer,
          remoteRenderer,
        );

        _bindWebRTCEvents();
        await _webrtc.createConnection(_media.localStream);

        if (state.remoteSdp != null && state.remoteSdp!.isNotEmpty) {
          await _webrtc.setRemoteDescription(state.remoteSdp!, 'offer');
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) _webrtc.flushIceCandidateQueue();
          });
        } else {
          hangUp();
          return;
        }

        final tweakedSdp = await _webrtc.createAnswerAndSetLocal();
        _signaling.emitAccept(
          sessionId: state.sessionId!,
          targetId: state.targetId!,
          sdp: tweakedSdp,
        );

        await _enableBackgroundMode();
        _startTimer();
        state = state.copyWith(floatOffset: Offset(1.sw - 120.w, 60.h));
      } catch (e) {
        hangUp();
      } finally {
        _isAccepting = false;
      }
    }

    if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS) {
      await setupWebRTCFlow();
    } else {
      Future.delayed(const Duration(milliseconds: 1000), () async {
        if (mounted && state.status == CallStatus.connected) {
          await setupWebRTCFlow();
        } else {
          _isAccepting = false;
        }
      });
    }
  }

  // ================= 核心流程：挂断 =================
  void hangUp({bool emitEvent = true}) async {
    if (_isHangingUp ||
        state.status == CallStatus.idle ||
        state.status == CallStatus.ended ||
        !mounted)
      return;

    _isHangingUp = true;

    // 🎯 核心修复 2：在 state 被清空前，死死攥住当前的 sessionId！
    final currentSessionId = state.sessionId;

    _resetStateFlags();
    state = state.copyWith(status: CallStatus.ended);

    if (emitEvent && currentSessionId != null) {
      _signaling.emitEnd(
        sessionId: currentSessionId,
        targetId: state.targetId ?? '',
        reason: 'hangup',
      );
      await CallArbitrator.instance.markSessionAsEnded(currentSessionId);
      await CallArbitrator.instance.lockGlobalCooldown();
    }

    // 🎯 核心修复 3：物理强制清理 CallKit，并且必须用 await 等待！
    try {
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          FlutterBackground.isBackgroundExecutionEnabled) {
        FlutterBackground.disableBackgroundExecution();
      }
      OverlayManager.instance.hide();

      debugPrint("🛑 [StateMachine] 准备拔管 CallKit... Session: $currentSessionId");
      if (currentSessionId != null && currentSessionId.isNotEmpty) {
        await CallKitService.instance.endCall(currentSessionId);
      }
      //await CallKitService.instance.clearAllCalls();
      debugPrint("✅ [StateMachine] CallKit 系统界面已被彻底击杀！");
    } catch (e) {
      debugPrint("❌ [StateMachine] CallKit 清理失败: $e");
    }

    final oldLocal = state.localRenderer;
    final oldRemote = state.remoteRenderer;
    state = state.copyWith(
      localRenderer: null,
      remoteRenderer: null,
      duration: "00:00",
    );

    Future.microtask(() async {
      try {
        await _media.dispose();
        await _webrtc.dispose();
        if (oldLocal != null) await oldLocal.dispose();
        if (oldRemote != null) await oldRemote.dispose();
      } catch (_) {
      } finally {
        _isHangingUp = false;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && state.status == CallStatus.ended)
            state = CallState.initial();
        });
      }
    });
  }

  void _bindWebRTCEvents() {
    _webrtc.onIceCandidate = (candidate) {
      if (!mounted || state.targetId == null) return;
      debugPrint("📡 [ICE Candidate] 发现新路线: ${candidate.candidate}");
      _signaling.emitIce(
        sessionId: state.sessionId!,
        targetId: state.targetId!,
        candidate: candidate,
      );
    };

    _webrtc.onAddStream = (stream) {
      if (!mounted) return;
      debugPrint("📺 [WebRTC] 收到远端媒体流！轨数量: ${stream.getTracks().length}");
      state.remoteRenderer?.srcObject = stream;
      state = state.copyWith(duration: "00:00 ");
    };

    _webrtc.onTrack = (event) {
      if (!mounted) return;
      debugPrint("🎞️ [WebRTC] 收到远端轨道！类型: ${event.track.kind}");

      if (event.streams.isNotEmpty) {
        state.remoteRenderer?.srcObject = event.streams[0];
      } else {
        MediaStream? currentStream = state.remoteRenderer?.srcObject;
        if (currentStream != null) {
          currentStream.addTrack(event.track);
          state.remoteRenderer?.srcObject = currentStream;
        }
      }
      state = state.copyWith(duration: "00:00  ");
    };

    _webrtc.onIceConnectionState = (iceState) {
      debugPrint("🔌 [WebRTC-ICE] 底层物理通道状态变更为: ${iceState.toString()}");

      if (iceState == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          iceState == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        _iceDisconnectTimer?.cancel();
        _iceDisconnectTimer = Timer(const Duration(seconds: 3), () {
          if (_webrtc.peerConnection?.iceConnectionState ==
              RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
              _webrtc.peerConnection?.iceConnectionState ==
                  RTCIceConnectionState.RTCIceConnectionStateFailed) {

            if (_socketService.socket?.connected == true) {
              _triggerIceRestart();
            }
          }
        });
      } else if (iceState == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          iceState == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _iceDisconnectTimer?.cancel();
        _isRestartingIce = false;
      }
    };
  }

  Future<void> _triggerIceRestart() async {
    if (!_isCaller ||
        state.status != CallStatus.connected ||
        _webrtc.peerConnection == null ||
        _isRestartingIce) {
      return;
    }

    if (_socketService.socket?.connected != true) return;

    _isRestartingIce = true;
    debugPrint("🔄 [ICE Restart] 正在执行无缝网络重连...");

    try {
      final tweakedSdp = await _webrtc.createOfferAndSetLocal(iceRestart: true);
      _signaling.emitAccept(
        sessionId: state.sessionId!,
        targetId: state.targetId!,
        sdp: tweakedSdp,
        isRenegotiation: true,
      );
    } catch (e) {
      debugPrint("❌ [ICE Restart] 重连失败: $e");
    } finally {
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted) _isRestartingIce = false;
      });
    }
  }

  void _initSocketListeners() {
    _socketService.socket?.on('disconnect', (_) {
      if (mounted) {
        _isRestartingIce = false;
      }
    });

    _socketService.socket?.on('connect', (_) {
      if (mounted && state.status == CallStatus.connected && !_isRestartingIce) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && state.status == CallStatus.connected && !_isRestartingIce) {
            _triggerIceRestart();
          }
        });
      }
    });

    _signaling.listenEvents(
      onAccept: (data) async {
        if (data['sessionId'] != state.sessionId ||
            state.status == CallStatus.ended ||
            _isHangingUp)
          return;

        if (data['isRenegotiation'] == true) {
          try {
            if (_isCaller) {
              await _webrtc.setRemoteDescription(data['sdp'], 'answer');
            } else {
              await _webrtc.setRemoteDescription(data['sdp'], 'offer');
              final answer = await _webrtc.peerConnection!.createAnswer();
              await _webrtc.peerConnection!.setLocalDescription(answer);

              _signaling.emitAccept(
                sessionId: state.sessionId!,
                targetId: state.targetId!,
                sdp: answer.sdp!,
                isRenegotiation: true,
              );
            }
          } catch (e) {}
          return;
        }

        if (_webrtc.peerConnection?.signalingState == RTCSignalingState.RTCSignalingStateStable) return;

        try {
          await _webrtc.setRemoteDescription(data['sdp'], 'answer');
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) _webrtc.flushIceCandidateQueue();
          });

          state = state.copyWith(
            status: CallStatus.connected,
            remoteSdp: data['sdp'],
          );

          await _enableBackgroundMode();
          _startTimer();
          state = state.copyWith(floatOffset: Offset(1.sw - 120.w, 60.h));
        } catch (_) {}
      },
      onIce: (data) {
        if (data['sessionId'] != state.sessionId) return;
        dynamic rawCandidate = data['candidate'];
        String actualCandidateStr = rawCandidate is Map
            ? (rawCandidate['candidate'] ?? "")
            : rawCandidate.toString();
        _webrtc.addIceCandidate(
          RTCIceCandidate(actualCandidateStr, data['sdpMid'], data['sdpMLineIndex']),
        );
      },
      onEnd: (data) {
        if (data['sessionId'] == state.sessionId) hangUp(emitEvent: false);
      },
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _callStartTime = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.status == CallStatus.connected && _callStartTime != null) {
        final duration = DateTime.now().difference(_callStartTime!);
        final minutes = duration.inMinutes.toString().padLeft(2, '0');
        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
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

  void _resetStateFlags() {
    _timer?.cancel();
    _iceDisconnectTimer?.cancel();
    _isAccepting = false;
    _isHangingUp = false;
  }

  void toggleMute() {
    bool newState = !state.isMuted;
    _media.toggleMute(newState);
    state = state.copyWith(isMuted: newState);
  }

  void toggleCamera() {
    bool newState = !state.isCameraOff;
    _media.toggleCamera(newState);
    state = state.copyWith(isCameraOff: newState);
  }

  void toggleSpeaker() async {
    bool newState = !state.isSpeakerOn;
    await _media.toggleSpeaker(newState);
  }

  void updateFloatOffset(Offset newOffset) =>
      state = state.copyWith(floatOffset: newOffset);

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    _media.handleAppLifecycleState(appState, state.isCameraOff);
    if (appState == AppLifecycleState.resumed && state.status == CallStatus.connected) {
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (!mounted) return;
        final local = state.localRenderer?.srcObject;
        final remote = state.remoteRenderer?.srcObject;

        if (local != null) {
          state.localRenderer?.srcObject = null;
          state.localRenderer?.srcObject = local;
          if (local.getVideoTracks().isNotEmpty) {
            local.getVideoTracks().first.enabled = false;
            await Future.delayed(const Duration(milliseconds: 100));
            local.getVideoTracks().first.enabled = true;
          }
        }
        if (remote != null) {
          state.remoteRenderer?.srcObject = null;
          state.remoteRenderer?.srcObject = remote;
          if (remote.getVideoTracks().isNotEmpty) {
            remote.getVideoTracks().first.enabled = false;
            await Future.delayed(const Duration(milliseconds: 100));
            remote.getVideoTracks().first.enabled = true;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _resetStateFlags();
    _signaling.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}