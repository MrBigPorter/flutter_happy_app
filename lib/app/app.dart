import 'dart:ui';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/pwa_banners.dart';
import 'package:flutter_app/core/events/global_handler.dart';
import 'package:flutter_app/core/providers/app_router_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../theme/theme_provider.dart';
import 'widgets/auth_aware_service_manager.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // [Phase 4 优化] 重服务 Provider（Socket、FCM、ChatEventProcessor）
    // 已移至 AuthAwareServiceManager，仅在认证用户时初始化。
    return MaterialApp.router(
      title: 'JoyMini',
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
        // ThemeData 已设置 fontFamily: 'Inter'（本地字体），此处直接继承，
        // 无需 GoogleFonts.inter()，避免网络字体校验延迟。
        final content = DefaultTextStyle.merge(
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            height: 1.2,
            fontWeight: FontWeight.w400,
          ),
          child: child!,
        );

        // 2. 包裹你的全局逻辑处理 (Socket监听等)
        child = GlobalHandler(child: content);

        // 3. PWA Update Banner（Web only, no-op on native）
        child = Column(
          children: [
            const PwaUpdateBanner(),
            Expanded(child: child),
          ],
        );

        // 4. 包裹 AuthAwareServiceManager (条件性初始化重服务)
        // 5. 最外层包裹 BotToastInit
        // 这样 BotToast 才能覆盖在所有页面(包括 GlobalHandler)之上
        return AuthAwareServiceManager(
          child: BotToastInit()(context, child),
        );
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
