import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/providers/app_router_provider.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../theme/theme_provider.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 全局处理 Token 失效：登出并跳转到登录页 - Global handling of token invalidation: logout and redirect to login page
    Http.onTokenInvalid ??= () async {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.logout();
    };

    // 全局处理 Token 刷新：更新存储的 Token - Global handling of token refresh: update stored tokens
    Http.onTokenRefresh ??= (String newAccess, String? newRefresh) async {
      final authNotifier = ref.read(authProvider.notifier);
      authNotifier.updateTokens(newAccess, newRefresh);
    };

    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Lucky App',

      routerConfig: router,
      themeMode: themeMode,
      theme: _buildTheme(false),
      darkTheme: _buildTheme(true),
      themeAnimationDuration: Duration.zero,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      scrollBehavior: const _NoScrollbarBehavior(),
      builder: (context, child) {
        final content = DefaultTextStyle.merge(
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.2,
            fontWeight: FontWeight.w400,
          ),
          child: child!,
        );

        return content;
      },
    );
  }
}

///  自定义 ScrollBehavior：关闭滚动条，但保留平台惯性与滚轮优化
class _NoScrollbarBehavior extends MaterialScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  BouncingScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
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
