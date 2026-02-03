import 'package:flutter/cupertino.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/services/socket/socket_service.dart';

import '../api/http_client.dart';

// 1. 获取 SocketService 单例
final service = SocketService();

final socketServiceProvider = Provider<SocketService>((ref) {
  //  1. 打印 Provider 被触发的日志
  debugPrint("👀 [Provider] SocketProvider 正在构建/刷新...");

  // 监听 Token
  final token = ref.watch(authProvider.select((state) => state.accessToken));

  //  2. 打印拿到的 Token 情况 (只打前几位，保护隐私)
  if (token != null && token.isNotEmpty) {
    debugPrint("👀 [Provider] 拿到 Token: ${token.substring(0, 5)}... 准备调用 init");

    // 调用初始化
    service.init(token: token);
  } else {
    debugPrint("👀 [Provider] Token 为空或 null，调用 disconnect");
    service.disconnect();
  }


  // 5. 生命周期管理
  ref.onDispose(() {
    debugPrint("👀 [Provider] 被销毁");
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