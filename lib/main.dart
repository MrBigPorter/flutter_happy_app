import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import 'package:flutter_app/ui/chat/services/network/offline_queue_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/store/auth/auth_initial.dart';
import 'theme/theme_provider.dart';
import 'app/app.dart';

// Mandatory: This must be a top-level function to handle notifications when app is killed
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("[FCM] Handling background message: ${message.messageId}");
}

Future<void> main() async {
  if (kIsWeb) usePathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs = true;

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Global Error Handlers
  _initErrorHandlers();

  // Core Service Initialization
  await EasyLocalization.ensureInitialized();
  await Http.init();

  // Step 1: Initialize Database
  await LocalDatabaseService().init();

  // Step 2: Initialize Offline Manager (Must happen after DB init)
  OfflineQueueManager().init();

  // Step 3: Initialize Firebase
  await _setupFirebase();

  // App State Initialization
  final prefs = await SharedPreferences.getInstance();
  final savedThemeMode = prefs.getString('app_theme_mode');
  final initialThemeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == savedThemeMode,
    orElse: () => ThemeMode.system,
  );

  final tokenStorage = authInitialTokenStorage();
  final storedTokens = await tokenStorage.read();

  runApp(
    riverpod.ProviderScope(
      overrides: [
        initialThemeModeProvider.overrideWithValue(initialThemeMode),
        initialTokensProvider.overrideWithValue(storedTokens),
      ],
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
    debugPrint("[Firebase] Core initialized in main.");
  } catch (e) {
    debugPrint("[Firebase] Init failed: $e");
  }
}