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

      if (event.action == 'endCall' &&
          !_isHangingUp &&
          state.status != CallStatus.idle) {
        if (incomingSessionId == state.sessionId) {
          hangUp(emitEvent: true);
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

      final tweakedSdp = await _webrtc.createOfferAndSetLocal();
      _signaling.emitInvite(
        sessionId: sessionId,
        targetId: targetId,
        sdp: tweakedSdp,
        isVideo: isVideo,
      );

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
    } catch (e) {
      debugPrint(" [StateMachine] 拨号严重失败: $e");
      hangUp(emitEvent: false);
    }
  }

  void onIncomingInvite(CallEvent event) async {
    //  终极护盾：拦截被后端或 FCM 强行篡改成 invite 的重连信令！
    // 只要是当前 Session 的，且带 isRenegotiation 标志，绝对不能当成普通来电扔掉！
    if (event.rawData['isRenegotiation'] == true &&
        state.sessionId == event.sessionId &&
        state.status == CallStatus.connected) {
      debugPrint(" [ICE Restart] 在 Invite 推送通道拦截到重协商信令...");
      try {
        await _webrtc.setRemoteDescription(event.rawData['sdp'], 'offer');

        // 必须回传 Answer
        final answer = await _webrtc.peerConnection!.createAnswer();
        await _webrtc.peerConnection!.setLocalDescription(answer);

        _signaling.emitAccept(
          sessionId: state.sessionId!,
          targetId: state.targetId!,
          sdp: answer.sdp!,
          isRenegotiation: true,
        );
        debugPrint(" [ICE Restart] 被叫方已成功回复 Answer！");

        //  极其关键：冲刷候选者队列，把新网络 IP 灌入底层！
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _webrtc.flushIceCandidateQueue();
        });
      } catch (e) {
        debugPrint(" [ICE Restart] 协商失败: $e");
      }
      return; //  处理完重连直接退出，严禁往下走！
    }

    // ================= 以下是正常新来电逻辑 =================

    // 如果当前是 ended 或者是另一个 sessionId 的老电话，立即强制重置状态
    if (state.status == CallStatus.ended ||
        (state.status != CallStatus.idle && state.sessionId != event.sessionId)) {
      debugPrint("[StateMachine] 检测到新来电，正在物理强制清理旧 Session: ${state.sessionId}");
      _resetStateFlags();
      state = CallState.initial();
    }

    // 就是这句话之前把重连信令杀了，现在我们在上面已经拦截，安全了！
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

  // ================= 核心流程：接听 =================
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
    _resetStateFlags();
    state = state.copyWith(status: CallStatus.ended);

    if (emitEvent && state.sessionId != null) {
      _signaling.emitEnd(
        sessionId: state.sessionId!,
        targetId: state.targetId ?? '',
        reason: 'hangup',
      );
      await CallArbitrator.instance.markSessionAsEnded(state.sessionId!);
      await CallArbitrator.instance.lockGlobalCooldown();
    }

    try {
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          FlutterBackground.isBackgroundExecutionEnabled) {
        FlutterBackground.disableBackgroundExecution();
      }
      OverlayManager.instance.hide();
      CallKitService.instance.endCall(state.sessionId ?? '');
      CallKitService.instance.clearAllCalls();
    } catch (_) {}

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

  // ================= 引擎绑定与重连 =================
  void _bindWebRTCEvents() {
    _webrtc.onIceCandidate = (candidate) {
      if (!mounted || state.targetId == null) return;

      debugPrint("[ICE Candidate] 发现新路线: ${candidate.candidate}");

      _signaling.emitIce(
        sessionId: state.sessionId!,
        targetId: state.targetId!,
        candidate: candidate,
      );
    };

    _webrtc.onAddStream = (stream) {
      if (!mounted) return;
      debugPrint(" [WebRTC] 收到远端媒体流！轨数量: ${stream.getTracks().length}");

      state.remoteRenderer?.srcObject = stream;
      state = state.copyWith(duration: "00:00 ");

      if (kIsWeb) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            state.remoteRenderer?.srcObject = null;
            state.remoteRenderer?.srcObject = stream;
          }
        });
      }
    };

    _webrtc.onTrack = (event) {
      if (!mounted) return;
      debugPrint(" [WebRTC] 收到远端轨道！类型: ${event.track.kind}");

      if (event.streams.isNotEmpty) {
        state.remoteRenderer?.srcObject = event.streams[0];

        if (kIsWeb) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              state.remoteRenderer?.srcObject = null;
              state.remoteRenderer?.srcObject = event.streams[0];
            }
          });
        }
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
      //  极其重要的探针：监控底层 WebRTC 的真实物理连通性！
      debugPrint(" [WebRTC-ICE] 底层物理通道状态变更为: ${iceState.toString()}");

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
    // 1. 只有主叫方(_isCaller)有资格发起重连
    if (!_isCaller ||
        state.status != CallStatus.connected ||
        _webrtc.peerConnection == null ||
        _isRestartingIce) {
      return;
    }

    //  终极防空转护盾：如果 Socket 还没连上（说明物理网络还没彻底准备好），
    // 坚决不能此时生成 Offer！否则会收集到无网状态下的废弃 IP！
    if (_socketService.socket?.connected != true) {
      debugPrint(" [ICE Restart] 物理网络尚未就绪，拒绝收集空 IP，等待 Socket 连通...");
      return;
    }

    _isRestartingIce = true;
    debugPrint(" [ICE Restart] 正在执行无缝网络重连，生成新 IP 简历...");

    try {
      final tweakedSdp = await _webrtc.createOfferAndSetLocal(iceRestart: true);
      _signaling.emitAccept(
        sessionId: state.sessionId!,
        targetId: state.targetId!,
        sdp: tweakedSdp,
        isRenegotiation: true,
      );
    } catch (e) {
      debugPrint(" [ICE Restart] 生成新简历失败: $e");
    } finally {
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted) _isRestartingIce = false;
      });
    }
  }

  void _initSocketListeners() {
    //  终极救命补丁：只要 Socket 断开，立刻强行砸碎 15 秒重连防抖锁！
    // 防止旧网络发出的“废弃 Offer”锁死新网络的重连通道！
    _socketService.socket?.on('disconnect', (_) {
      if (mounted) {
        debugPrint(" [Socket] 物理断线！立刻解除防抖锁，等待新网络就绪...");
        _isRestartingIce = false;
      }
    });
    // 毫秒级网络切换雷达
    _socketService.socket?.on('connect', (_) {
      if (mounted && state.status == CallStatus.connected && !_isRestartingIce) {
        debugPrint(" [StateMachine] 嗅探到新网络连通，延迟 2 秒等待网卡彻底初始化...");
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

        //  终极修复：精确区分主叫与被叫的 SDP 处理方式，彻底告别 have-local-offer 崩溃！
        if (data['isRenegotiation'] == true) {
          debugPrint(" [ICE Restart] 收到对方的重协商信令...");
          try {
            if (_isCaller) {
              // 我是主叫：我发出了 Offer，现在收到了对方的 Answer！
              await _webrtc.setRemoteDescription(data['sdp'], 'answer');
              debugPrint(" [ICE Restart] 主叫方成功应用 Answer，底层隧道重建完毕！");
            } else {
              // 我是被叫：我收到了主叫发来的 Offer！
              await _webrtc.setRemoteDescription(data['sdp'], 'offer');

              // 必须立刻生成 Answer 传回去，绝不能再生成 Offer！
              final answer = await _webrtc.peerConnection!.createAnswer();
              await _webrtc.peerConnection!.setLocalDescription(answer);

              _signaling.emitAccept(
                sessionId: state.sessionId!,
                targetId: state.targetId!,
                sdp: answer.sdp!,
                isRenegotiation: true,
              );
              debugPrint(" [ICE Restart] 被叫方已成功回复 Answer！");
            }
          } catch (e) {
            debugPrint(" [ICE Restart] 协商失败: $e");
          }
          return; // 重协商完毕，退出！
        }

        // ================== 下面是正常的首次接听逻辑 ==================
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

          if (kIsWeb) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted && state.remoteRenderer?.srcObject != null) {
                final stream = state.remoteRenderer!.srcObject;
                state.remoteRenderer!.srcObject = null;
                state.remoteRenderer!.srcObject = stream;
              }
            });
          }

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
          RTCIceCandidate(
            actualCandidateStr,
            data['sdpMid'],
            data['sdpMLineIndex'],
          ),
        );
      },
      onEnd: (data) {
        if (data['sessionId'] == state.sessionId) hangUp(emitEvent: false);
      },
    );
  }

  // ================= UI 与外围辅助 =================
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
      notificationIcon: const AndroidResource(
        name: 'ic_launcher',
        defType: 'mipmap',
      ),
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
    state = state.copyWith(isSpeakerOn: newState);
  }

  void updateFloatOffset(Offset newOffset) =>
      state = state.copyWith(floatOffset: newOffset);

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    _media.handleAppLifecycleState(appState, state.isCameraOff);

    if (appState == AppLifecycleState.resumed && state.status == CallStatus.connected) {
      debugPrint("📱 [StateMachine] App 恢复前台，执行【心脏电击】物理唤醒被冻结的解码器...");

      // 延迟 500 毫秒等待 Android 画布就绪
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (!mounted) return;

        final local = state.localRenderer?.srcObject;
        final remote = state.remoteRenderer?.srcObject;

        // 1. 物理拔插画板
        if (local != null) {
          state.localRenderer?.srcObject = null;
          state.localRenderer?.srcObject = local;
          // ⚡ 电击本地视频轨：关掉再瞬间打开，强迫摄像头和编码器重启！
          if (local.getVideoTracks().isNotEmpty) {
            local.getVideoTracks().first.enabled = false;
            await Future.delayed(const Duration(milliseconds: 100));
            local.getVideoTracks().first.enabled = true;
          }
        }

        if (remote != null) {
          state.remoteRenderer?.srcObject = null;
          state.remoteRenderer?.srcObject = remote;
          // ⚡ 电击远端视频轨：强迫远端重新请求关键帧！
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