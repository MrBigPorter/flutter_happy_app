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
      debugPrint("[StateMachine] Received hardware route change notification, UI state synchronized to speaker: $isSpeakerOn");
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
        // Shield against accidental disconnects
        // Intercept iOS system hang-up commands triggered by hardware changes (e.g., putting AirPods back)
        if (state.status == CallStatus.connected && _media.isDeviceJustChanged) {
          debugPrint("[StateMachine] AirPods/Hardware change detected, intercepting accidental iOS system hang-up command");
          return;
        }

        // Standard hang-up logic (manual button press or remote hang-up)
        if (!_isHangingUp && state.status != CallStatus.idle) {
          if (incomingSessionId == state.sessionId) {
            hangUp(emitEvent: true);
          }
        }
      }

      if (event.action == 'setMuted') toggleMute();
    });
  }

  // ================= Core Process: Outgoing Call =================
  Future<void> startCall(String targetId, {bool isVideo = true}) async {
    if (_isHangingUp) {
      debugPrint("[StateMachine] Cleaning up hardware from previous call, please try again later");
      return;
    }

    if (state.status != CallStatus.idle) {
      debugPrint("[StateMachine] Residual state detected before dialing (${state.status}), forcing reset");
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

      // Core Fix: Record targetId and state before generating SDP
      // Prevents WebRTC engine from discarding ICE candidates due to missing target metadata
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

      final tweakedSdp = await _webrtc.createOfferAndSetLocal();
      _signaling.emitInvite(
        sessionId: sessionId,
        targetId: targetId,
        sdp: tweakedSdp,
        isVideo: isVideo,
      );

    } catch (e) {
      debugPrint("[StateMachine] Dialing failed significantly: $e");
      hangUp(emitEvent: false);
    }
  }

  void onIncomingInvite(CallEvent event) async {
    if (event.rawData['isRenegotiation'] == true &&
        state.sessionId == event.sessionId &&
        state.status == CallStatus.connected) {
      debugPrint("[ICE Restart] Intercepted renegotiation signal on Invite channel");
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
        debugPrint("[ICE Restart] Callee successfully responded with Answer");

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _webrtc.flushIceCandidateQueue();
        });
      } catch (e) {
        debugPrint("[ICE Restart] Negotiation failed: $e");
      }
      return;
    }

    if (state.status == CallStatus.ended ||
        (state.status != CallStatus.idle && state.sessionId != event.sessionId)) {
      debugPrint("[StateMachine] New incoming call detected, forcing cleanup of old session: ${state.sessionId}");
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

  // ================= Core Process: Hang Up =================
  void hangUp({bool emitEvent = true}) async {
    if (_isHangingUp ||
        state.status == CallStatus.idle ||
        state.status == CallStatus.ended ||
        !mounted)
      return;

    _isHangingUp = true;

    // Core Fix: Capture current sessionId before state is cleared
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

    // Core Fix: Physical cleanup of CallKit must be awaited
    try {
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          FlutterBackground.isBackgroundExecutionEnabled) {
        FlutterBackground.disableBackgroundExecution();
      }
      OverlayManager.instance.hide();

      debugPrint("[StateMachine] Preparing to disconnect CallKit... Session: $currentSessionId");
      if (currentSessionId != null && currentSessionId.isNotEmpty) {
        await CallKitService.instance.endCall(currentSessionId);
      }
      debugPrint("[StateMachine] CallKit system UI terminated");
    } catch (e) {
      debugPrint("[StateMachine] CallKit cleanup failed: $e");
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
      debugPrint("[ICE Candidate] Found new route: ${candidate.candidate}");
      _signaling.emitIce(
        sessionId: state.sessionId!,
        targetId: state.targetId!,
        candidate: candidate,
      );
    };

    _webrtc.onAddStream = (stream) {
      if (!mounted) return;
      debugPrint("[WebRTC] Received remote stream. Track count: ${stream.getTracks().length}");
      state.remoteRenderer?.srcObject = stream;
      state = state.copyWith(duration: "00:00 ");
    };

    _webrtc.onTrack = (event) {
      if (!mounted) return;
      debugPrint("[WebRTC] Received remote track. Type: ${event.track.kind}");

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
      debugPrint("[WebRTC-ICE] Physical channel state changed to: ${iceState.toString()}");

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
    debugPrint("[ICE Restart] Performing seamless network reconnection...");

    try {
      final tweakedSdp = await _webrtc.createOfferAndSetLocal(iceRestart: true);
      _signaling.emitAccept(
        sessionId: state.sessionId!,
        targetId: state.targetId!,
        sdp: tweakedSdp,
        isRenegotiation: true,
      );
    } catch (e) {
      debugPrint("[ICE Restart] Reconnection failed: $e");
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