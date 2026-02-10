import 'dart:ui';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/events/global_handler.dart';
import 'package:flutter_app/core/providers/app_router_provider.dart';
import 'package:flutter_app/core/providers/fcm_service_provider.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../theme/theme_provider.dart';
import '../core/providers/socket_provider.dart';
import '../ui/chat/services/chat_event_processor.dart';

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
    // Token 失效处理保持不变
    Http.onTokenInvalid ??= () async {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.logout();
    };

    Http.onTokenRefresh ??= (String newAccess, String? newRefresh) async {
      final authNotifier = ref.read(authProvider.notifier);
      authNotifier.updateTokens(newAccess, newRefresh);
    };

    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    //watch 它，让 SocketService 实例保持存活，并开始监听 Auth 变化。
    // 我们不需要用它的返回值，只需要它活着。
     ref.watch(socketServiceProvider);

    // 2. 启动 Socket 事件处理器 (指挥官)
    // 只要这一行在，ChatEventProcessor 就开始工作，
    // 无论用户在哪个页面，它都会在后台监听并更新数据库。
    ref.watch(chatEventProcessorProvider);

    // 初始化 FCM 服务
     ref.watch(fcmInitProvider);



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

        // 2. 包裹你的全局逻辑处理 (Socket监听等)
        child = GlobalHandler(child: content);

        // 3. 最外层包裹 BotToastInit
        // 这样 BotToast 才能覆盖在所有页面(包括 GlobalHandler)之上
        return BotToastInit()(context, child);
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
