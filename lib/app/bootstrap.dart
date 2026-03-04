import 'dart:async';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/api/http_client.dart';
import 'package:flutter_app/core/store/auth/auth_initial.dart';
import 'package:flutter_app/firebase_options.dart';
import 'package:flutter_app/theme/theme_provider.dart';
import 'package:flutter_app/utils/asset/asset_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/store/auth/auth_provider.dart';
import '../ui/chat/core/call_manager/call_dispatcher.dart';


@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  //  核心替换：不管后台收到什么牛鬼蛇神推送，全部无脑扔给我们的“总安检大门”！
  // Dispatcher 会帮我们查死人名单、查防抖锁，然后决定要不要弹 CallKit！
  await CallDispatcher.instance.dispatch(message.data);

}

class AppBootstrap {
  /// 1. 系统级初始化 (System Level)
  /// 处理所有不需要 Riverpod 参与的基础设施
  static Future<void> initSystem() async {
    // Web URL 策略
    if (kIsWeb) usePathUrlStrategy();
    GoRouter.optionURLReflectsImperativeAPIs = true;

    // Flutter 绑定
    WidgetsFlutterBinding.ensureInitialized();

    // 资源与本地化
    await AssetManager.init();
    await EasyLocalization.ensureInitialized();

    // 网络层
    await Http.init();

    // 错误捕获配置
    _setupErrorHandlers();

    // Firebase
    await _setupFirebase();
  }

  /// 2. 数据级初始化 (Data Level)
  /// 读取本地存储，决定 App 启动时的初始状态 (Overrides)
  static Future<List<Override>> loadInitialOverrides() async {
    final prefs = await SharedPreferences.getInstance();

    // A. 主题处理
    final savedThemeMode = prefs.getString('app_theme_mode');
    final initialThemeMode = ThemeMode.values.firstWhere(
          (mode) => mode.name == savedThemeMode,
      orElse: () => ThemeMode.system,
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
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      debugPrint("[Firebase] Core initialized.");
    } catch (e) {
      debugPrint("[Firebase] Init failed: $e");
    }
  }
}