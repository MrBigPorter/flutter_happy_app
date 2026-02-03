import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../api/http_client.dart';
import '../../providers/socket_provider.dart';

/// 这是一个纯逻辑类，不涉及任何 UI 弹窗
class SessionManager extends WidgetsBindingObserver {
  final Ref ref;
  Timer? _refreshTimer;

  SessionManager(this.ref) {
    // 初始化时，开始监听生命周期
    WidgetsBinding.instance.addObserver(this);
    // 启动定时检查
    _scheduleNextRefresh();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
  }

  // 监听前后台切换
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("📱 [SessionManager] App 切回前台，检查 Token...");
      _refreshTimer?.cancel();
      _checkTokenAndReconnect();
    }
  }

  // 核心：定时器调度逻辑
  Future<void> _scheduleNextRefresh() async {
    _refreshTimer?.cancel();
    final token = await Http.getToken();
    if (token == null || token.isEmpty) return;

    try {
      final Duration remaining = JwtDecoder.getRemainingTime(token);
      final int secondsToWait = remaining.inSeconds - 120; // 提前2分钟

      if (secondsToWait <= 0) {
        await _performSilentRefresh();
      } else {
        debugPrint("⏰ [SessionManager] 计划在 $secondsToWait 秒后刷新");
        _refreshTimer = Timer(Duration(seconds: secondsToWait), () async {
          await _performSilentRefresh();
        });
      }
    } catch (_) {}
  }

  // 执行刷新
  Future<void> _performSilentRefresh() async {
    debugPrint("🔄 [SessionManager] 执行静默刷新...");
    final success = await Http.tryRefreshToken(Http.rawDio);
    if (success) {
      final newToken = await Http.getToken();
      if (newToken != null) {
        // 指挥 Socket 重连
        ref.read(socketServiceProvider).init(token: newToken);
        // 递归续命
        _scheduleNextRefresh();
      }
    }
  }

  Future<void> _checkTokenAndReconnect() async {
    // (逻辑同之前，判断是否过期，过期则刷新，不过期则重置定时器)
    final token = await Http.getToken();
    if (token == null) return;
    bool isExpired = JwtDecoder.isExpired(token) || JwtDecoder.getRemainingTime(token).inSeconds < 60;

    if (isExpired) {
      await _performSilentRefresh();
    } else {
      _scheduleNextRefresh();
      // 检查 Socket 连接
      final socket = ref.read(socketServiceProvider).socket;
      if (socket == null || !socket.connected) {
        ref.read(socketServiceProvider).init(token: token);
      }
    }
  }
}

//  定义 Provider，使用 keepAlive 确保它在 App 运行期间一直活着
final sessionManagerProvider = Provider<SessionManager>((ref) {
  final manager = SessionManager(ref);
  ref.onDispose(() => manager.dispose());
  return manager;
});