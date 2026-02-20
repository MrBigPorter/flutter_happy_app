import 'package:flutter/foundation.dart';
import 'package:flutter_app/ui/chat/core/call_manager/storage/call_arbitrator.dart';

import '../../models/call_event.dart';
import '../../services/callkit_service.dart';

class CallDispatcher {
  CallDispatcher._();
  static final CallDispatcher instance = CallDispatcher._();

  //  终极护盾：在内存中死死抱住最新信令，防止安卓原生层把超大 SDP 文本丢弃
  CallEvent? currentInvite;

  Future<void> dispatch(
      Map<String, dynamic> rawData, {
        Function(CallEvent)? onNotify,
      }) async {
    try {
      final event = CallEvent.fromMap(rawData);
      if (event.isExpired) return;

      switch (event.type) {
        case CallEventType.invite:
          final passed = await _handleInvite(event);
          if (passed && onNotify != null) onNotify(event);
          break;
        case CallEventType.end:
          await _handleEnd(event);
          if (onNotify != null) onNotify(event);
          break;
        case CallEventType.accept:
        case CallEventType.ice:
          if (onNotify != null) onNotify(event);
          break;
        case CallEventType.unknown:
          break;
      }
    } catch (e) {
      debugPrint("❌ [Dispatcher] 分发异常: $e");
    }
  }

  Future<bool> _handleInvite(CallEvent event) async {
    final arbitrator = CallArbitrator.instance;

    if (await arbitrator.isGlobalCooldownActive()) return false;
    if (await arbitrator.isSessionEnded(event.sessionId)) return false;
    if (await arbitrator.isSessionHandled(event.sessionId)) return false;

    await arbitrator.markSessionAsHandled(event.sessionId);
    await arbitrator.lockGlobalCooldown();

    debugPrint(" [Dispatcher] 安检通过，正式唤起 CallKit");

    //  存入内存保险箱！
    currentInvite = event;

    await CallKitService.instance.showIncomingCall(
      uuid: event.sessionId,
      name: event.senderName,
      avatar: event.senderAvatar,
      isVideo: event.isVideo,
      extra: event.rawData,
    );
    return true;
  }

  Future<void> _handleEnd(CallEvent event) async {
    final arbitrator = CallArbitrator.instance;
    debugPrint(" [Dispatcher] 收到挂断指令，开始物理大清场 (Session: ${event.sessionId})");
    await arbitrator.markSessionAsEnded(event.sessionId);
    CallKitService.instance.endCall(event.sessionId);
  }
}