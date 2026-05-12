import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/api/http_client.dart';
import 'package:flutter_app/core/services/firebase_service.dart';
import 'package:flutter_app/core/store/auth/auth_initial.dart';
import 'package:flutter_app/theme/theme_provider.dart';
import 'package:flutter_app/utils/asset/asset_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app/core/cache/api_cache_manager.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/features/share/services/deep_link_service.dart';
import 'package:flutter_app/ui/chat/core/call_manager/call_dispatcher.dart';


@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  //  核心替换：不管后台收到什么牛鬼蛇神推送，全部无脑扔给我们的“总安检大门”！
  // Dispatcher 会帮我们查死人名单、查防抖锁，然后决定要不要弹 CallKit！
  await CallDispatcher.instance.dispatch(message.data);

}

class AppBootstrap {
  /// 1a. 系统级初始化 — 非 Firebase 部分 (System Level)
  /// 处理所有不需要 Riverpod 参与的基础设施。
  /// Firebase 初始化已分离到 [initFirebaseAsync] 中，不阻塞首帧。
  static Future<void> initSystem() async {
    // 同步配置（顺序无关，毫秒级）
    if (kIsWeb) usePathUrlStrategy();
    GoRouter.optionURLReflectsImperativeAPIs = true;
    WidgetsFlutterBinding.ensureInitialized();

    // 先设置错误处理器，确保后续并行任务中的错误都能被捕获
    _setupErrorHandlers();

    // EasyLocalization 是唯一 blocking 首帧的依赖（文本渲染）
    // AssetManager / ApiCacheManager / Http 已移到 initNonCriticalAsync()
    await EasyLocalization.ensureInitialized();

    // DeepLink 初始化依赖其他服务就绪，放初始化完成后（fire-and-forget）
    DeepLinkService().init();
  }

  /// 1c. 非关键异步初始化 — runApp 后 fire-and-forget
  /// 不阻塞首帧渲染。AssetManager / ApiCacheManager / Http 在后台完成。
  static Future<void> initNonCriticalAsync() async {
    await Future.wait([
      AssetManager.init(),
      ApiCacheManager.init(),
      Http.init(),
    ]);
  }

  /// 1b. Firebase 异步初始化（runApp 后 fire-and-forget）
  /// 不阻塞首帧渲染。Firebase SDK 脚本下载（~165ms）在后台完成。
  /// fcmInitProvider 通过 firebaseInitProvider 依赖链保证 Firebase 就绪后
  /// 才访问 FirebaseMessaging.instance，避免 [core/no-app] 崩溃。
  static Future<void> initFirebaseAsync() async {
    await _setupFirebase();
  }

  /// 2. 数据级初始化 (Data Level)
  /// 读取本地存储，决定 App 启动时的初始状态 (Overrides)
  static Future<List<Override>> loadInitialOverrides() async {
    final prefs = await SharedPreferences.getInstance();

    // A. 主题处理 — 默认黑色主题
    // 迁移：首次升级后清除旧版 'light' 偏好，让新 dark 默认值生效
    // 后续用户手动切换（设置页）仍会保存偏好，重启后恢复
    const migrationKey = 'theme_migration_v1_dark';
    if (!(prefs.getBool(migrationKey) ?? false)) {
      await prefs.remove('app_theme_mode');
      await prefs.setBool(migrationKey, true);
    }

    final savedThemeMode = prefs.getString('app_theme_mode');
    final initialThemeMode = ThemeMode.values.firstWhere(
          (mode) => mode.name == savedThemeMode,
      orElse: () => ThemeMode.dark,
    );

    // B. Token 脏数据清洗逻辑 (你原来的核心逻辑)
    final tokenStorage = authInitialTokenStorage();
    var storedTokens = await tokenStorage.read();
    final userInfoJson = prefs.getString('user_info_storage');

    final hasToken = storedTokens.$1 != null;
    final hasUser = userInfoJson != null;

    if (hasToken && !hasUser) {
      debugPrint('[Bootstrap] Found token but no user info. Cleaning dirty data.');
      await tokenStorage.clear();
      storedTokens = (null, null);
    } else {
      debugPrint( '[Bootstrap] Token check passed.');
    }

    // 返回 Provider 的覆盖列表
    return [
      initialThemeModeProvider.overrideWithValue(initialThemeMode),
      initialTokensProvider.overrideWithValue(storedTokens),
    ];
  }

  ///  新增：专门配置全局拦截器的方法
  static void setupInterceptors(ProviderContainer container) {
    Http.onTokenInvalid = () async {
      // 通过 container 直接读取，不需要依赖 UI
      final authNotifier = container.read(authProvider.notifier);
      await authNotifier.logout();
    };

    Http.onTokenRefresh = (String newAccess, String? newRefresh) async {
      final authNotifier = container.read(authProvider.notifier);
      authNotifier.updateTokens(newAccess, newRefresh);
    };
  }

  // --- 私有辅助函数 ---

  static void _setupErrorHandlers() {
    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint("[PlatformError] $error\n$stack");
      return true;
    };
  }

  static Future<void> _setupFirebase() async {
    try {
      // [Phase 3 优化] Web 端超时缩短至 5s（弱网最多节省 5s），Native 保持 10s。
      // 超时后 Firebase 降级运行（已有 catch 兜底），不影响业务主流程。
      await FirebaseService.initialize()
          .timeout(kIsWeb ? const Duration(seconds: 5) : const Duration(seconds: 10));

      //  核心修改：只有在【非 Web】平台才注册这个后台处理函数
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      }

      debugPrint("[Firebase] Core initialized.");
    } catch (e) {
      // 超时或失败均不崩溃，App 在无 Firebase 状态下继续运行
      debugPrint("[Firebase] Init failed or timed out: $e");
    }
  }
}