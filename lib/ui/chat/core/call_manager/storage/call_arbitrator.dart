import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 跨进程信令仲裁中心 (Process Arbitrator)
/// 职责：利用 SharedPreferences 作为物理共享锁，解决主线程和 FCM 后台线程的竞态冲突

class CallArbitrator {
  // 单例模式，全局唯一
  CallArbitrator._();
  static final CallArbitrator instance = CallArbitrator._();

  // 统一管理 Key 前缀，防止污染其他本地数据
  static const String _kGlobalLockTime = 'arb_global_cooldown_time';
  static const String _kEndedPrefix = 'arb_ended_';
  static const String _kHandledPrefix = 'arb_handled_';

  /// 检查系统是否处于“冷却期” (默认 3500 毫秒)
  Future<bool> isGlobalCooldownActive() async {
    final prefs = await SharedPreferences.getInstance();
    final int lockTime = prefs.getInt(_kGlobalLockTime) ?? 0;
    final int now = DateTime.now().millisecondsSinceEpoch;

    final bool isCoolingDown = (now - lockTime) < 3500;
    if (isCoolingDown) {
      debugPrint(" [Arbitrator] 全局防抖锁生效！丢弃当前密集信令");
    }
    return isCoolingDown;
  }

  /// 激活全局防抖锁 (接收到合法 Invite 或点击挂断时调用)
  Future<void> lockGlobalCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kGlobalLockTime, DateTime.now().millisecondsSinceEpoch);
    debugPrint(" [Arbitrator] 全局防抖锁已开启 (3.5秒)");
  }

  /// ----------------------------------------------------------------
  /// ️ 第二把锁：死亡名单锁 (Death Lock)
  /// 作用：主线程挂断后，彻底物理拉黑该 Session，拦截延迟到达的 FCM
  /// ----------------------------------------------------------------

  /// 标记一个 Session 已彻底终结
  Future<void> markSessionAsEnded(String sessionId) async {
    if (sessionId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kEndedPrefix$sessionId', true);
    debugPrint(" [Arbitrator] Session $sessionId 已打上死亡标记");
  }

  /// 检查该 Session 是否在死亡名单中
  Future<bool> isSessionEnded(String sessionId) async {
    if (sessionId.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final bool isEnded = prefs.getBool('$_kEndedPrefix$sessionId') == true;

    if (isEnded) {
      debugPrint("[Arbitrator] 死亡名单锁生效！拦截诈尸信令: $sessionId");
    }
    return isEnded;
  }

  /// ----------------------------------------------------------------
  ///  第三把锁：业务认领锁 (Claim Lock)
  /// 作用：对于同一个 Session 的来电，谁先拿到（Socket 或 FCM），谁就占坑
  /// ----------------------------------------------------------------

  /// 声明当前进程已接管该 Session
  Future<void> markSessionAsHandled(String sessionId) async {
    if (sessionId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kHandledPrefix$sessionId', true);
    debugPrint(" [Arbitrator] Session $sessionId 已被当前进程认领");
  }

  /// 检查该 Session 是否已被其他进程抢先处理
  Future<bool> isSessionHandled(String sessionId) async {
    if (sessionId.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final bool isHandled = prefs.getBool('$_kHandledPrefix$sessionId') == true;

    if (isHandled) {
      debugPrint(" [Arbitrator] 认领锁生效！该信令已被其他线程接管，本线程退出");
    }
    return isHandled;
  }

}