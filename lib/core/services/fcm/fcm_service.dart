import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'fcm_dispatcher.dart';

class FcmService {
  final Ref ref;

  // 架构点：引入中枢分发器
  final FcmDispatcher _dispatcher = FcmDispatcher();

  // Lazy init: FirebaseMessaging.instance 在构造函数字段初始化时访问会触发
  // [core/no-app]（如果 Firebase 尚未就绪）。改为惰性 getter 后，FcmService
  // 可以在 Firebase 初始化完成前安全创建，实际使用时才解析实例。
  FirebaseMessaging? _firebaseMessaging;
  FirebaseMessaging get _messaging => _firebaseMessaging ??= FirebaseMessaging.instance;

  FcmService(this.ref);

  // 1. 获取 Token (逻辑保持整洁)
  Future<String?> getToken() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true, badge: true, sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print(" [FCM] 用户未授权");
        return null;
      }

      String? token;
      // Web 环境识别与 VAPID Key 注入
      if (identical(0, 0.0)) {
        token = await _messaging.getToken(
          vapidKey: "BBbbdJ94sdOcNEhL1O7ejrE_tMvnZvwoiiQfeSO1O_W5X90bhinfo5pK-wpnns7V5xlqzyOS0fYcXlon-44NjQA",
        );
      } else {
        token = await _messaging.getToken();
      }

      if (token != null) print(" [FCM] Device Token: $token");
      return token;
    } catch (e) {
      print(" [FCM] 获取 Token 失败: $e");
      return null;
    }
  }

  // 2. 初始化消息监听 (架构重构点：全流汇聚)
  Future<void> setupMsgListeners() async {
    // A. 后台点击处理
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print(' [FCM] 后台通知被点击');
      _dispatcher.dispatch(message, isInteraction: true);
    });

    // B. 前台接收处理
    FirebaseMessaging.onMessage.listen((message) {
      print(' [FCM] 前台收到消息');
      // 架构点：前台逻辑由 Dispatcher 决定是否调用 UiFactory 展示
      _dispatcher.dispatch(message, isInteraction: false);
    });

    // C. 冷启动处理
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('[FCM] 冷启动唤醒');
      _dispatcher.dispatch(initialMessage, isInteraction: true);
    }
  }

  // 监听 Token 刷新
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}