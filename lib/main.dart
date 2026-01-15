// main.dart
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/store/auth/auth_initial.dart';
import 'theme/theme_provider.dart';
import 'app/app.dart';


Future<void> main() async {
// main.dart 中正常初始化 Firebase 即可
  // Web 去掉 #，其它平台无影响
  if (kIsWeb) usePathUrlStrategy();
  //  让 push 也同步 URL
  GoRouter.optionURLReflectsImperativeAPIs = true;

  bool errorHandlerRegistered = false;

  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Http.init();

  //  [新增] 2. 初始化 Firebase
  try {
    await Firebase.initializeApp();

    // 🔥 [新增] 3. 获取并打印 FCM Token
    final fcmToken = await FirebaseMessaging.instance.getToken();
    print("🔥 [FCM] Device Token: $fcmToken");

  } catch (e) {
    print("❌ Firebase 初始化失败: $e");
  }

  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };


  void registerGlobalErrorHandler() {
    if (errorHandlerRegistered) return;
    errorHandlerRegistered = true;

    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Platform error: $error\n$stack');
      return true;
    };
  }

  registerGlobalErrorHandler();

  // theme provider
  final prefs = await SharedPreferences.getInstance();
  final savedThemeMode = prefs.getString('app_theme_mode');

  final initialThemeMode = ThemeMode.values.firstWhere(
    (mode) => mode.name == savedThemeMode,
    orElse: () => ThemeMode.system,
  );


  //auth initial, read token from storage first
  final tokenStorage = authInitialTokenStorage();
  final storedTokens = await tokenStorage.read();



  runApp(
    riverpod.ProviderScope(
        overrides: [
          // 4) 覆盖初始主题模式 provider
          initialThemeModeProvider.overrideWithValue(initialThemeMode),
          // 传给 AuthNotifier 的初始 token
          initialTokensProvider.overrideWithValue(storedTokens),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('tl')],
          path: 'assets/locales',
          fallbackLocale: const Locale('en'),
          child: ScreenUtilInit(
              designSize: const Size(375, 812),
              useInheritedMediaQuery: true,
              minTextAdapt: true,
              splitScreenMode: true,
              builder: (_,__){
                //3) 传给 MaterialApp.router
                return MyApp();
              }
          ),
        ),
    )

  );
}