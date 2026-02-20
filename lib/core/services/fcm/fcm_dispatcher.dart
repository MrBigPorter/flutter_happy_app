import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_app/core/services/fcm/fcm_payload.dart';
import 'package:flutter_app/ui/chat/core/call_manager/call_dispatcher.dart';

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

    // 🟢 终极修复：在顶层截获！只要是音视频信令，绝不走普通推送逻辑，直接交给总调度器！
    final String typeStr = message.data['type']?.toString() ?? '';
    if (typeStr == 'call_invite' || typeStr == 'call_end' || typeStr == 'call_accept' || typeStr == 'call_ice') {
      print("[FCM Dispatcher] 收到音视频信令 ($typeStr)，紧急移交 CallDispatcher 处理！");
      CallDispatcher.instance.dispatch(message.data);
      return; // 🔪 核心护盾：移交后立刻 return，绝对不让它往下走！
    }

    // 2. 将原始 Map 转化为强类型契约对象 (普通聊天、系统通知等)
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
      case FcmType.chat:
        _chatHandler.handle(payload);
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