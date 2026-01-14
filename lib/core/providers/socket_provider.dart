import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/services/socket_service.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';

import '../api/http_client.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  // 1. 获取 SocketService 单例
  final service = SocketService();


  // 5. 生命周期管理
  ref.onDispose(() {
    service.dispose();
  });

  service.onTokenRefreshRequest = () async {
    debugPrint("🔄 [MyApp] Socket 请求刷新 Token...");
    final bool success = await Http.tryRefreshToken(Http.rawDio);
    if(success){
      debugPrint("✅ [MyApp] 刷新成功，获取新 Token...");
      // B. 刷新成功后，从 Http 缓存拿新 Token
      final newToken = await Http.getToken();
      return newToken;
    }else{
      debugPrint("❌ [MyApp] 刷新失败，执行登出");
      // C. 刷新失败，强制登出
      await Http.performLogout();
      return null;
    }
  };

  return service;
});