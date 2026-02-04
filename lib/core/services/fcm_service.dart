import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FcmService {
  final Ref ref;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  FcmService(this.ref);

  // 1. 获取 Token (适配 Web 端)
  Future<String?> getToken() async {
    try {
      // iOS / Android 13+ / Web 请求权限
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print(" [FCM] 用户未授权通知权限");
        return null;
      }

      // --- 修改这里 ---
      String? token;
      if (identical(0, 0.0)) { // 这是一个判断是否在 Web 环境的常用技巧
        // 如果是 Web 端，必须传入 vapidKey
        token = await _firebaseMessaging.getToken(
          vapidKey: "BBbbdJ94sdOcNEhL1O7ejrE_tMvnZvwoiiQfeSO1O_W5X90bhinfo5pK-wpnns7V5xlqzyOS0fYcXlon-44NjQA",
        );
      } else {
        // 如果是手机端，保持原样
        token = await _firebaseMessaging.getToken();
      }
      // ----------------

      if (token != null) {
        print(" [FCM] Device Token: $token");
        return token;
      }
    } catch (e) {
      print(" [FCM] 获取 Token 失败: $e");
      return null;
    }
    return null;
  }

  // 2.  初始化消息监听 (处理点击跳转 + 前台接收)
  Future<void> setupMsgListeners() async {
    // ----------------------------------------------------------
    // A. 冷启动处理 (App 被完全杀死状态下，点击通知启动)
    // ----------------------------------------------------------
    
    print('[FCM] 设置冷启动监听');

    // ----------------------------------------------------------
    // B. 后台运行处理 (App 在后台/锁屏，点击通知回到前台)
    // ----------------------------------------------------------
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(' [FCM] App 在后台被点击');
      _handleMessageInteraction(message);
    });

    // ----------------------------------------------------------
    // C. 前台运行处理 (App 正在前台使用，收到推送)
    // ----------------------------------------------------------
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {

        // 使用自定义构建，可以获得 context，从而自动适配主题
        BotToast.showCustomNotification(
          duration: const Duration(seconds: 4),
          toastBuilder: (cancelFunc) {
            return Card(
              // Card 默认会自动适配 Theme 的 cardColor
              margin: const EdgeInsets.only(top: 10, left: 16, right: 16),
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                // Leading 可以放个 Logo 或 Icon
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.deepOrange.withOpacity(0.1),
                      shape: BoxShape.circle
                  ),
                  child: const Icon(Icons.notifications, color: Colors.deepOrange),
                ),
                title: Text(
                  message.notification!.title ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  message.notification!.body ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  cancelFunc(); // 点击后先关闭弹窗
                  _handleMessageInteraction(message); // 再跳转
                },
              ),
            );
          },
        );
      }
    });
    
    RemoteMessage? initialMessage =
    await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('[FCM] App 被通知冷启动');
      _handleMessageInteraction(initialMessage);
    }


  }

  //  [统一处理跳转逻辑]
  void _handleMessageInteraction(RemoteMessage message) {
    final data = message.data;
    print(" [FCM] 准备跳转，参数: $data");

    // 1. 获取消息类型和关键 ID
    final String? type = data['type'];
    final String? id = data['id'];

    // 2. 根据类型分发路由
    switch (type) {

    // 场景 A: 拼团结果通知 (成团/失败)
      case 'group_detail':
        if (id != null && id.isNotEmpty) {
          // 对应你路由里的 name: 'groupRoom'
          // 对应你路由里的 queryParameters['groupId']
          appRouter.pushNamed(
            'groupRoom',
            queryParameters: {'groupId': id},
          );
        }
        break;

    // 场景 B: 聊天私信 (预留)
      case 'chat':
      // 假设你的聊天路由是 /chat/:id
      // if (id != null) appRouter.push('/chat/room/$id');
        break;

    // 场景 C: 系统公告或默认
      case 'system':
      default:
      // 如果没有特定类型，或者类型不认识，跳到首页或者消息中心
        appRouter.pushNamed('home');
        break;
    }
  }

  // 监听 Token 刷新
  Stream<String> get onTokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;
}