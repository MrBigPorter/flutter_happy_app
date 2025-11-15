// main.dart
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/routes/app_router.dart';
import 'theme/theme_provider.dart';
import 'app/app.dart';



Future<void> main() async {

  // Web 去掉 #，其它平台无影响
  if (kIsWeb) usePathUrlStrategy();
  //  让 push 也同步 URL
  GoRouter.optionURLReflectsImperativeAPIs = true;

  bool errorHandlerRegistered = false;

  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Http.init();

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

  // 2) 预加载主题模式（避免先亮后暗）
  final themeProvider = ThemeProvider();
  await themeProvider.ready; // 在 ThemeProvider 里暴露一个 ready Future，见下


  runApp(
    riverpod.ProviderScope(
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('tl')],
          path: 'assets/locales',
          fallbackLocale: const Locale('en'),
          child: ChangeNotifierProvider.value(
              value: themeProvider,
              child: ScreenUtilInit(
                  designSize: const Size(375, 812),
                  useInheritedMediaQuery: true,
                  minTextAdapt: true,
                  splitScreenMode: true,
                  builder: (_,__){
                    //3) 传给 MaterialApp.router
                    return MyApp();
                  }
              )
          ),
        ),
    )

  );
}