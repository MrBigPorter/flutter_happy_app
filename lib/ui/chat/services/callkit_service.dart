import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

class CallKitService {
  static final CallKitService instance = CallKitService._();
  CallKitService._();

  /// 1. 唤起系统级来电界面
  Future<void> showIncomingCall({
    required String uuid,       // 会话 ID (SessionId)
    required String name,       // 对方名字
    required String avatar,     // 对方头像
    required bool isVideo,      // 是否视频
  }) async {

    final params = CallKitParams(
      id: uuid,
      nameCaller: name,
      appName: 'Lucky IM',
      avatar: avatar,
      handle: isVideo ? 'Video Call' : 'Voice Call',
      type: isVideo ? 1 : 0,
      duration: 30000, // 30秒无人接听自动挂断
      textAccept: 'Accept',
      textDecline: 'Decline',

      // Android 设置
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#000000', // 酷一点，用黑色背景
        actionColor: '#4CAF50',
        incomingCallNotificationChannelName: "Incoming Call",
      ),

      // iOS 设置 (为以后做准备)
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'videoChat',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  /// 2. 主动结束通话 (例如对方挂断了，我们要把系统界面关掉)
  Future<void> endCall(String uuid) async {
    await FlutterCallkitIncoming.endCall(uuid);
  }

  /// 3. 全局监听用户操作 (接听/挂断)
  void initListener({
    required Function(String uuid) onAccept,
    required Function(String uuid) onDecline,
  }) {
    FlutterCallkitIncoming.onEvent.listen((event) {
      if (event == null) return;

      switch (event.event) {
        case Event.actionCallAccept:
          debugPrint(" CallKit: 用户点击接听");
          onAccept(event.body['id']);
          break;

        case Event.actionCallDecline:
          debugPrint(" CallKit: 用户点击挂断");
          onDecline(event.body['id']);
          break;

        case Event.actionCallEnded:
        // 这里的 Ended 可能是用户挂断，也可能是系统清理
        // 通常不需要额外处理，或者也可以映射为 Decline
          onDecline(event.body['id']);
          break;

        default:
          break;
      }
    });
  }
}