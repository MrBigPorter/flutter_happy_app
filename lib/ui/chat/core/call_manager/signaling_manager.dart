import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_app/core/constants/socket_events.dart';
import 'package:flutter_app/core/services/socket/socket_service.dart';

class SignalingManager {
  final SocketService _socketService;

  SignalingManager(this._socketService);

  /// Send an initial call invitation or renegotiation offer to a target user
  void emitInvite({
    required String sessionId,
    required String targetId,
    required String sdp,
    required bool isVideo,
    bool isRenegotiation = false,
  }) {
    _socketService.socket?.emit(SocketEvents.callInvite, {
      'sessionId': sessionId,
      'targetId': targetId,
      'sdp': sdp,
      'mediaType': isVideo ? 'video' : 'audio',
      if (isRenegotiation) 'isRenegotiation': true,
    });
  }

  /// Accept an incoming call or respond to a renegotiation offer with an answer SDP
  void emitAccept({
    required String sessionId,
    required String targetId,
    required String sdp,
    bool isRenegotiation = false,
  }) {
    _socketService.socket?.emit(SocketEvents.callAccept, {
      'sessionId': sessionId,
      'targetId': targetId,
      'sdp': sdp,
      if (isRenegotiation) 'isRenegotiation': true,
    });
  }

  /// Send ICE candidates to the remote peer to establish a P2P connection
  void emitIce({
    required String sessionId,
    required String targetId,
    required RTCIceCandidate candidate,
  }) {
    _socketService.socket?.emit(SocketEvents.callIce, {
      'sessionId': sessionId,
      'targetId': targetId,
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    });
  }

  /// Notify the remote peer and server that the call session has ended
  void emitEnd({
    required String sessionId,
    required String targetId,
    required String reason,
  }) {
    _socketService.socket?.emit(SocketEvents.callEnd, {
      'sessionId': sessionId,
      'targetId': targetId,
      'reason': reason,
    });
  }

  /// Register listeners for incoming socket events related to call signaling
  void listenEvents({
    required Function(dynamic) onAccept,
    required Function(dynamic) onIce,
    required Function(dynamic) onEnd,
  }) {
    _socketService.socket?.on(SocketEvents.callAccept, onAccept);
    _socketService.socket?.on(SocketEvents.callIce, onIce);
    _socketService.socket?.on(SocketEvents.callEnd, onEnd);
  }

  /// Unregister signaling listeners to prevent memory leaks or redundant callbacks
  void dispose() {
    _socketService.socket?.off(SocketEvents.callAccept);
    _socketService.socket?.off(SocketEvents.callIce);
    _socketService.socket?.off(SocketEvents.callEnd);
  }
}