import 'package:flutter/foundation.dart';
import 'package:flutter_app/ui/chat/core/call_manager/storage/call_arbitrator.dart';

import '../../models/call_event.dart';
import 'callkit_service.dart';

class CallDispatcher {
  CallDispatcher._();
  static final CallDispatcher instance = CallDispatcher._();

  // Ultimate Shield: Hold the latest invite signal in memory
  // to prevent Android native layer from discarding large SDP text strings.
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
      debugPrint("[Dispatcher] Dispatch error: $e");
    }
  }

  Future<bool> _handleInvite(CallEvent event) async {
    final arbitrator = CallArbitrator.instance;

    // Pre-fetch historical status for this session
    final isHandled = await arbitrator.isSessionHandled(event.sessionId);
    final isEnded = await arbitrator.isSessionEnded(event.sessionId);

    // Fast Reconnection Shield: Autonomous Inference!
    // Even if the backend loses the isRenegotiation field, if this call has been handled
    // and hasn't ended, it's undoubtedly a reconnection signal from a network switch.
    if (event.rawData['isRenegotiation'] == true || (isHandled && !isEnded)) {
      debugPrint("[Dispatcher] Secondary stream detected for same session (Network Reconnection), bypassing popup.");
      event.rawData['isRenegotiation'] = true; // Force-patch the flag for the state machine
      return true;
    }

    if (await arbitrator.isGlobalCooldownActive()) return false;
    if (isEnded) return false;
    if (isHandled) return false;

    await arbitrator.markSessionAsHandled(event.sessionId);
    await arbitrator.cacheSdp(event.sessionId, event.rawData['sdp']?.toString() ?? '');
    await arbitrator.lockGlobalCooldown();

    debugPrint("[Dispatcher] Security check passed, formally invoking CallKit");
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
    debugPrint("[Dispatcher] Termination command received, starting physical cleanup (Session: ${event.sessionId})");
    await arbitrator.markSessionAsEnded(event.sessionId);
    CallKitService.instance.endCall(event.sessionId);
  }
}