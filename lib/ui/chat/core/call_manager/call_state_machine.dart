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
    _signaling = SignalingManager(socketService);
    WidgetsBinding.instance.addObserver(this);
    _initSocketListeners();
    _initCallKitListeners();
  }

  void _initCallKitListeners() {
    CallKitService.instance.onAction('StateMachine', (event) {
      if (event.action == 'answerCall' &&
          !_isAccepting &&
          state.status != CallStatus.connected)
        acceptCall();
      if (event.action == 'endCall' &&
          !_isHangingUp &&
          state.status != CallStatus.idle)
        hangUp(emitEvent: true);
      if (event.action == 'setMuted') toggleMute();
    });
  }

  // ================= 核心流程：拨打 =================
  Future<void> startCall(String targetId, {bool isVideo = true}) async {
    if (state.status != CallStatus.idle || !mounted) return;
    final sessionId = const Uuid().v4();

    try {
      _isCaller = true;

      // 1. 挂载物理硬件
      await _media.configureAudioSession(isVideo, () => state.isMuted);

      final localRenderer = RTCVideoRenderer();
      final remoteRenderer = RTCVideoRenderer();

      //  补丁 1：拨打方也要显式预热，防止 DOM 找不到
      await Future.wait([
        localRenderer.initialize(),
        remoteRenderer.initialize(),
      ]);

      await _media.initLocalMedia(isVideo, localRenderer, remoteRenderer);

      // 2. 挂载底层引擎并绑定监听
      _bindWebRTCEvents();
      await _webrtc.createConnection(_media.localStream);

      // 3. 生成带护盾的 SDP 并发信令
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
      debugPrint(" [StateMachine] 拨号失败: $e");
      hangUp(emitEvent: false);
    }
  }

  void onIncomingInvite(CallEvent event) async {
    // 1. 处理 ICE 重连逻辑 (保持不变)
    if (event.rawData['isRenegotiation'] == true) {
      if (state.sessionId == event.sessionId &&
          state.status == CallStatus.connected) {
        try {
          await _webrtc.setRemoteDescription(event.rawData['sdp'], 'offer');
          final tweakedSdp = await _webrtc.createAnswerAndSetLocal();
          _signaling.emitAccept(
            sessionId: state.sessionId!,
            targetId: state.targetId!,
            sdp: tweakedSdp,
            isRenegotiation: true,
          );
        } catch (e) {
          debugPrint(" [ICE Restart] 接收方协商失败: $e");
        }
      }
      return;
    }

    //  核心修复：如果当前是 ended 或者是另一个 sessionId 的老电话，立即强制重置状态
    if (state.status == CallStatus.ended ||
        (state.status != CallStatus.idle &&
            state.sessionId != event.sessionId)) {
      debugPrint("[StateMachine] 检测到新来电，正在物理强制清理旧 Session: ${state.sessionId}");
      _resetStateFlags();
      state = CallState.initial(); // 强制归位，允许新来电进入
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

  // ================= 核心流程：接听 =================
  Future<void> acceptCall() async {
    if (state.status != CallStatus.ringing || _isAccepting || !mounted) return;
    _isAccepting = true;
    _isCaller = false;

    //  1. 核心修复：创建画板后，必须先执行 initialize()！
    // 这一步在 Web 端会立即创建出 HTML 的 <video> 标签，耗时极短（约2毫秒）。
    final localRenderer = RTCVideoRenderer();
    final remoteRenderer = RTCVideoRenderer();
    await Future.wait([
      localRenderer.initialize(),
      remoteRenderer.initialize(),
    ]);

    //  2. 画板底层节点就绪后，立刻切状态到 connected 交给 UI 挂载！
    // 因为预先 initialize 过，Web UI 渲染时就能完美咬合底层的 DOM 节点了。
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

        // 此处的 initLocalMedia 会发现 textureId 已经不为空，直接绑定本地媒体流，本地画面瞬间亮起！
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

      // 补丁 3：防休眠起搏器
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

        //  补丁 3：防休眠起搏器
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
          // 这里直接赋值即可，不要置为 null 了
          state.remoteRenderer?.srcObject = currentStream;
        }
      }
      state = state.copyWith(duration: "00:00  ");
    };

    _webrtc.onTrack = (event) {
      if (!mounted) return;
      debugPrint(" [WebRTC] 收到远端轨道！类型: ${event.track.kind}");
      if (event.streams.isNotEmpty) {
        final stream = event.streams[0];
        //  防撞车锁：优先使用 onTrack，同样严禁重复挂载！
        state.remoteRenderer?.srcObject = stream;
        state = state.copyWith(duration: "00:00  ");

        //  Web 端物理外挂
        if (kIsWeb) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              //  先置空，再赋值
              state.remoteRenderer?.srcObject = null;
              state.remoteRenderer?.srcObject = stream;
            }
          });
        }
      } else {
        MediaStream? currentStream = state.remoteRenderer?.srcObject;
        if (currentStream != null) {
          currentStream.addTrack(event.track);
          //  非常关键：即使是手机端，也必须先置空再赋值，否则遇到网络卡顿也容易黑屏
          state.remoteRenderer?.srcObject = null;
          state.remoteRenderer?.srcObject = currentStream;
        }
      }
      state = state.copyWith(duration: "00:00  ");

      //  Web 端外挂
      if (kIsWeb) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && event.streams.isNotEmpty) {
            state.remoteRenderer?.srcObject = event.streams[0];
          }
        });
      }
    };

    _webrtc.onIceConnectionState = (iceState) {
      if (iceState == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          iceState == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        _iceDisconnectTimer?.cancel();
        _iceDisconnectTimer = Timer(const Duration(seconds: 3), () {
          if (_webrtc.peerConnection?.iceConnectionState ==
                  RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
              _webrtc.peerConnection?.iceConnectionState ==
                  RTCIceConnectionState.RTCIceConnectionStateFailed) {
            if (_isCaller) _triggerIceRestart();
          }
        });
        Timer(const Duration(seconds: 30), () {
          if (this.state.status == CallStatus.connected &&
              (_webrtc.peerConnection?.iceConnectionState ==
                      RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
                  _webrtc.peerConnection?.iceConnectionState ==
                      RTCIceConnectionState.RTCIceConnectionStateFailed)) {
            hangUp(emitEvent: true);
          }
        });
      } else if (iceState ==
              RTCIceConnectionState.RTCIceConnectionStateConnected ||
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
        _isRestartingIce)
      return;
    _isRestartingIce = true;
    try {
      final tweakedSdp = await _webrtc.createOfferAndSetLocal(iceRestart: true);
      _signaling.emitInvite(
        sessionId: state.sessionId!,
        targetId: state.targetId!,
        sdp: tweakedSdp,
        isVideo: state.isVideoMode,
        isRenegotiation: true,
      );
    } catch (_) {
    } finally {
      Future.delayed(
        const Duration(seconds: 10),
        () => _isRestartingIce = false,
      );
    }
  }

  void _initSocketListeners() {
    _signaling.listenEvents(
      onAccept: (data) async {
        if (data['sessionId'] != state.sessionId ||
            state.status == CallStatus.ended ||
            _isHangingUp)
          return;
        if (_webrtc.peerConnection?.signalingState ==
            RTCSignalingState.RTCSignalingStateStable)
          return;
        try {
          await _webrtc.setRemoteDescription(data['sdp'], 'answer');
          // 延迟 100ms 冲刷，彻底解决 Web 端的 ICE InvalidState 崩溃
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) _webrtc.flushIceCandidateQueue();
          });

          if (data['isRenegotiation'] == true) return;

          state = state.copyWith(
            status: CallStatus.connected,
            remoteSdp: data['sdp'],
          );
          // 补丁 2：主叫方收到接听后，给沉睡了的 Web 解码器一脚“物理重启”！
          if (kIsWeb) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted && state.remoteRenderer?.srcObject != null) {
                final stream = state.remoteRenderer!.srcObject;
                state.remoteRenderer!.srcObject = null; // 先拔掉
                state.remoteRenderer!.srcObject = stream; // 重新插上，强制唤醒浏览器！
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
    _callStartTime = DateTime.now(); // 记录接通那一刻的绝对时间

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.status == CallStatus.connected && _callStartTime != null) {
        // 每次循环都计算绝对差值，无论浏览器怎么休眠，时间都是准的
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
  }

  @override
  void dispose() {
    _resetStateFlags();
    _signaling.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
