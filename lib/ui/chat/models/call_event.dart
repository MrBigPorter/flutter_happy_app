// Maps external string event types to internal strict enums
import 'package:flutter/cupertino.dart';
import '../../../core/constants/socket_events.dart';

enum CallEventType { invite, accept, end, ice, unknown }

class CallEvent {
  final String sessionId;
  final CallEventType type;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final bool isVideo;
  final int timestamp; // Signaling generation timestamp
  final Map<String, dynamic> rawData; // Original data preserved for CallKit extra/passthrough

  CallEvent({
    required this.sessionId,
    required this.type,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.isVideo,
    required this.timestamp,
    required this.rawData,
  });

  /// Architectural Defense: Expiration Mechanism.
  /// If a signal is delayed in the network or FCM queue for more than 15 seconds,
  /// it is classified as an invalid "ghost signal" to prevent stale UI states.
  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Use absolute difference to account for minor clock drifts between server and client
    return (now - timestamp).abs() > 15000;
  }

  /// Unified Factory Constructor:
  /// Translates disparate Map structures from Socket/FCM into standardized objects
  /// while handling all potential null exceptions.
  factory CallEvent.fromMap(Map<String, dynamic> map, {String? overrideType}) {
    // Compatibility: In FCM, 'type' is usually internal; in Socket, it is determined by the channel
    final typeStr = overrideType ?? map['type']?.toString() ?? '';

    return CallEvent(
      sessionId: map['sessionId']?.toString() ?? '',
      type: _parseType(typeStr),
      senderId:
      map['senderId']?.toString() ??
          map['targetId']?.toString() ??
          'unknown',
      senderName: map['senderName']?.toString() ?? 'Incoming Call',
      senderAvatar:
      map['senderAvatar']?.toString() ?? 'https://via.placeholder.com/150',
      isVideo: map['mediaType'] == 'video',
      timestamp:
      int.tryParse(map['timestamp']?.toString() ?? '') ??
          DateTime.now().millisecondsSinceEpoch,
      rawData: map,
    );
  }

  /// Maps string constants from SocketEvents to internal safe enums
  static CallEventType _parseType(String typeStr) {
    debugPrint("[CallEvent] Parsing signaling type: '$typeStr'");
    switch (typeStr) {
      case SocketEvents.callInvite:
        return CallEventType.invite;
      case SocketEvents.callAccept:
        return CallEventType.accept;
      case SocketEvents.callEnd:
        return CallEventType.end;
      case SocketEvents.callIce:
        return CallEventType.ice;
      default:
        return CallEventType.unknown;
    }
  }
}