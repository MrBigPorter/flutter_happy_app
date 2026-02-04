import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'fcm_dispatcher.dart';

class FcmService {
  final Ref ref;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // 架构点：引入中枢分发器
  final FcmDispatcher _dispatcher = FcmDispatcher();

  FcmService(this.ref);

  // 1. 获取 Token (逻辑保持整洁)
  Future<String?> getToken() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true, badge: true, sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print(" [FCM] 用户未授权");
        return null;
      }

      String? token;
      // Web 环境识别与 VAPID Key 注入
      if (identical(0, 0.0)) {
        token = await _firebaseMessaging.getToken(
          vapidKey: "BBbbdJ94sdOcNEhL1O7ejrE_tMvnZvwoiiQfeSO1O_W5X90bhinfo5pK-wpnns7V5xlqzyOS0fYcXlon-44NjQA",
        );
      } else {
        token = await _firebaseMessaging.getToken();
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
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('[FCM] 冷启动唤醒');
      _dispatcher.dispatch(initialMessage, isInteraction: true);
    }
  }

  // 监听 Token 刷新
  Stream<String> get onTokenRefresh => _firebaseMessaging.onTokenRefresh;
}