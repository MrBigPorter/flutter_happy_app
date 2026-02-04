import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_app/core/services/fcm/fcm_payload.dart';

import 'handlers/group_handler.dart';

class FcmDispatcher {
  // 记录最近处理的消息 ID，防止重复触发
  final Set<String> _processedMessageIds = {};

  // 注入具体的业务执行者
  final _groupHandler = GroupActionHandler();

  // 架构点：分发入口，区分【前台展示】与【交互跳转】
  void dispatch(RemoteMessage message, {required bool isInteraction}) {
    // 1. 幂等性检查：如果消息 ID 已处理，直接拦截
    if (message.messageId != null &&
        _processedMessageIds.contains(message.messageId)) {
      print("FCM message ${message.messageId} already processed. Skipping.");
      return;
    }

    if (message.messageId != null) {
      _processedMessageIds.add(message.messageId!);
      // 可选：限制缓存大小，防止内存泄漏
      if (_processedMessageIds.length > 100) {
        _processedMessageIds.clear();
      }
    }
    // 2. 将原始 Map 转化为强类型契约对象
    final payload = FcmPayload.fromMap(
      message.data,
      notificationTitle: message.notification?.title,
      notificationBody: message.notification?.body,
    );

    if (isInteraction) {
      // 场景：用户点击了通知（后台唤醒或冷启动）
      _handleInteraction(payload);
    } else {
      // 场景：App 正在前台运行，收到静默消息或前台通知
      _handleForeground(payload);
    }
  }

  // 内部逻辑：处理点击跳转
  void _handleInteraction(FcmPayload payload) {
    if (!payload.hasValidAction) return;
    print("[FCM Dispatcher] 执行跳转逻辑: ${payload.type}");
    // 架构点：根据类型寻找执行肌肉
    switch (payload.type) {
      case FcmType.groupDetail:
        _groupHandler.handle(payload);
        break;
      case FcmType.system:
        // _systemHandler.handle(payload);
        break;
      default:
        print("[FCM] 未定义的执行逻辑");
    }
  }

  // 内部逻辑：处理前台弹窗
  void _handleForeground(FcmPayload payload) {
    print("[FCM Dispatcher] 执行前台展示逻辑: ${payload.title}");

    // 这里将对接未来的 FcmUiFactory (BotToast)
  }
}
