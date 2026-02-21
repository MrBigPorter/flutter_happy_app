import 'package:flutter/foundation.dart';
import 'package:flutter_app/ui/chat/core/call_manager/storage/call_arbitrator.dart';

import '../../models/call_event.dart';
import 'callkit_service.dart';

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
      debugPrint(" [Dispatcher] 分发异常: $e");
    }
  }

  Future<bool> _handleInvite(CallEvent event) async {
    final arbitrator = CallArbitrator.instance;

    // 提前获取该 Session 的历史状态
    final isHandled = await arbitrator.isSessionHandled(event.sessionId);
    final isEnded = await arbitrator.isSessionEnded(event.sessionId);

    //  极速重连终极护盾：自主推理！
    // 即使后端弄丢了 isRenegotiation 字段，只要这个电话接过 (isHandled) 且没挂断 (!isEnded)
    // 毫无疑问，这就是底层网络切换带来的重连信令！直接放行给状态机！
    if (event.rawData['isRenegotiation'] == true || (isHandled && !isEnded)) {
      debugPrint(" [Dispatcher] 嗅探到同一 Session 的二次推流 (网络重连)，免弹窗直接放行！");
      event.rawData['isRenegotiation'] = true; // 强制给它补齐标志，喂给状态机
      return true;
    }

    if (await arbitrator.isGlobalCooldownActive()) return false;
    if (isEnded) return false;
    if (isHandled) return false;

    await arbitrator.markSessionAsHandled(event.sessionId);
    await arbitrator.cacheSdp(event.sessionId, event.rawData['sdp']?.toString() ?? '');
    await arbitrator.lockGlobalCooldown();

    debugPrint(" [Dispatcher] 安检通过，正式唤起 CallKit");
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