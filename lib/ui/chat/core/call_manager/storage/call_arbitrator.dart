import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Process Arbitrator
/// Responsibility: Uses SharedPreferences as a physical shared lock to resolve
/// race conditions between the main UI thread and FCM background threads.

class CallArbitrator {
  // Singleton pattern for global access
  CallArbitrator._();
  static final CallArbitrator instance = CallArbitrator._();

  // Standardized key prefixes to avoid polluting other local data
  static const String _kGlobalLockTime = 'arb_global_cooldown_time';
  static const String _kEndedPrefix = 'arb_ended_';
  static const String _kHandledPrefix = 'arb_handled_';
  static const String _kSdpCachePrefix = 'arb_sdp_';

  /// Cross-process SDP caching (Persisted to disk, visible to all processes)
  Future<void> cacheSdp(String sessionId, String sdp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kSdpCachePrefix$sessionId', sdp);
  }

  /// Cross-process SDP retrieval
  Future<String?> getCachedSdp(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_kSdpCachePrefix$sessionId');
  }

  /// Check if the system is currently in a "cooldown period" (default 3500ms)
  Future<bool> isGlobalCooldownActive() async {
    final prefs = await SharedPreferences.getInstance();
    final int lockTime = prefs.getInt(_kGlobalLockTime) ?? 0;
    final int now = DateTime.now().millisecondsSinceEpoch;

    final bool isCoolingDown = (now - lockTime) < 3500;
    if (isCoolingDown) {
      debugPrint("[Arbitrator] Global debounce lock active! Discarding dense signaling");
    }
    return isCoolingDown;
  }

  /// Activate the global debounce lock (Called on valid Invite or hang-up)
  Future<void> lockGlobalCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kGlobalLockTime, DateTime.now().millisecondsSinceEpoch);
    debugPrint("[Arbitrator] Global debounce lock enabled (3.5s)");
  }

  /// ----------------------------------------------------------------
  /// Second Lock: Death Lock
  /// Purpose: Physically blacklists a session after hang-up to intercept delayed FCM signals.
  /// ----------------------------------------------------------------

  /// Mark a session as permanently terminated
  Future<void> markSessionAsEnded(String sessionId) async {
    if (sessionId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kEndedPrefix$sessionId', true);
    debugPrint("[Arbitrator] Session $sessionId marked as dead");
  }

  /// Check if a session is in the death blacklist
  Future<bool> isSessionEnded(String sessionId) async {
    if (sessionId.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final bool isEnded = prefs.getBool('$_kEndedPrefix$sessionId') == true;

    if (isEnded) {
      debugPrint("[Arbitrator] Death lock active! Intercepting ghost signal: $sessionId");
    }
    return isEnded;
  }

  /// ----------------------------------------------------------------
  /// Third Lock: Claim Lock
  /// Purpose: Ensures only the first process to receive a session signal (Socket or FCM) takes control.
  /// ----------------------------------------------------------------

  /// Declare that the current process has taken over the session
  Future<void> markSessionAsHandled(String sessionId) async {
    if (sessionId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kHandledPrefix$sessionId', true);
    debugPrint("[Arbitrator] Session $sessionId claimed by current process");
  }

  /// Check if the session has already been handled by another process
  Future<bool> isSessionHandled(String sessionId) async {
    if (sessionId.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final bool isHandled = prefs.getBool('$_kHandledPrefix$sessionId') == true;

    if (isHandled) {
      debugPrint("[Arbitrator] Claim lock active! Signaling already handled by another thread, exiting");
    }
    return isHandled;
  }
}