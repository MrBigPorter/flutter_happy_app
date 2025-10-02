// main.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'theme/theme_provider.dart';
import 'app/app.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('❌ Platform error: $error\n$stack');
    return true;
  };


  // 2) 预加载主题模式（避免先亮后暗）
  final themeProvider = ThemeProvider();
  await themeProvider.ready; // 在 ThemeProvider 里暴露一个 ready Future，见下

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('tl')],
      path: 'assets/locales',
      fallbackLocale: const Locale('en'),
      child: ChangeNotifierProvider.value(
        value: themeProvider,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),

          minTextAdapt: true,
          builder: (_,__)=>MyApp()
        )
      ),
    ),
  );
}