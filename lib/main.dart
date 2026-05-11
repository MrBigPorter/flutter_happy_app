import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app/app.dart';
import 'app/app_startup.dart';
import 'app/bootstrap.dart';
import 'core/services/auth/global_oauth_handler.dart';
import 'core/services/auth/deep_link_oauth_service.dart';
import 'utils/pwa_helper_web.dart'
    if (dart.library.io) 'utils/pwa_helper_stub.dart';

void main() {
  // 第一道防线：捕捉 Flutter UI 渲染层的报错
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint(' [Flutter 致命错误]: ${details.exceptionAsString()}');
  };

  // 第二道防线：黑匣子，捕捉所有异步、插件报错
  runZonedGuarded(() async {
    // 必须加上这句：确保 Flutter 底层绑定初始化完成
    WidgetsFlutterBinding.ensureInitialized();

    // PWA: Register web implementation on web platform
    if (kIsWeb) registerPwaHelperWeb();

    // 1. 系统初始化 (无返回值，纯副作用)
    await AppBootstrap.initSystem();

    // 2. 加载初始配置 (获取 Overrides)
    final overrides = await AppBootstrap.loadInitialOverrides();

    // 3. 创建状态容器
    final container = ProviderContainer(overrides: overrides);
    AppBootstrap.setupInterceptors(container);

    // 初始化全局OAuth处理器（解决Native端OAuth页面销毁问题）
    GlobalOAuthHandler.initialize(container);
    debugPrint(' [架构日志] 全局OAuth处理器已初始化');

    // 初始化 Deep Link OAuth 服务（三端统一）
    DeepLinkOAuthService.initialize();
    debugPrint(' [架构日志] Deep Link OAuth 服务已初始化');

    // Deep Link OAuth 不需要 Web 重定向恢复逻辑
    // 所有 OAuth 状态由后端管理，前端只需等待 Deep Link 回调


    // [Phase 1 优化] 数据预热改为后台运行，不再阻塞 runApp。
    // 安全保障：authProvider 已在 ProviderContainer 创建时同步读取 initialTokensProvider，
    // isAuthenticated 在第一帧即正确；GoRouter redirect 守卫（app_router.dart:607）兜底鉴权跳转。
    // 副作用：认证用户首次进入聊天模块时可能有 200-500ms Loading，属于可接受取舍。
    unawaited(
      container.read(appStartupProvider.future).catchError((e) {
        debugPrint(' [架构日志] AppStartup 后台初始化异常: $e');
      }),
    );

    // 4. 启动 UI：runApp 前移，首帧立即可见，消除启动白屏。
    //    Firebase 异步初始化（不阻塞 runApp），节省 ~165ms 首帧延迟。
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

    // 5. Firebase 异步初始化（runApp 后 fire-and-forget）
    //    Firebase SDK 脚本下载（~165ms）不再阻塞首帧。
    unawaited(AppBootstrap.initFirebaseAsync());

  }, (error, stackTrace) {
    debugPrint(' [全局拦截到的崩溃异常]: $error');
    debugPrint(' [异常堆栈]: $stackTrace');
  });
}

