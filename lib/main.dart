import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app/app.dart';
import 'app/app_startup.dart';
import 'app/bootstrap.dart'; // 引入刚才新建的文件

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

// 原来的 AppBootstrap Widget 改名为 AppBootstrapWidget 或 AppRoot
class AppBootstrapWidget extends ConsumerWidget {
  const AppBootstrapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听启动逻辑 (AppStartup)
    final startupState = ref.watch(appStartupProvider);

    return startupState.when(
      data: (_) => const MyApp(),
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: const Center(child: CircularProgressIndicator.adaptive()),
        ),
      ),
      error: (e, st) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                Text("Error: $e"),
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