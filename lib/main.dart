import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app/app.dart';
import 'app/app_startup.dart';
import 'app/bootstrap.dart';

void main() {
  // 第一道防线：捕捉 Flutter UI 渲染层的报错
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint(' [Flutter 致命错误]: ${details.exceptionAsString()}');
  };

  // 第二道防线：黑匣子，捕捉所有异步、插件报错
  runZonedGuarded(() async {
    // 必须加上这句：确保 Flutter 底层绑定初始化完成
    WidgetsFlutterBinding.ensureInitialized();

    // 1. 系统初始化 (无返回值，纯副作用)
    await AppBootstrap.initSystem();

    // 2. 加载初始配置 (获取 Overrides)
    final overrides = await AppBootstrap.loadInitialOverrides();

    // 3. 创建状态容器
    final container = ProviderContainer(overrides: overrides);
    AppBootstrap.setupInterceptors(container);

    //  核心架构升级：数据屏障！
    // 在这里强制阻断，通过 container.read 手动触发并等待 startup 逻辑跑完。
    try {
      await container.read(appStartupProvider.future);
      debugPrint(' [架构日志] 所有底层数据预热完毕，准备渲染 UI！');
    } catch (e, stackTrace) {
      debugPrint(' [架构日志] AppStartup 初始化出现异常: $e');
    }

    // 4. 启动 UI：直接渲染 MyApp，零白屏，零中间态！
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
            //  直接挂载真实业务入口
            builder: (_, __) => const MyApp(),
          ),
        ),
      ),
    );
  }, (error, stackTrace) {
    debugPrint(' [全局拦截到的崩溃异常]: $error');
    debugPrint(' [异常堆栈]: $stackTrace');
  });
}

