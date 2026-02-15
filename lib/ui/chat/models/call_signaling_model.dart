import 'package:uuid/uuid.dart';
import 'call_enums.dart';

//  0. 基础信令模型
class BaseCallSignal {
  final String sessionId;
  final String senderId;
  final String targetId;
  final int timestamp;

  BaseCallSignal({
    required this.sessionId,
    required this.senderId,
    required this.targetId,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'targetId': targetId,
    };
  }
}

//  1. 发起呼叫 (Invite)
class CallInviteSignal extends BaseCallSignal {
  final CallMediaType mediaType;
  final String sdp;

  CallInviteSignal({
    required super.sessionId,
    required super.senderId,
    required super.targetId,
    required this.mediaType,
    required this.sdp,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'mediaType': mediaType.name, // 'audio' or 'video'
      'sdp': sdp,
    };
  }

  factory CallInviteSignal.fromMap(Map<String, dynamic> map) {
    return CallInviteSignal(
      sessionId: map['sessionId'],
      senderId: map['senderId'],
      targetId: map['targetId'] ?? '', // 接收时自己是 target
      mediaType: CallMediaType.values.byName(map['mediaType']),
      sdp: map['sdp'],
    );
  }
}

//  2. 接听呼叫 (Accept)
class CallAcceptSignal extends BaseCallSignal {
  final String sdp;

  CallAcceptSignal({
    required super.sessionId,
    required super.senderId,
    required super.targetId,
    required this.sdp,
  });

  @override
  Map<String, dynamic> toMap() => {...super.toMap(), 'sdp': sdp};

  factory CallAcceptSignal.fromMap(Map<String, dynamic> map) {
    return CallAcceptSignal(
      sessionId: map['sessionId'],
      senderId: map['senderId'],
      targetId: map['targetId'],
      sdp: map['sdp'],
    );
  }
}

//  3. ICE 候选者
class IceCandidateSignal extends BaseCallSignal {
  final String candidate;
  final String sdpMid;
  final int sdpMLineIndex;

  IceCandidateSignal({
    required super.sessionId,
    required super.senderId,
    required super.targetId,
    required this.candidate,
    required this.sdpMid,
    required this.sdpMLineIndex,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'candidate': candidate,
      'sdpMid': sdpMid,
      'sdpMLineIndex': sdpMLineIndex,
    };
  }

  factory IceCandidateSignal.fromMap(Map<String, dynamic> map) {
    return IceCandidateSignal(
      sessionId: map['sessionId'],
      senderId: map['senderId'],
      targetId: map['targetId'],
      candidate: map['candidate'],
      sdpMid: map['sdpMid'],
      sdpMLineIndex: map['sdpMLineIndex'],
    );
  }
}

//  4. 结束/拒绝/取消 (通用)
class CallEndSignal extends BaseCallSignal {
  final CallEndReason reason;

  CallEndSignal({
    required super.sessionId,
    required super.senderId,
    required super.targetId,
    required this.reason,
  });

  @override
  Map<String, dynamic> toMap() => {...super.toMap(), 'reason': reason.name};

  factory CallEndSignal.fromMap(Map<String, dynamic> map) {
    return CallEndSignal(
      sessionId: map['sessionId'],
      senderId: map['senderId'],
      targetId: map['targetId'],
      reason: CallEndReason.values.byName(map['reason']),
    );
  }
}