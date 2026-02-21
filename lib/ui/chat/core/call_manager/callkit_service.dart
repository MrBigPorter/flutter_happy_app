import 'dart:async';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

class CallKitActionEvent {
  final String action;
  final Map<String, dynamic>? data;

  CallKitActionEvent(this.action, this.data);
}

class CallKitService {
  static final CallKitService instance = CallKitService._();

  CallKitService._();

  StreamSubscription? _callKitSub;

  final Map<String, Function(CallKitActionEvent)> _handlers = {};

  /// 订阅系统通话行为
  void onAction(String subscriberId, Function(CallKitActionEvent) handler) {
    if (kIsWeb) return; //  物理隔离：Web 端没有系统按键，无需监听系统级回调

    _handlers[subscriberId] = handler;

    if (_callKitSub != null) return;

    _callKitSub = FlutterCallkitIncoming.onEvent.listen((event) {
      if (event == null) return;

      CallKitActionEvent? actionEvent;
      switch (event.event) {
        case Event.actionCallAccept:
          actionEvent = CallKitActionEvent('answerCall', event.body);
          break;
        case Event.actionCallDecline:
        case Event.actionCallTimeout:
        case Event.actionCallEnded:
          actionEvent = CallKitActionEvent('endCall', event.body);
          break;
        case Event.actionCallToggleMute:
          actionEvent = CallKitActionEvent('setMuted', event.body);
          break;
        default:
          break;
      }

      if (actionEvent != null) {
        final List<Function(CallKitActionEvent)> targets = _handlers.values.toList();
        for (var h in targets) {
          try {
            h(actionEvent);
          } catch (e) {
            debugPrint(" [CallKitService] Handler 执行失败: $e");
          }
        }
      }
    });
  }

  void disposeHandlers() {
    _handlers.clear();
  }

  /// 兼容旧代码的 initListener
  void initListener({
    required Function(String uuid) onAccept,
    required Function(String uuid) onDecline,
  }) {
    if (kIsWeb) return; //  物理隔离

    onAction('legacy_init', (event) {
      final String uuid = event.data?['id']?.toString() ?? '';
      if (event.action == 'answerCall')
        onAccept(uuid);
      else if (event.action == 'endCall')
        onDecline(uuid);
    });
  }

  Future<void> clearAllCalls() async {
    if (kIsWeb) return; //  物理隔离
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (_) {}
  }

  Future<void> showIncomingCall({
    required String uuid,
    required String name,
    required String avatar,
    required bool isVideo,
    Map<String, dynamic>? extra,
  }) async {
    if (kIsWeb) {
      //  物理隔离：Web 端不调系统弹窗，直接靠 App 内部的 Socket 和状态机驱动 UI
      debugPrint("🌐 [CallKitService] Web端拦截系统来电，直接交由 App 内 UI 处理");
      return;
    }

    final params = CallKitParams(
      id: uuid,
      nameCaller: name,
      appName: 'Lucky IM',
      avatar: avatar,
      handle: isVideo ? 'Video Call' : 'Voice Call',
      type: isVideo ? 1 : 0,
      duration: 30000,
      extra: extra ?? {},
      android: AndroidParams(
        isCustomNotification: false,
        isShowLogo: false,
        isShowFullLockedScreen: true,
        isImportant: true,
        incomingCallNotificationChannelName: "Lucky Incoming Call V2",
        missedCallNotificationChannelName: "Lucky Missed Call V2",
        backgroundColor: '#0955fa',
        actionColor: '#4CAF50',
      ),
      ios: const IOSParams(
        handleType: 'generic',
        supportsVideo: true,
        audioSessionActive: true,
      ),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  Future<void> endCall(String uuid) async {
    if (kIsWeb) return; //  物理隔离
    await FlutterCallkitIncoming.endCall(uuid);
  }
}