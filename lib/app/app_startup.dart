import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';

import '../core/store/config_store.dart';
import '../ui/chat/providers/contact_provider.dart';
import '../ui/chat/providers/conversation_provider.dart';

part 'app_startup.g.dart';

@Riverpod(keepAlive: true)
Future<void> appStartup(AppStartupRef ref) async {
  debugPrint("🚀 [AppStartup] Starting application initialization...");

  // 1. 监听认证状态，确保 authProvider 在 Provider 树内保活
  ref.watch(authProvider);
  debugPrint("🚀 [AppStartup] Auth provider watched");

  // 2. 后台拉取远程系统配置（非关键，失败不影响启动）
  Future.microtask(() async {
    try {
      debugPrint("🚀 [AppStartup] Fetching latest config...");
      final notifier = ref.read(configProvider.notifier);
      await notifier.fetchLatest();
      debugPrint("🚀 [AppStartup] Config fetched successfully");
    } catch (e) {
      debugPrint("⚠️ [AppStartup] Config fetch failed (non-critical): $e");
    }
  });

  final authState = ref.read(authProvider);
  debugPrint("🚀 [AppStartup] Auth state: isAuthenticated=${authState.isAuthenticated}");

  // 3. 认证用户：后台 fire-and-forget 触发聊天数据预热
  // [Phase 2 优化] 移除脆弱的 lucky_state JSON 手动解析 + DB 重复初始化。
  // DB 的唯一正确初始化入口：user_store.fetchProfile() → LocalDatabaseService.init(user.id)
  // 在 login() 时调用，冷启动时由 HydratedStateNotifier 异步从 SharedPreferences 恢复用户状态。
  // 各 Provider 内部已有 userProvider == null 守卫，预热失败会静默降级。
  if (authState.isAuthenticated) {
    Future.microtask(() {
      debugPrint("🚀 [AppStartup] Background chat data pre-warming...");
      try { ref.read(contactListProvider); } catch (_) {}
      try { ref.read(conversationListProvider); } catch (_) {}
      try { ref.read(contactEntitiesProvider); } catch (_) {}
      debugPrint("🚀 [AppStartup] Background pre-warming triggered");
    });
  } else {
    debugPrint("ℹ️ [AppStartup] User not authenticated, skipping chat pre-warming");
  }

  debugPrint("✅ [AppStartup] Application initialization completed");
}
