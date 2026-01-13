import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_app/core/services/socket_service.dart';

part 'socket_provider.g.dart';

@Riverpod(keepAlive: true)
SocketService socketService(SocketServiceRef ref) {
  // 创建 SocketService 实例
  final service = SocketService();

  // 2. 核心：监听 AuthProvider 的变化
  // 只要 Auth 状态一变，这里马上执行
  ref.listen(authProvider, (previous, next) {
    // 情况 A: 从未登录变成已登录 (Login)
    if (next.isAuthenticated && next.accessToken != null) {
      // 只有当之前没登录，或者 Token 变了的时候才重连
      if (previous?.accessToken != next.accessToken) {
        // 用户登录后，连接 WebSocket
        service.init(token: next.accessToken!);
      }
    } else if (!next.isAuthenticated) {
      // 情况 B: 从已登录变成未登录 (Logout)
      service.disconnect();
    }
  });

  //  2. 处理 Provider 初始化时的状态 (App 刚启动时)
  // 因为 listen 只有状态变化才触发，所以第一次要手动检查
  final currentAuth = ref.read(authProvider);
  if (currentAuth.isAuthenticated && currentAuth.accessToken != null) {
    service.init(token: currentAuth.accessToken!);
  }

  // 3. 清理资源
  ref.onDispose(() {
    service.dispose();
  });

  return service;
}
