// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'theme/token_theme.dart';
import 'theme/theme_provider.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // 1) 预加载 tokens（同步给 MyApp）
  final lightTokens = await TokenTheme.fromAsset('assets/figma-tokens.light.json', dark: false);
  final darkTokens  = await TokenTheme.fromAsset('assets/figma-tokens.dark.json',  dark: true);

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
          builder: (_,__)=>MyApp(lightTokens: lightTokens, darkTokens: darkTokens)
        )
      ),
    ),
  );
}