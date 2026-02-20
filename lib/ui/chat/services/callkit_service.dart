import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
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

  // 🟢 核心改动 1：将 List 改为 Map，使用 String 作为身份证 (Key) 来存储监听器
  // 这样同名的监听器在每次页面刷新时，会自动覆盖旧的“丧尸”函数。
  final Map<String, Function(CallKitActionEvent)> _handlers = {};

  /// 订阅系统通话行为
  // 🟢 核心改动 2：增加 subscriberId 参数，实行“实名制”注册
  void onAction(String subscriberId, Function(CallKitActionEvent) handler) {
    // 🟢 核心改动 3：直接通过 Key 赋值覆盖旧函数。不需要再用 contains 检查了！
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
        // 🟢 核心改动 4：取出 Map 中所有的 values (即当前存活的最新函数) 进行广播
        final List<Function(CallKitActionEvent)> targets = _handlers.values
            .toList();
        for (var h in targets) {
          try {
            h(actionEvent);
          } catch (e) {
            debugPrint("❌ [CallKitService] Handler 执行失败: $e");
          }
        }
      }
    });
  }

  // 【新增】：提供一个清空监听器的方法，用于 App 登出或重置
  void disposeHandlers() {
    _handlers.clear();
  }

  /// 兼容旧代码的 initListener
  void initListener({
    required Function(String uuid) onAccept,
    required Function(String uuid) onDecline,
  }) {
    // 🟢 核心改动 5：给老代码分配一个固定的身份证 'legacy_init'
    onAction('legacy_init', (event) {
      final String uuid = event.data?['id']?.toString() ?? '';
      if (event.action == 'answerCall')
        onAccept(uuid);
      else if (event.action == 'endCall')
        onDecline(uuid);
    });
  }

  Future<void> clearAllCalls() async {
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
        // 🔪 核心护盾 1：必须改成 false！绝对不要用自定义通知，使用系统默认的 VoIP 原生界面，杜绝底层渲染崩溃！
        isCustomNotification: false,
        isShowLogo: false,
        // 🔪 核心护盾 2：强制要求锁屏显示
        isShowFullLockedScreen: true,
        isImportant: true,
        // 🔪 核心护盾 3：强行改名字！这会强迫安卓系统废弃掉旧的低优先级通道，重新建立一个最高优先级的“来电专属通道”！
        incomingCallNotificationChannelName: "Lucky Incoming Call V2",
        missedCallNotificationChannelName: "Lucky Missed Call V2",
        // 给个兜底颜色，防止透明度引发的黑屏
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

  Future<void> endCall(String uuid) async =>
      await FlutterCallkitIncoming.endCall(uuid);
}
