import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_app/common.dart';

class WebRTCManager {
  RTCPeerConnection? peerConnection;
  final List<RTCIceCandidate> _iceCandidateQueue = [];

  // Internal flag to track if the remote session description is successfully set
  bool _isRemoteDescriptionSet = false;

  Map<String, dynamic> iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  // Event hooks exported by the engine
  void Function(RTCIceConnectionState)? onIceConnectionState;
  void Function(RTCIceCandidate)? onIceCandidate;
  void Function(MediaStream)? onAddStream;
  void Function(RTCTrackEvent)? onTrack;

  // Fetch updated ICE server configurations from the API
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

  // Create a new PeerConnection and attach local tracks
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

  // Generate an Offer and set it as the local description
  Future<String> createOfferAndSetLocal({bool iceRestart = false}) async {
    if (peerConnection == null) throw Exception("PeerConnection is null");

    // Using legacy mandatory/optional format for Android MediaConstraints compatibility with IceRestart
    final Map<String, dynamic> constraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': [
        if (iceRestart) {'IceRestart': true},
      ],
    };

    try {
      debugPrint("[WebRTCManager] Generating Offer, ICE Restart: $iceRestart");

      RTCSessionDescription offer = await peerConnection!.createOffer(constraints);
      await peerConnection!.setLocalDescription(offer);

      return offer.sdp!;
    } catch (e) {
      debugPrint("[WebRTCManager] Failed to generate Offer: $e");
      rethrow;
    }
  }

  // Generate an Answer and set it as local description, returning the SDP
  Future<String> createAnswerAndSetLocal() async {
    final answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);
    return _forceVP8(answer.sdp!);
  }

  // Set the remote session description and update the internal flag
  Future<void> setRemoteDescription(String sdp, String type) async {
    await peerConnection?.setRemoteDescription(
      RTCSessionDescription(sdp, type),
    );
    _isRemoteDescriptionSet = true;
  }

  // Add ICE candidates, queuing them if the remote description isn't set yet
  void addIceCandidate(RTCIceCandidate candidate) {
    // Core Fix: Use the internal flag instead of getRemoteDescription() to avoid sync issues
    if (peerConnection == null || !_isRemoteDescriptionSet) {
      _iceCandidateQueue.add(candidate);
      return;
    }

    try {
      peerConnection!.addCandidate(candidate).catchError((e) {
        debugPrint("[WebRTC] Async add ICE candidate failed, queuing for retry: $e");
        _iceCandidateQueue.add(candidate);
      });
    } catch (e) {
      debugPrint("[WebRTC] Sync add ICE candidate failed, queuing: $e");
      _iceCandidateQueue.add(candidate);
    }
  }

  // Apply all queued ICE candidates once the connection is ready
  void flushIceCandidateQueue() {
    // Intercept with internal flag to ensure tunnel is ready before pushing candidates
    if (_iceCandidateQueue.isEmpty || !_isRemoteDescriptionSet) {
      return;
    }
    for (var candidate in _iceCandidateQueue) {
      peerConnection?.addCandidate(candidate).catchError((e){
        debugPrint("[WebRTC] Failed to flush ICE candidate from queue: $e");
      });
    }
    _iceCandidateQueue.clear();
  }

  // Hardware encoding downgrade shield
  String _forceVP8(String sdp) {
    // Keep original SDP for Web and iOS as they have strong hardware H264 support
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS) {
      return sdp;
    }
    // Downgrade H264 only for Android devices to ensure compatibility
    return sdp.replaceAll('H264/90000', 'DISABLED-H264/90000');
  }

  // Clean up resources and reset flags
  Future<void> dispose() async {
    onIceConnectionState = null;
    onIceCandidate = null;
    onAddStream = null;
    onTrack = null;

    // Reset internal flag to prevent state leakage in subsequent calls
    _isRemoteDescriptionSet = false;

    await peerConnection?.close();
    await peerConnection?.dispose();
    peerConnection = null;
    _iceCandidateQueue.clear();
  }
}