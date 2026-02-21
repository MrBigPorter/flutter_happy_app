import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_app/core/constants/socket_events.dart';
import 'package:flutter_app/core/services/socket/socket_service.dart';

class SignalingManager {
  final SocketService _socketService;

  SignalingManager(this._socketService);

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

  void listenEvents({
    required Function(dynamic) onAccept,
    required Function(dynamic) onIce,
    required Function(dynamic) onEnd,
  }) {
    _socketService.socket?.on(SocketEvents.callAccept, onAccept);
    _socketService.socket?.on(SocketEvents.callIce, onIce);
    _socketService.socket?.on(SocketEvents.callEnd, onEnd);
  }

  void dispose() {
    _socketService.socket?.off(SocketEvents.callAccept);
    _socketService.socket?.off(SocketEvents.callIce);
    _socketService.socket?.off(SocketEvents.callEnd);
  }
}
