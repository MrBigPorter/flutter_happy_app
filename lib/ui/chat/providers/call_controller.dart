
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/socket_events.dart';
import 'package:flutter_app/core/services/socket/socket_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/socket_provider.dart';
import '../models/call_state_model.dart';

// 定义 Provider,持久化
final callControllerProvider = StateNotifierProvider<CallController, CallState>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return CallController(socketService);
});

class CallController extends StateNotifier<CallState> {
  final SocketService _socketService;

  // RTC 相关对象
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  Timer? _timer;
  int _seconds = 0;
  String? _currentSessionId;
  String? _targetId;

  //  新增：ICE 候选者缓存队列
  final List<RTCIceCandidate> _iceCandidateQueue = [];

  // ICE 服务器配置 (STUN/TURN)
  // 实际生产环境请使用 coturn 搭建的 TURN 服务器，这里用 Google 公共 STUN 演示
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      // 换一个公共 STUN 试试，或者多加几个
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun.miwifi.com:3478'}, // 小米的有时候在国内/华为上更好用
    ],
  };

  CallController(this._socketService) : super(const CallState()) {
    _initSocketListeners();
  }

  //  1. Socket 监听 (接电话线)
  void _initSocketListeners(){
    final socket = _socketService.socket;
    
    // 监听来电请求
    socket?.on(SocketEvents.callAccept, (data) async {
      if(data['sessionId'] != _currentSessionId) return; // 只处理当前会话的事件

      final sdp = RTCSessionDescription(data['sdp'], 'answer'); // 注意变量名拼写 sdb -> sdp
      await _peerConnection?.setRemoteDescription(sdp);

      //  核心修复 1：设置完 SDP 后，立即处理堆积的 ICE 候选者
      _flushIceCandidateQueue();

      state = state.copyWith(status: CallStatus.connected);
      _startTimer();

      // 接通时重置悬浮窗位置
      state = state.copyWith(floatOffset: Offset(1.sw - 120.w, 60.h));
    });

    // 监听对方的 ICE 候选者 (打洞)
    socket?.on(SocketEvents.callIce, (data) async {
      if(data['sessionId'] != _currentSessionId) return; // 只处理当前会话的事件

      final candidate = RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      );
      //  核心修复 2：如果还没设置远端描述，先存队列；否则直接添加
      if (_peerConnection?.getRemoteDescription() == null) {
        debugPrint("❄️ ICE 收到太早，加入队列缓存");
        _iceCandidateQueue.add(candidate);
      } else {
        await _peerConnection?.addCandidate(candidate);
      }
    });

      // 监听挂断事件
    socket?.on(SocketEvents.callEnd, (data) {
      if(data['sessionId'] != _currentSessionId) return; // 只处理当前会话的事件
      // 对方挂断了，结束通话
      hangUp(emitEvent: false);
    });
  }

  //  2. 主叫逻辑 (Start Call)
  Future<void> startCall(String targetId, {bool isVideo = true}) async {
    _targetId = targetId;
    _currentSessionId = const Uuid().v4(); // 生成唯一会话 ID

    print('Starting call to $targetId with session ID $_currentSessionId');

    try{
      // 打开麦克风和摄像头
      await _initLocalMedia(isVideo);

      // 创建 PeerConnection
      await _createPeerConnection();

      // 3. 生成 Offer
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      // 4. 通过 Socket 发送呼叫请求和 SDP
      _socketService.socket?.emit(SocketEvents.callInvite, {
        'sessionId': _currentSessionId,
        'targetId': targetId,
        'sdp': offer.sdp,
        'mediaType': isVideo ? 'video' : 'audio',
      });

      // 更新 UI
      state = state.copyWith(
        status: CallStatus.dialing,
        isVideoMode: isVideo,
        floatOffset: Offset(240.w, 100.h),
      );
    }catch(e){
      debugPrint("Call start error: $e");
      // 发生错误，清理资源并重置状态
      hangUp(emitEvent: false);
    }
  }

  //3. 被叫逻辑 (Incoming Call)
  Future<void> incomingCall(Map<String, dynamic> inviteData) async {
    _targetId = inviteData['senderId'];
    _currentSessionId = inviteData['sessionId'];
    final remoteSdp = inviteData['sdp'];
    final isVideo = inviteData['mediaType'] == 'video';

    //  核心修复 3：立即更新状态为 ringing
    // 防止 CallPage 的 initState 误以为是 idle 而再次调用 startCall
    state = state.copyWith(status: CallStatus.ringing);

    try{
      await _initLocalMedia(isVideo);
      await _createPeerConnection();

      // 设置对方的名片
      final sdp = RTCSessionDescription(remoteSdp, 'offer');
      await _peerConnection!.setRemoteDescription(sdp);

      // 2. 名片设置好了，现在可以安全地处理刚才堆积的 ICE 候选者了
      _flushIceCandidateQueue();



      // 更新 UI 显示来电界面
      state = state.copyWith(
        status: CallStatus.ringing,
        isVideoMode: isVideo,
      );
    }catch(e){
      debugPrint("Incoming call error: $e");
      hangUp(emitEvent: true);
    }
  }

  // --- 业务动作 (Action) ---

  void acceptCall() async{
    if(_peerConnection == null) return;

    try{
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      _socketService.socket?.emit(SocketEvents.callAccept, {
        'sessionId': _currentSessionId,
        'targetId': _targetId,
        'sdp': answer.sdp,
      });

      state = state.copyWith(status: CallStatus.connected);
      _startTimer();

       // 接通时重置悬浮窗位置
      state = state.copyWith(floatOffset: Offset(1.sw - 120.w, 60.h));

    }catch(e){
      debugPrint("Accept call error: $e");
    }
  }

  //  WebRTC 内部初始化
  Future<void> _initLocalMedia(bool isVideo) async {
    //  修复：使用标准 WebRTC 约束语法 (移除 mandatory/optional)
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': isVideo
          ? {
        // 想要前置摄像头
        'facingMode': 'user',

        // 分辨率和帧率使用 ideal (理想值)，这样如果设备不支持也不会报错，而是降级
        'width': {'ideal': 640},
        'height': {'ideal': 480},
        'frameRate': {'ideal': 30},
      }
          : false,
    };

    // 打开本地媒体设备
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    
    print("Local media stream initialized with ${_localStream?.getVideoTracks().length ?? 0} video tracks and ${_localStream?.getAudioTracks().length ?? 0} audio tracks.");

    // 初始化本地渲染器
    final localRenderer = RTCVideoRenderer();
    await localRenderer.initialize();
    localRenderer.srcObject = _localStream;

    // 初始化远端渲染器（先不绑定流，等对方接通后再绑定）
    final remoteRenderer = RTCVideoRenderer();
    await remoteRenderer.initialize();

    state = state.copyWith(
      localRenderer: localRenderer,
      remoteRenderer: remoteRenderer,
    );
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceServers);

    // 添加本地流到 PeerConnection
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    // ICE 候选回调
    _peerConnection?.onIceCandidate = (candidate) {
      if(_targetId != null){
        _socketService.socket?.emit(SocketEvents.callIce, {
          'sessionId': _currentSessionId,
          'targetId': _targetId,
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    // 远端流回调 (对方画面)
    _peerConnection?.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        state.remoteRenderer?.srcObject = event.streams[0];
      // 强制刷新 UI
      state = state.copyWith(remoteRenderer: state.remoteRenderer);
      }
    };
  }

  //  挂断与安全销毁 (Safe Dispose)
  void hangUp({bool emitEvent = true}) {
    // 1. 停止计时器
    _timer?.cancel();

    // 1. 通知服务器
    if(emitEvent && _currentSessionId != null){
      _socketService.socket?.emit(SocketEvents.callEnd, {
        'sessionId': _currentSessionId,
        'targetId': _targetId,
        'reason': 'hangup',
      });
    }

    // 2. 核心防御：先脱钩 (Detach)
    final oldLocal = state.localRenderer;
    final oldRemote = state.remoteRenderer;

    state = state.copyWith(
      localRenderer: null, // 先置空状态中的渲染器，防止 UI 访问到已销毁的渲染器
      remoteRenderer: null,
      status: CallStatus.ended,
    );

    // 3. 异步销毁 (Dispose)
    Future.microtask(() async {
      try {
        _localStream?.getTracks().forEach((track) => track.stop());
        await _localStream?.dispose();

        await _peerConnection?.close();
        _peerConnection = null;

        oldLocal?.srcObject = null;
        await oldLocal?.dispose();

        oldRemote?.srcObject = null;
        await oldRemote?.dispose();
      } catch (e) {
        debugPrint("Resource dispose error: $e");
      }
    });


  }

  // --- 辅助功能 ---
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

  void toggleSpeaker() {
    // 需要 flutter_webrtc Helper 支持，暂时只改状态
    state = state.copyWith(isSpeakerOn: !state.isSpeakerOn);
  }

  void updateFloatOffset(Offset newOffset) {
    state = state.copyWith(floatOffset: newOffset);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds++;
      final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
      final seconds = (_seconds % 60).toString().padLeft(2, '0');
      if (state.status != CallStatus.ended) {
        state = state.copyWith(duration: "$minutes:$seconds");
      }
    });
  }

  void _flushIceCandidateQueue() {
    if (_iceCandidateQueue.isEmpty) return;

    //  双重保险：再检查一次是否真的准备好了
    if (_peerConnection?.getRemoteDescription() == null) {
      debugPrint("️ 尝试清空队列，但 RemoteDescription 仍为空，跳过");
      return;
    }

    debugPrint("❄️ 处理缓存的 ${_iceCandidateQueue.length} 个 ICE 候选者");
    for (var candidate in _iceCandidateQueue) {
      _peerConnection?.addCandidate(candidate);
    }
    _iceCandidateQueue.clear();
  }

  @override
  void dispose() {
    _timer?.cancel();

    // 移除 Socket 监听 (防止内存泄漏)
    _socketService.socket?.off(SocketEvents.callAccept);
    _socketService.socket?.off(SocketEvents.callIce);
    _socketService.socket?.off(SocketEvents.callEnd);

    // 兜底销毁
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