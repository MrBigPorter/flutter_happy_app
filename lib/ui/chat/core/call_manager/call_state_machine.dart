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
  late final dynamic _socketService; // 【本次修改】：保存底层 Socket 引擎，用于监听物理断网
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
    // 【本次修改】：在这里把传进来的 socketService 存起来
    _socketService = socketService;
    _signaling = SignalingManager(socketService);
    WidgetsBinding.instance.addObserver(this);
    _initSocketListeners();
    _initCallKitListeners();
  }

  void _initCallKitListeners() {
    CallKitService.instance.onAction('StateMachine', (event) {
      // 获取系统传回来的真实 ID
      final incomingSessionId = event.data?['id']?.toString();

      if (event.action == 'answerCall' &&
          !_isAccepting &&
          state.status != CallStatus.connected) {
        acceptCall();
      }

      if (event.action == 'endCall' &&
          !_isHangingUp &&
          state.status != CallStatus.idle) {
        // 核心防误杀护盾 1：必须确认系统挂断的是“当前的电话”！
        // 坚决防止旧电话的延迟信号，把新电话给错杀了！
        if (incomingSessionId == state.sessionId) {
          hangUp(emitEvent: true);
        }
      }

      if (event.action == 'setMuted') toggleMute();
    });
  }

  // ================= 核心流程：拨打 =================
  Future<void> startCall(String targetId, {bool isVideo = true}) async {
    //  护盾 1：严防竞态崩溃！如果上一个电话的硬件还在异步清理中，坚决拦截新拨号！
    if (_isHangingUp) {
      debugPrint("⏳ [StateMachine] 正在清理上一个通话底层硬件，请稍后重试拨打...");
      return;
    }

    //  护盾 2：物理复位！如果因为网络抖动导致状态机卡在 ended 或其他非 idle 状态，强行清空！
    if (state.status != CallStatus.idle) {
      debugPrint(" [StateMachine] 拨号前发现状态机遗留异常 (${state.status})，强行复位！");
      _resetStateFlags();
      state = CallState.initial();
    }

    if (!mounted) return;
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
      debugPrint("❌ [StateMachine] 拨号严重失败: $e");
      hangUp(emitEvent: false);
    }
  }

  void onIncomingInvite(CallEvent event) async {

    // 如果当前是 ended 或者是另一个 sessionId 的老电话，立即强制重置状态
    if (state.status == CallStatus.ended ||
        (state.status != CallStatus.idle && state.sessionId != event.sessionId)) {
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

    _webrtc.onIceConnectionState = (iceState) {
      if (iceState == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          iceState == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        _iceDisconnectTimer?.cancel();
        _iceDisconnectTimer = Timer(const Duration(seconds: 3), () {
          if (_webrtc.peerConnection?.iceConnectionState ==
                  RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
              _webrtc.peerConnection?.iceConnectionState ==
                  RTCIceConnectionState.RTCIceConnectionStateFailed) {
            // 【本次修改】：去掉了 if(_isCaller) 的限制。谁断网谁就立刻发重连！
            _triggerIceRestart();
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
    //  极强防抖：如果正在重连，或者状态不是 connected，坚决拒绝！
    if (state.status != CallStatus.connected ||
        _webrtc.peerConnection == null ||
        _isRestartingIce) {
      return;
    }

    _isRestartingIce = true;
    debugPrint(" [ICE Restart] 正在执行无缝网络重连，生成新 IP 简历...");

    try {
      final tweakedSdp = await _webrtc.createOfferAndSetLocal(iceRestart: true);
      //  核心改变：用 emitAccept 带着 isRenegotiation 去做纯粹的“重协商”，千万别用 emitInvite 伪装拨号了！
      _signaling.emitAccept(
        sessionId: state.sessionId!,
        targetId: state.targetId!,
        sdp: tweakedSdp,
        isRenegotiation: true,
      );
    } catch (e) {
      debugPrint(" [ICE Restart] 生成新简历失败: $e");
    } finally {
      //  给重连雷达加上 5 秒的冷却期，防止 Socket 频繁抖动引发死循环
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) _isRestartingIce = false;
      });
    }
  }

  void _initSocketListeners() {
    //  毫秒级网络切换雷达（加上了 !_isRestartingIce 防抖限制）
    _socketService.socket?.on('connect', (_) {
      if (mounted && state.status == CallStatus.connected && !_isRestartingIce) {
        debugPrint(" [StateMachine] 嗅探到物理网络切换 (Socket 极速重连)，立即触发 ICE Restart!");
        _triggerIceRestart();
      }
    });

    _signaling.listenEvents(
      onAccept: (data) async {
        if (data['sessionId'] != state.sessionId ||
            state.status == CallStatus.ended ||
            _isHangingUp)
          return;

        //  纯粹的重协商分支（网络切换时走这里）
        if (data['isRenegotiation'] == true) {
          debugPrint(" [ICE Restart] 收到对方的新网络简历，开始更新底座...");
          try {
            await _webrtc.setRemoteDescription(data['sdp'], 'offer');
            final tweakedSdp = await _webrtc.createAnswerAndSetLocal();
            // 把我的新简历回传过去
            _signaling.emitAccept(
              sessionId: state.sessionId!,
              targetId: state.targetId!,
              sdp: tweakedSdp,
              isRenegotiation: true,
            );
          } catch (e) {
            debugPrint(" [ICE Restart] 协商失败: $e");
          }
          return; // 重协商结束，坚决退出，不能往下走去重置 UI 状态！
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
