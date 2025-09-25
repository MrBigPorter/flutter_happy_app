import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../theme/theme_provider.dart';
import 'page/demo_page.dart';
import 'routes/route_generator.dart';

// app/app.dart（改成无异步，首帧即最终主题）
class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.lightTokens, required this.darkTokens});
  final TokenTheme lightTokens;
  final TokenTheme darkTokens;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Lucky App',
      onGenerateRoute: RouteGenerator.generateRoute,
      navigatorKey: AppRouter.navigatorKey,
      themeMode: themeProvider.themeMode,
      theme: _buildTheme(lightTokens, dark: false),
      darkTheme: _buildTheme(darkTokens, dark: true),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: DemoPage(onToggleTheme: themeProvider.toggleTheme),
    );
  }
}

ThemeData _buildTheme(TokenTheme tokens, {required bool dark}) {
  final cs = ColorScheme.fromSeed(
    seedColor: tokens.color('colors_foreground_fg_brand_primary') ?? Colors.deepPurple,
    brightness: dark ? Brightness.dark : Brightness.light,
  ).copyWith(
    surface: tokens.color('colors_background_bg_primary'),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: cs,
    scaffoldBackgroundColor:
    tokens.color('colors_background_bg_secondary') ??
        (dark ? Colors.black : Colors.white),
    extensions: [tokens],
  );
}