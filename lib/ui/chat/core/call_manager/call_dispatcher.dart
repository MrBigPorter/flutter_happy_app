
import 'package:flutter/foundation.dart';
import 'package:flutter_app/ui/chat/core/call_manager/storage/call_arbitrator.dart';

import '../../models/call_event.dart';
import '../../services/callkit_service.dart';

class CallDispatcher {
  // 单例模式
  CallDispatcher._();
  static final CallDispatcher instance = CallDispatcher._();

  /// 唯一的信令入口！
  /// 不管是 Socket 还是 FCM，收到数据后直接无脑丢给这个方法。
  Future<void> dispatch(Map<String, dynamic> rawData) async {
    try {
      // 1. 翻译为标准事件 (现在编译器明确知道用我们自己的 CallEvent)
      final event = CallEvent.fromMap(rawData);

      // 2. 基础防御：过期信令直接丢弃
      if (event.isExpired) {
        debugPrint(" [Dispatcher] 信令已过期 (超过15秒)，丢弃: ${event.sessionId}");
        return;
      }

      // 3. 路由分发
      switch (event.type) {
        case CallEventType.invite:
          await _handleInvite(event);
          break;
        case CallEventType.end:
          await _handleEnd(event);
          break;
        case CallEventType.accept:
        case CallEventType.ice:
        // 这些是连通后的信令，后续我们会交给 StateMachine 处理
          debugPrint(" [Dispatcher] 收到流媒体信令，准备转交状态机...");
          break;
        case CallEventType.unknown:
          debugPrint(" [Dispatcher] 收到未知类型的信令");
          break;
      }
    } catch (e) {
      debugPrint(" [Dispatcher] 致命错误，分发信令失败: $e");
    }
  }

  /// ----------------------------------------------------------------
  /// 处理来电邀请 (Invite) - 核心安检逻辑
  /// ----------------------------------------------------------------
  Future<void> _handleInvite(CallEvent event) async {
    final arbitrator = CallArbitrator.instance;

    // 安检 1：全局冷却中？
    if (await arbitrator.isGlobalCooldownActive()) return;

    // 安检 2：已经在死亡名单？
    if (await arbitrator.isSessionEnded(event.sessionId)) return;

    // 安检 3：已经被另一个线程 (比如 Socket) 抢先处理了？
    if (await arbitrator.isSessionHandled(event.sessionId)) return;

    //  安检全过！本线程正式抢占控制权！
    await arbitrator.markSessionAsHandled(event.sessionId);
    await arbitrator.lockGlobalCooldown();

    debugPrint(" [Dispatcher] 安检通过，正式唤起 CallKit (Session: ${event.sessionId})");

    // 唤起原生界面，并且把完整的 rawData 作为 extra 塞进去（资料隧道）
    await CallKitService.instance.showIncomingCall(
      uuid: event.sessionId,
      name: event.senderName,
      avatar: event.senderAvatar,
      isVideo: event.isVideo,
      extra: event.rawData,
    );
  }

  /// ----------------------------------------------------------------
  /// 处理挂断信令 (End)
  /// ----------------------------------------------------------------
  Future<void> _handleEnd(CallEvent event) async {
    final arbitrator = CallArbitrator.instance;

    // 挂断信令拥有最高优先级！
    debugPrint(" [Dispatcher] 收到挂断指令，开始物理大清场 (Session: ${event.sessionId})");

    // 1. 记入死亡名单
    await arbitrator.markSessionAsEnded(event.sessionId);

    // 2. 开启 3.5 秒无敌金身，防止挂断后紧跟着的幽灵 invite 亮屏
    await arbitrator.lockGlobalCooldown();

    // 3. 强制关掉原生界面
    await CallKitService.instance.endCall(event.sessionId);
    await CallKitService.instance.clearAllCalls();

  }
}