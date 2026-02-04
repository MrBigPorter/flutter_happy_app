import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/fcm_notification.dart';
import '../services/fcm/fcm_service.dart';

//  修改这里：把 FutureProvider 改成 Provider
// 因为创建 Service 实例本身是瞬间完成的，不需要 Future
// 1. 定义 Service (用普通 Provider)
final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(ref);
});

final fcmInitProvider = FutureProvider<void>((ref) async {
  // A. 拿到工具人
  // 现在 watch 拿到的直接就是 FcmService 实例了
  final fcmService = ref.watch(fcmServiceProvider);

  // 先启动监听！(加这一行)
  await fcmService.setupMsgListeners();

  //  修复点 1: 先定义局部函数 (Local Function)
  // 必须定义在前面，或者放在外面，不然下面没法调用
  Future<void> uploadTokenToBackend(String? token) async {
    try {
      String platformName;

      if (kIsWeb) {
        platformName = 'web'; // 如果是网页，定义为 web
      } else if (Platform.isAndroid) {
        platformName = 'android';
      } else if (Platform.isIOS) {
        platformName = 'ios';
      } else {
        platformName = 'unknown';
      }

      final dto = FcmNotificationDeviceRegisterDto(
        token: token!,
        platform: platformName, // 使用我们判断好的变量
      );

      print(" [FCM] 上传 Token 到后端: ${dto.toJson()}");
      await Api.fcmNotificationDeviceRegisterApi(dto);
    } catch (e) {
      print("❌ [FCM] 上传失败: $e");
    }
  }


  // B. 尝试获取 Token (调用刚才改过的方法)
  // 这里只负责“拿”，不负责“传”
  String? token = await fcmService.getToken();

  // C. 打印结果 (实际项目中这里可以做更多事，比如注册到后端)
  if (token != null) {
    print("✅ [FCM] 初始化成功，Token: $token");
    uploadTokenToBackend(token);
  }

  fcmService.onTokenRefresh.listen((newToken) async {
    print("🔄 [FCM] Token 刷新: $newToken");
    // 刷新后也上传到后端
    await uploadTokenToBackend(newToken);
  });
});
