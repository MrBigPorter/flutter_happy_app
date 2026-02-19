
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/constants/socket_events.dart';
import 'package:flutter_app/core/services/socket/socket_service.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/socket_provider.dart';
import '../../../utils/overlay_manager.dart';
import '../models/call_state_model.dart';
import '../services/callkit_service.dart';

// 定义 Provider,持久化
final callControllerProvider = StateNotifierProvider<CallController, CallState>((ref) {
  //把 watch 改为 read，防止 Socket 重连时销毁通话控制器
  final socketService = ref.read(socketServiceProvider);
  return CallController(socketService);
});

class CallController extends StateNotifier<CallState> with WidgetsBindingObserver {


  final SocketService _socketService;

  // RTC 相关对象
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  Timer? _timer;
  int _seconds = 0;
  String? _currentSessionId;
  String? _targetId;
  String? _remoteSdpStr; // 新增：暂时缓存对方发来的 SDP

  String? targetName;
  String? targetAvatar;
  String? get targetId => _targetId;

  // --- 状态锁 ---
  bool _isAccepting = false;  // 防止重复接听
  bool _isHangingUp = false;   // 防止重复挂断
  final Set<String> _recentlyEndedIds = {}; // 幽灵呼叫拦截池


  //  新增：ICE 候选者缓存队列
  final List<RTCIceCandidate> _iceCandidateQueue = [];

  // ICE 服务器配置 (STUN/TURN)
  // 实际生产环境请使用 coturn 搭建的 TURN 服务器，这里用 Google 公共 STUN 演示
   Map<String, dynamic> _iceServers = {
    'iceServers': [
      // 换一个公共 STUN 试试，或者多加几个
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun.miwifi.com:3478'}, // 小米的有时候在国内/华为上更好用
    ],
  };


  CallController(this._socketService) : super(const CallState()) {
    _initSocketListeners();
    _fetchIceCredentials();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(_localStream == null) return;
    final videoTracks = _localStream!.getVideoTracks();
    if (videoTracks.isEmpty) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      //  App 切到后台 / 锁屏：主动暂停视频流发送，防止系统强杀相机
      debugPrint(" [App 生命周期] 切入后台，暂停视频采集");
      videoTracks[0].enabled = false;
    } else if (state == AppLifecycleState.resumed) {
      // 📱 App 回到前台：恢复视频流发送
      debugPrint("[App 生命周期] 回到前台，恢复视频采集");
      // 注意：如果用户本来就手动关了摄像头，这里不要强制打开，可以通过 state 判断
      if (!this.state.isCameraOff) {
        videoTracks[0].enabled = true;
      }
    }
  }

  // 从服务器获取 ICE 服务器列表 (如果有的话)，并更新配置
  Future<void> _fetchIceCredentials() async {
    try{
      final result = await Api.chatIceServers();
      final List<Map<String, dynamic>> iceConfig = [];

      for(var item in result){
        final Map<String, dynamic> map = item.toJson();
        // 重要：清洗掉 null 值。如果 username 为 null，有些 WebRTC 版本会报错
        map.removeWhere((key, value) => value == null || value == "");
        iceConfig.add(map);
      }

      if (iceConfig.isNotEmpty) {
        _iceServers = { 'iceServers': iceConfig };
        debugPrint(" 最终配置: $_iceServers");
      }

    }catch(e){
      debugPrint("Fetch ICE servers error: $e");
    }
  }

  Future<void> _ensureIceServersReady() async {
    // 默认配置里只有 urls，没有 username。如果 username 为空，说明还没拿到 TURN 配置。
    final firstServer = _iceServers['iceServers']?.first;
    bool isDefaultConfig = firstServer['username'] == null || firstServer['username'].isEmpty;
    debugPrint("Checking ICE server config... current config: ${_iceServers['iceServers']}, isDefaultConfig: $isDefaultConfig");
    if(isDefaultConfig){
      // 还在用默认配置，尝试刷新一次
      await _fetchIceCredentials();
    }
  }

  // 配置后台保活
  Future<bool> _enableBackgroundMode() async {
    if (defaultTargetPlatform == TargetPlatform.iOS || kIsWeb) {
      return true;
    }
    final androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "Joyminis Call",
      notificationText: "Call in progress...",
      notificationImportance: AndroidNotificationImportance.normal,
      notificationIcon: const AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
    );

    // 1. 初始化
    bool hasPermissions = await FlutterBackground.initialize(androidConfig: androidConfig);

    // 2. 开启保活 (这会在通知栏显示一个常驻通知)
    if (hasPermissions) {
      return await FlutterBackground.enableBackgroundExecution();
    }
    return false;
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
      await _enableBackgroundMode(); // 接通时启用后台保活
      _startTimer();

      // 接通时重置悬浮窗位置
      state = state.copyWith(floatOffset: Offset(1.sw - 120.w, 60.h));
    });

    // 监听对方的 ICE 候选者 (打洞)
    socket?.on(SocketEvents.callIce, (data) async {
      if(data['sessionId'] != _currentSessionId) return;

      //  核心修复：防御性解析 Candidate
      dynamic rawCandidate = data['candidate'];
      String actualCandidateStr = "";

      if (rawCandidate is Map) {
        // 如果是对象格式，取内部的 candidate 字段
        actualCandidateStr = rawCandidate['candidate'] ?? "";
      } else {
        // 如果本身就是字符串（常见情况），直接转换
        actualCandidateStr = rawCandidate.toString();
      }

      final candidate = RTCIceCandidate(
        actualCandidateStr,
        data['sdpMid'],
        data['sdpMLineIndex'],
      );

      // 打印对方发过来的地址类型
      if (actualCandidateStr.contains("typ relay")) {
        debugPrint("🏆 关键证据：正在通过你的 TURN 服务器中继流量！");
      } else if (actualCandidateStr.contains("typ srflx")) {
        debugPrint("📡 正在通过 STUN 进行 P2P 直连。");
      } else if (actualCandidateStr.contains("typ host")) {
        debugPrint("🏠 局域网直连，不走服务器。");
      }

      if (_peerConnection?.getRemoteDescription() == null) {
        debugPrint(" 远端描述未就绪，先缓存 Candidate");
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
    if (!mounted) return; //  第一道防线：防止在销毁后拨号
    _targetId = targetId;
    _currentSessionId = const Uuid().v4(); // 生成唯一会话 ID


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

      if (!mounted) return; //  异步操作后必须再次检查
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

  // 3. 被叫逻辑 (Incoming Call)
  Future<void> incomingCall(Map<String, dynamic> inviteData) async {
    if (!mounted) return; // 防御

    final sid = inviteData['sessionId'];
    // 核心修复：检查磁盘标记，防止“挂了又响”
    final prefs = await SharedPreferences.getInstance();
    final isEndedOnDisk = prefs.getBool('ended_$sid') ?? false;

    if (_recentlyEndedIds.contains(sid) || isEndedOnDisk) {
      debugPrint("[Controller] 拦截已在内存或磁盘标记结束的呼叫: $sid");
      return;
    }

    _targetId = inviteData['senderId'];
    _currentSessionId = inviteData['sessionId'];
    _remoteSdpStr = inviteData['sdp'];

    targetName = inviteData['senderName'] ?? "Incoming Call";
    targetAvatar = inviteData['senderAvatar'] ?? "";

    final isVideo = inviteData['mediaType'] == 'video';

    // 核心修复：仅仅改变状态，绝对不去调用 _initLocalMedia 和创建 PeerConnection！
    state = state.copyWith(
      status: CallStatus.ringing,
      isVideoMode: isVideo,
    );
  }


  // --- 业务动作 (Action) ---
  void acceptCall() async {
    //  1. 防御：如果正在接听或者已经销毁，直接返回
    if (_isAccepting || !mounted) return;
    _isAccepting = true;

    // 立刻切断 Ringing 状态，强行进入 Connected，消除按钮闪烁
    state = state.copyWith(status: CallStatus.connected);

    if (_peerConnection == null) {
      try {
        await _initLocalMedia(state.isVideoMode);
        await _createPeerConnection();

        if (_remoteSdpStr != null) {
          //  2. 核心修复：必须 await 确保名片贴好了
          await _peerConnection!.setRemoteDescription(
              RTCSessionDescription(_remoteSdpStr!, 'offer')
          );
          _flushIceCandidateQueue();
        }
      } catch (e) {
        debugPrint("Media init error: $e");
        _isAccepting = false; // 出错重置
        hangUp();
        return;
      }
    }

    try {
      // 此时状态已经是合法的 have-remote-offer
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      _socketService.socket?.emit(SocketEvents.callAccept, {
        'sessionId': _currentSessionId,
        'targetId': _targetId,
        'sdp': answer.sdp,
      });

      await _enableBackgroundMode();
      _startTimer();
      state = state.copyWith(floatOffset: Offset(1.sw - 120.w, 60.h));
    } catch (e) {
      debugPrint("Accept process error: $e");
    } finally {
      _isAccepting = false; // 流程走完解锁
    }
  }

  //  WebRTC 内部初始化
  Future<void> _initLocalMedia(bool isVideo) async {

    // 【必须加】告诉 iOS/Android 这是一个 VOIP 通话
    // 这会激活底层的 AudioSession，把模式切到 .voiceChat
    try{
      // 语音通话默认关扬声器(false)，视频默认开(true)
      await Helper.setSpeakerphoneOn(isVideo);
    }catch(e){
      debugPrint("Audio session config error: $e");
    }

    //  修复：使用标准 WebRTC 约束语法 (移除 mandatory/optional)
    final Map<String, dynamic> mediaConstraints = {
      'audio': {
        'echoCancellation': true, // 回声消除
        'noiseSuppression': true, // 降噪
        'autoGainControl': true,  // 自动增益
      },
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

    await _ensureIceServersReady(); // 确保 ICE 服务器配置是最新的

    print("Creating PeerConnection with ICE servers: ${_iceServers['iceServers']}");

    _peerConnection = await createPeerConnection(_iceServers);

    // 添加本地流到 PeerConnection
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    // ICE 候选回调
    _peerConnection?.onIceCandidate = (candidate) {
      if (!mounted) return;
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

    // 还有这个状态改变监听
    _peerConnection!.onConnectionState = (pcState) {
      if (!mounted) return;
      debugPrint("RTCPeerConnection State: $pcState");
    };


    // 远端流回调 (对方画面)
    _peerConnection?.onTrack = (event) {
      if (!mounted) return;
      if (event.streams.isNotEmpty) {
        state.remoteRenderer?.srcObject = event.streams[0];
      // 强制刷新 UI
      state = state.copyWith(remoteRenderer: state.remoteRenderer);
      }
    };
  }

  // 【修改 3】hangUp 增加磁盘写入
  void hangUp({bool emitEvent = true}) async{
    if (_isHangingUp || !mounted) return;
    _isHangingUp = true;
    _timer?.cancel();

   // 终极修复：不再依赖 ID，挂断后立刻开启全局 5 秒免打扰锁
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('global_call_lock', DateTime.now().millisecondsSinceEpoch);

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && FlutterBackground.isBackgroundExecutionEnabled) {
        FlutterBackground.disableBackgroundExecution();
      }
      OverlayManager.instance.hide();
      try {
        if(_currentSessionId != null) CallKitService.instance.endCall(_currentSessionId!);
        CallKitService.instance.clearAllCalls();
      } catch (_) {}
    } catch (_) {}



    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && FlutterBackground.isBackgroundExecutionEnabled) {
        FlutterBackground.disableBackgroundExecution();
      }
      OverlayManager.instance.hide();
      try {
        if(_currentSessionId != null) CallKitService.instance.endCall(_currentSessionId!);
        CallKitService.instance.clearAllCalls();
      } catch (_) {}
    } catch (_) {}

    if(emitEvent && _currentSessionId != null){
      _socketService.socket?.emit(SocketEvents.callEnd, {
        'sessionId': _currentSessionId, 'targetId': _targetId, 'reason': 'hangup',
      });
    }

    final oldLocal = state.localRenderer;
    final oldRemote = state.remoteRenderer;
    state = state.copyWith(localRenderer: null, remoteRenderer: null, status: CallStatus.ended, duration: "00:00");
    _currentSessionId = null;

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
        _isHangingUp = false; // 重置挂断锁
        //  挂断 2 秒后，自动将状态重置为 idle，彻底释放通话通道
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && state.status == CallStatus.ended) {
            state = state.copyWith(status: CallStatus.idle);
          }
        });
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

  void toggleSpeaker() async{
    if(kIsWeb) return; // Web 不支持扬声器切换

    try{
      // 1. 计算新状态
      bool newStatus = !state.isSpeakerOn;
      // 2. 【必须加】调用硬件接口切换输出设备
      await Helper.setSpeakerphoneOn(newStatus);

      // 需要 flutter_webrtc Helper 支持，暂时只改状态
      state = state.copyWith(isSpeakerOn: !state.isSpeakerOn);
    }catch(e){
      debugPrint("Toggle speaker error: $e");
    }

  }

  void updateFloatOffset(Offset newOffset) {
    state = state.copyWith(floatOffset: newOffset);
  }

  // 修改 call_controller.dart

  void _startTimer() {
    // 1. 防御：先取消可能存在的旧定时器
    _timer?.cancel();

    // 2. 核心修复：重置计数器！否则第二次通话会接着上次的时间跑，或者出现逻辑错误
    _seconds = 0;

    debugPrint("⏰ 计时器启动...");

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // 3. 累加
      _seconds++;

      // 4. 格式化
      final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
      final seconds = (_seconds % 60).toString().padLeft(2, '0');
      final timeStr = "$minutes:$seconds";

      // 5. 只有状态是 Connected 时才更新 UI (避免挂断后还在跑)
      if (state.status == CallStatus.connected) {
        state = state.copyWith(duration: timeStr);
      } else {
        timer.cancel(); // 如果状态不对，自动停止
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

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }
}