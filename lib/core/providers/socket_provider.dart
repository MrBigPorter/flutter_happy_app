import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/services/socket_service.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  // 1. 获取 SocketService 单例
  final service = SocketService();

  // 2. 监听 Auth 状态
  final authState = ref.watch(authProvider);

  // 3. 解析 Token (根据刚才调试的结果，字段名是 accessToken)
  String token = '';

  // 使用 dynamic 访问，兼容不同 State 写法，只取 accessToken
  try {
    final dynamic state = authState;
    if (state.accessToken != null && state.accessToken is String) {
      token = state.accessToken;
    }
  } catch (_) {
    // 忽略错误，默认为空
  }

  // 4. 根据 Token 决定 Socket 行为
  if (token.isNotEmpty) {
    // 已登录：强制带 Token 重连
    service.init(token: token);
  } else {
    // 未登录：断开连接 (防止游客接收旧用户的私信)
    service.disconnect();
  }

  // 5. 生命周期管理
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});