// 顶部（仅 Web 打印浏览器地址需要）
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../theme/theme_provider.dart';



class MyApp extends StatefulWidget {
  final GoRouter router;
  const MyApp({super.key, required this.router});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  VoidCallback? _ripListener;


  @override
  void initState() {
    super.initState();

    final rip = widget.router.routeInformationProvider; // ValueListenable<RouteInformation>
    _ripListener = () {
      final uri = rip.value.uri;
      final goPath = uri.toString();
      // 打印一下 GoRouter 看到的地址
      debugPrint('ROUTER URI  => $goPath');

      if (!kIsWeb) return;

      final browserPath = html.window.location.pathname ?? '';
      debugPrint('BROWSER PATH (now) => $browserPath');

      // ✅ 强制把浏览器地址和 GoRouter 对齐（只在不一致时写，避免死循环）
      if (browserPath != uri.path) {
        // 用 pushState（想替换当前历史记录就用 replaceState）
        html.window.history.pushState(null, '', goPath);
        // 再打印一遍确认
        debugPrint('BROWSER PATH (fix) => ${html.window.location.pathname}');
      }
    };

    rip.addListener(_ripListener!);
  }


  @override
  void dispose() {
    if (_ripListener != null) {
      widget.router.routeInformationProvider.removeListener(_ripListener!);
    }
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'Lucky App',
      // 显式接入 GoRouter 的四件套，确保会写浏览器地址栏
      routeInformationProvider: widget.router.routeInformationProvider,
      routeInformationParser:  widget.router.routeInformationParser,
      routerDelegate:          widget.router.routerDelegate,
      backButtonDispatcher:    widget.router.backButtonDispatcher,
      // routerConfig: widget.router,
      themeMode: themeProvider.themeMode,
      theme: _buildTheme(false),
      darkTheme: _buildTheme(true),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      scrollBehavior: const _NoScrollbarBehavior(),
      builder: (context,child){
        return DefaultTextStyle.merge(
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.2,
            fontWeight: FontWeight.w400,
          ),
          child: child!,
        );
      },
    );
  }
}

/// ✅ 自定义 ScrollBehavior：关闭滚动条，但保留平台惯性与滚轮优化
class _NoScrollbarBehavior extends MaterialScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  BouncingScrollPhysics getScrollPhysics(BuildContext context) =>  const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

ThemeData _buildTheme(bool dark) {
  final brightness = dark ? Brightness.dark : Brightness.light;

  final cs =
      ColorScheme.fromSeed(
        seedColor: Colors.deepOrange,
        brightness: brightness,
      ).copyWith(
        surface: brightness == Brightness.dark
            ? TokensDark.bgMobilePrimary
            : TokensLight.bgMobilePrimary,
      );
  return ThemeData(
    fontFamily: 'Inter',
    useMaterial3: true,
    brightness: brightness,
    colorScheme: cs,
    scaffoldBackgroundColor: brightness == Brightness.dark
        ? TokensDark.bgMobilePrimary
        : TokensLight.bgMobilePrimary,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
