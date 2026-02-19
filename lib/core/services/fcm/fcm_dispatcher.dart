import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_app/core/services/fcm/fcm_payload.dart';

import 'fcm_ui_factory.dart';
import 'handlers/chat_handler.dart';
import 'handlers/group_handler.dart';

class FcmDispatcher {
  // 记录最近处理的消息 ID，防止重复触发
  final Set<String> _processedMessageIds = {};

  // 注入具体的业务执行者
  final _groupHandler = GroupActionHandler();
  final _chatHandler = ChatActionHandler();

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

    //  新增拦截：电话的接听行为是由 CallKit 原生回调控制的，这里直接 return 即可
    if (payload.type == FcmType.callInvite) {
      return;
    }

    print("[FCM Dispatcher] 执行跳转逻辑: ${payload.type}");
    // 架构点：根据类型寻找执行肌肉
    switch (payload.type) {
      case FcmType.groupDetail:
        _groupHandler.handle(payload);
        break;
        case FcmType.chat:
         _chatHandler.handle(payload);
      case FcmType.system:
        // _systemHandler.handle(payload);
        break;
      default:
        print("[FCM] 未定义的执行逻辑");
    }
  }

  // 内部逻辑：处理前台弹窗
  void _handleForeground(FcmPayload payload) {

    //  新增拦截：前台收到电话推送，不弹 Toast！(交由 Socket 和 CallKit 自己处理)
    if (payload.type == FcmType.callInvite) {
      print("[FCM Dispatcher] 拦截 call_invite 前台推送");
      return;
    }

    print("[FCM Dispatcher] 执行前台展示逻辑: ${payload.title}");

    FcmUiFactory.showNotification(
      payload,
      onTap: () {
        print("[FCM] 用户点击了前台通知条，触发跳转");
        // 复用交互逻辑，实现从前台通知点击跳转
        _handleInteraction(payload);
      },
    );
  }
}
