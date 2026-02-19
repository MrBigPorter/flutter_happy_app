import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

StreamSubscription? _callKitSub; // 增加一个全局变量保存监听器

class CallKitService {
  static final CallKitService instance = CallKitService._();
  CallKitService._();

  //  新增：清理所有的幽灵来电
  Future<void> clearAllCalls() async {
    debugPrint("[CallKit] Clearing all ghost calls...");
    try {
      // 加入 try-catch，防止插件崩溃带崩全场
      await FlutterCallkitIncoming.endAllCalls();
    } catch (e) {
      debugPrint("[CallKit] endAllCalls 静默报错: $e");
    }
  }

  /// 1. 唤起系统级来电界面
  Future<void> showIncomingCall({
    required String uuid,       // 会话 ID (SessionId)
    required String name,       // 对方名字
    required String avatar,     // 对方头像
    required bool isVideo,      // 是否视频
    Map<String, dynamic>? extra, //  新增：接收额外数据
  }) async {
    //  核心防御：防止重复弹窗和重叠按钮
    try {
      final activeCalls = await FlutterCallkitIncoming.activeCalls();
      if (activeCalls is List && activeCalls.isNotEmpty) {
        debugPrint("️ [CallKit] System is already showing a call! Ignoring duplicate invite.");
        return; // 直接拦截，防止重叠！
      }
    } catch (e) {
      // 如果插件底层报 "content is null" 或其他错，直接无视，当作当前没有通话处理
      debugPrint(" [CallKit] Failed to check active calls, proceeding anyway. Error: $e");
    }

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
      extra: extra ?? {}, //  核心：把发送者资料塞进系统参数

      //  核心修复 2：确保外层也有开启屏幕的权限
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
      ),

      // Android 设置
      android: AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#000000',
        actionColor: '#4CAF50',
        isShowFullLockedScreen: true,
        isImportant: true,
        // 【核心修复】补全这两行，否则安卓 12+ 必崩
        incomingCallNotificationChannelName: "Incoming Call",
        missedCallNotificationChannelName: "Missed Call",
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

    //  核心修复：防止重复注册监听器
    _callKitSub?.cancel();

    _callKitSub = FlutterCallkitIncoming.onEvent.listen((event) {
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

        case Event.actionCallTimeout: //  加上超时处理
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