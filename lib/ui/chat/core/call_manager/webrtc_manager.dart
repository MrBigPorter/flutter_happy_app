import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_app/common.dart';

class WebRTCManager {
  RTCPeerConnection? peerConnection;
  final List<RTCIceCandidate> _iceCandidateQueue = [];

  Map<String, dynamic> iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  // 引擎向外输出的事件钩子
  void Function(RTCIceConnectionState)? onIceConnectionState;
  void Function(RTCIceCandidate)? onIceCandidate;
  void Function(MediaStream)? onAddStream;
  void Function(RTCTrackEvent)? onTrack;

  Future<void> ensureIceServersReady() async {
    try {
      final result = await Api.chatIceServers();
      final List<Map<String, dynamic>> iceConfig = [];
      for (var item in result) {
        final Map<String, dynamic> map = item.toJson();
        map.removeWhere((key, value) => value == null || value == "");
        iceConfig.add(map);
      }
      if (iceConfig.isNotEmpty) iceServers = {'iceServers': iceConfig};
    } catch (_) {}
  }

  Future<void> createConnection(MediaStream? localStream) async {
    await ensureIceServersReady();
    peerConnection = await createPeerConnection(iceServers);

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream);
    });

    peerConnection?.onIceConnectionState = (state) =>
        onIceConnectionState?.call(state);
    peerConnection?.onIceCandidate = (candidate) =>
        onIceCandidate?.call(candidate);
    peerConnection?.onAddStream = (stream) => onAddStream?.call(stream);
    peerConnection?.onTrack = (event) => onTrack?.call(event);
  }

  Future<String> createOfferAndSetLocal({bool iceRestart = false}) async {
    if (peerConnection == null) throw Exception("PeerConnection is null");

    // 🟢 终极杀手锏：必须用这种 'mandatory' 和 'optional' 数组的古老格式，
    // Android 底层的 MediaConstraints 才能真正识别 IceRestart 指令！
    final Map<String, dynamic> constraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': [
        // 注意：必须是大写的 'IceRestart'，并且包在数组里！
        if (iceRestart) {'IceRestart': true},
      ],
    };

    try {
      debugPrint("🛠️ [WebRTCManager] 正在生成 Offer，是否重启 ICE: $iceRestart");

      RTCSessionDescription offer = await peerConnection!.createOffer(constraints);
      await peerConnection!.setLocalDescription(offer);

      return offer.sdp!;
    } catch (e) {
      debugPrint("❌ [WebRTCManager] 生成 Offer 失败: $e");
      rethrow;
    }
  }

  //  生成原味 Answer 喂给自己，返回带护盾的魔改 SDP
  Future<String> createAnswerAndSetLocal() async {
    final answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);
    return _forceVP8(answer.sdp!);
  }

  Future<void> setRemoteDescription(String sdp, String type) async {
    await peerConnection?.setRemoteDescription(
      RTCSessionDescription(sdp, type),
    );
  }

  void addIceCandidate(RTCIceCandidate candidate) {
    if (peerConnection == null || peerConnection?.getRemoteDescription() == null) {
      _iceCandidateQueue.add(candidate);
      return;
    }

    // 2. 如果到了，尝试添加。在 Web 端必须使用 try-catch + catchError 双重护盾拦截异步崩溃！
    try {
      peerConnection!.addCandidate(candidate).catchError((e) {
        debugPrint(" [WebRTC] 异步添加 ICE 失败，放回队列等待重试: $e");
        _iceCandidateQueue.add(candidate);
      });
    } catch (e) {
      debugPrint("️ [WebRTC] 同步添加 ICE 失败，放回队列: $e");
      _iceCandidateQueue.add(candidate);
    }
  }

  void flushIceCandidateQueue() {
    if (_iceCandidateQueue.isEmpty ||
        peerConnection?.getRemoteDescription() == null)
      return;
    for (var candidate in _iceCandidateQueue) {
      peerConnection?.addCandidate(candidate);
    }
    _iceCandidateQueue.clear();
  }

  //  硬件编码降级护盾
  String _forceVP8(String sdp) {
    //  Web 浏览器和 iOS 的硬件解码能力极强，强行抹除 H264 反而会导致浏览器黑屏！
    // 如果是 Web 或者是 iOS，直接原封不动返回 SDP
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS) {
      return sdp;
    }
    // 只有安卓才会执行降级
    return sdp.replaceAll('H264/90000', 'DISABLED-H264/90000');
  }

  Future<void> dispose() async {
    onIceConnectionState = null;
    onIceCandidate = null;
    onAddStream = null;
    onTrack = null;

    await peerConnection?.close();
    await peerConnection?.dispose();
    peerConnection = null;
    _iceCandidateQueue.clear();
  }
}
