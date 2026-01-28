import 'dart:async';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/theme/theme_provider.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import 'package:flutter_app/ui/chat/services/network/offline_queue_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/api/http_client.dart';
import 'core/store/auth/auth_initial.dart';

// FCM 背景消息处理（必须在顶级作用域）
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("[FCM] Handling background message: ${message.messageId}");
}

Future<void> main() async {
  // 1. 基础初始化
  if (kIsWeb) usePathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 初始化全局错误捕获
  _initErrorHandlers();

  // 3. 核心服务初始化
  await EasyLocalization.ensureInitialized();
  // 注意：确保你的 Http 类里有 init 方法
  await Http.init();

  // 4. 数据库初始化
  await LocalDatabaseService().init();

  // 5. 准备 Riverpod 的初始数据
  final prefs = await SharedPreferences.getInstance();
  final savedThemeMode = prefs.getString('app_theme_mode');
  final initialThemeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == savedThemeMode,
    orElse: () => ThemeMode.system,
  );

  final tokenStorage = authInitialTokenStorage();
  final storedTokens = await tokenStorage.read();

  // 6.  创建手动容器 (核心重构)
  // 这允许我们在跑 runApp 之前就访问 Provider
  final container = riverpod.ProviderContainer(
    overrides: [
      initialThemeModeProvider.overrideWithValue(initialThemeMode),
      initialTokensProvider.overrideWithValue(storedTokens),
    ],
  );

  // 7. 初始化离线队列 (传入容器)
  // 确保 OfflineQueueManager 的 init 方法接收 dynamic 或 ProviderContainer
  OfflineQueueManager().init(container);

  // 8. 初始化 Firebase
  await _setupFirebase();

  runApp(
    // 9. 使用 UncontrolledProviderScope 绑定容器
    riverpod.UncontrolledProviderScope(
      container: container,
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('tl')],
        path: 'assets/locales',
        fallbackLocale: const Locale('en'),
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (_, __) => const MyApp(),
        ),
      ),
    ),
  );
}

// --- 补齐缺失的工具函数 ---

void _initErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint("[PlatformError] $error\n$stack");
    return true;
  };
}

Future<void> _setupFirebase() async {
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint("[Firebase] Core initialized.");
  } catch (e) {
    debugPrint("[Firebase] Init failed: $e");
  }
}