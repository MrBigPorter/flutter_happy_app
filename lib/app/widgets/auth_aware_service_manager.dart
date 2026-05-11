import 'package:flutter/material.dart';
import 'package:flutter_app/core/providers/fcm_service_provider.dart';
import 'package:flutter_app/core/providers/socket_provider.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/ui/chat/services/chat_event_processor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Only initializes heavy services (Socket, FCM, ChatEventProcessor)
/// when the user is authenticated. For unaunthenticated users, renders nothing.
///
/// [Phase 4 优化] 将重服务 Provider 从首帧剥离，未登录用户不再触发无用初始化。
/// 登录/登出时自动跟随 auth 状态启停。
class AuthAwareServiceManager extends ConsumerWidget {
  const AuthAwareServiceManager({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuth = ref.watch(authProvider.select((s) => s.isAuthenticated));
    if (isAuth) {
      // 认证用户 → 保活重服务
      ref.watch(socketServiceProvider);
      ref.watch(chatEventProcessorProvider);
      ref.watch(fcmInitProvider);
    }
    return child;
  }
}
