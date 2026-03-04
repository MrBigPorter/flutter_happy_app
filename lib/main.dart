import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui' as ui;

import 'app/app.dart';
import 'app/app_startup.dart';
import 'app/bootstrap.dart';


Future<void> main() async {
  // 1. 系统初始化 (无返回值，纯副作用)
  await AppBootstrap.initSystem();

  // 2. 加载初始配置 (获取 Overrides)
  final overrides = await AppBootstrap.loadInitialOverrides();

  // 3. 创建容器
  final container = ProviderContainer(overrides: overrides);

  AppBootstrap.setupInterceptors(container);

  // 4. 启动 UI
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('tl')],
        path: 'assets/locales',
        fallbackLocale: const Locale('en'),
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (_, __) => const AppBootstrapWidget(), // 改个名字，避免和类名冲突
        ),
      ),
    ),
  );
}

class AppBootstrapWidget extends ConsumerWidget {
  const AppBootstrapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startupState = ref.watch(appStartupProvider);

    return startupState.when(
      data: (_) => const MyApp(), // 真正的入口，只在这里暴露路由

      //修复：改用 Directionality，不给 Flutter 拦截 URL 的机会
      loading: () => const Directionality(
        textDirection: ui.TextDirection.ltr,
          child: ColoredBox(
          color: Colors.white,
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      ),

      // 修复：错误页同理，去掉 MaterialApp
      error: (e, st) => Directionality(
        textDirection: ui.TextDirection.ltr,
        child: ColoredBox(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                Text("Error: $e", style: const TextStyle(color: Colors.black, fontSize: 14, decoration: TextDecoration.none)),
                ElevatedButton(
                  onPressed: () => ref.invalidate(appStartupProvider),
                  child: const Text("Retry"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}