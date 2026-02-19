import 'dart:async';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/api/http_client.dart';
import 'package:flutter_app/core/store/auth/auth_initial.dart';
import 'package:flutter_app/firebase_options.dart';
import 'package:flutter_app/theme/theme_provider.dart';
import 'package:flutter_app/utils/asset/asset_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/store/auth/auth_provider.dart';
import '../ui/chat/services/callkit_service.dart';


@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final data = message.data;
  final String type = data['type'] ?? '';
  final String sessionId = data['sessionId'] ?? '';

  if (sessionId.isEmpty) return;

  //终极修复：后台线程检查全局时间锁
  final prefs = await SharedPreferences.getInstance();
  final int lockTime = prefs.getInt('global_call_lock') ?? 0;
  final int now = DateTime.now().millisecondsSinceEpoch;

  // 如果距离上一次处理邀请或挂断不到 5 秒（5000毫秒），直接拉黑！
  if (now - lockTime < 5000) {
    debugPrint(" [FCM Background] 全局冷却期生效！拦截短时间内疯狂轰炸的延迟推送！");
    return;
  }

  if (type == 'call_invite') {

    // 准备弹窗了，赶紧把锁续上，防止 1 秒后的下一个 FCM 弹出来
    await prefs.setInt('global_call_lock', now);

    debugPrint(" [FCM Background] 准备唤醒 CallKit...");
    await CallKitService.instance.showIncomingCall(
      uuid: sessionId,
      name: data['senderName'] ?? "Incoming Call",
      avatar: data['senderAvatar'] ?? "",
      isVideo: data['mediaType'] == 'video',
      extra: Map<String, dynamic>.from(data),
    );
  } else if (type == 'call_end') {
    debugPrint(" [FCM Background] 收到离线挂断，标记并清理");
    // 收到对方挂断了，也开启 5 秒无敌金身，防止后面的幽灵 invite 把屏幕又亮起来
    await prefs.setInt('global_call_lock', now);
    await CallKitService.instance.endCall(sessionId);
    await CallKitService.instance.clearAllCalls();
  }
}

class AppBootstrap {
  /// 1. 系统级初始化 (System Level)
  /// 处理所有不需要 Riverpod 参与的基础设施
  static Future<void> initSystem() async {
    // Web URL 策略
    if (kIsWeb) usePathUrlStrategy();
    GoRouter.optionURLReflectsImperativeAPIs = true;

    // Flutter 绑定
    WidgetsFlutterBinding.ensureInitialized();

    // 资源与本地化
    await AssetManager.init();
    await EasyLocalization.ensureInitialized();

    // 网络层
    await Http.init();

    // 错误捕获配置
    _setupErrorHandlers();

    // Firebase
    await _setupFirebase();
  }

  /// 2. 数据级初始化 (Data Level)
  /// 读取本地存储，决定 App 启动时的初始状态 (Overrides)
  static Future<List<Override>> loadInitialOverrides() async {
    final prefs = await SharedPreferences.getInstance();

    // A. 主题处理
    final savedThemeMode = prefs.getString('app_theme_mode');
    final initialThemeMode = ThemeMode.values.firstWhere(
          (mode) => mode.name == savedThemeMode,
      orElse: () => ThemeMode.system,
    );

    // B. Token 脏数据清洗逻辑 (你原来的核心逻辑)
    final tokenStorage = authInitialTokenStorage();
    var storedTokens = await tokenStorage.read();
    final userInfoJson = prefs.getString('user_info_storage');

    final hasToken = storedTokens.$1 != null;
    final hasUser = userInfoJson != null;

    if (hasToken && !hasUser) {
      debugPrint('[Bootstrap] Found token but no user info. Cleaning dirty data.');
      await tokenStorage.clear();
      storedTokens = (null, null);
    } else {
      debugPrint( '[Bootstrap] Token check passed.');
    }

    // 返回 Provider 的覆盖列表
    return [
      initialThemeModeProvider.overrideWithValue(initialThemeMode),
      initialTokensProvider.overrideWithValue(storedTokens),
    ];
  }

  ///  新增：专门配置全局拦截器的方法
  static void setupInterceptors(ProviderContainer container) {
    Http.onTokenInvalid = () async {
      // 通过 container 直接读取，不需要依赖 UI
      final authNotifier = container.read(authProvider.notifier);
      await authNotifier.logout();
    };

    Http.onTokenRefresh = (String newAccess, String? newRefresh) async {
      final authNotifier = container.read(authProvider.notifier);
      authNotifier.updateTokens(newAccess, newRefresh);
    };
  }

  // --- 私有辅助函数 ---

  static void _setupErrorHandlers() {
    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint("[PlatformError] $error\n$stack");
      return true;
    };
  }

  static Future<void> _setupFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      debugPrint("[Firebase] Core initialized.");
    } catch (e) {
      debugPrint("[Firebase] Init failed: $e");
    }
  }
}