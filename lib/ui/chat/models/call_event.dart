// 将外部的字符串类型，映射为内部严格的枚举类型
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
  final int timestamp; // 信号产生的时间戳
  final Map<String, dynamic> rawData; // 保留原始数据，用于透传给 CallKit 的 extra

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

  ///  架构防御点 1：自毁机制。
  /// 如果这个信号在网络里（或 FCM 队列里）卡了超过 15 秒，直接判定为无效“幽灵信令”。
  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch;
    // 取绝对值判断，防止服务器时间和本地时间有微小偏差
    return (now - timestamp).abs() > 15000;
  }

  /// 统一的解析工厂
  /// 负责把 Socket/FCM 传来的杂乱 Map 翻译成标准对象，并处理所有的 null 异常
  factory CallEvent.fromMap(Map<String, dynamic> map, {String? overrideType}) {
    // 兼容 Socket 和 FCM：FCM 里 type 通常在 map 内部，而 Socket 的 type 是通过频道名确定的
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

  /// 结合你的 SocketEvents，将字符串转为内部安全枚举
  static CallEventType _parseType(String typeStr) {
    debugPrint("🔍 [CallEvent] 正在解析信令类型: '$typeStr'"); // 加一行日志，以后抓虫一目了然
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
