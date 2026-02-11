import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/store/auth/auth_state.dart';
import 'package:flutter_app/core/store/token/token_storage.dart';
import 'package:flutter_app/core/store/user_store.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config_store.dart';
import '../wallet_store.dart';

/// 改变登录状态的 Notifier
/// AuthNotifier - StateNotifier for authentication state management
/// Manages AuthState and handles login, logout, and rehydration
/// Parameters:
/// - ref: Ref for accessing other providers
/// - storage: TokenStorage for persisting tokens
/// Methods:
/// - Future<‘void’> _rehydrate(): Rehydrates state from storage
/// - Future<‘void’> login(String access, String? refresh): Logs in user and saves tokens
/// - Future<’void‘> logout(): Logs out user and clears tokens
/// extends StateNotifier<‘AuthState’>
/// constructor AuthNotifier(Ref ref, TokenStorage storage)
/// - super(AuthState.initial())
/// - calls _rehydrate()
/// - final Ref ref
/// - final TokenStorage storage
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(
    this.ref,
    this.storage,
    String? initialAccess,
    String? initialRefresh,
  ) : super(
        AuthState(
          accessToken: initialAccess,
          refreshToken: initialRefresh,
          isAuthenticated: initialAccess != null,
        ),
      ){
       if(initialAccess != null && initialAccess.isNotEmpty){
         Http.setToken(initialAccess);
         debugPrint('[Auth] ctor: initialAccess=$initialAccess');
       }
  }

  final Ref ref;
  final TokenStorage storage;

  Future<void> login(String access, String? refresh) async {
    // Set token for HTTP requests
    Http.setToken(access);
    await storage.save(access, refresh);
    state = state.copyWith(
      accessToken: access,
      refreshToken: refresh,
      isAuthenticated: true,
    );

    //  第一步：关键路径 (Critical Path)
    // =========================================================
    // 必须 Await！因为没有 UserID，进入 APP 会崩 (数据库无法初始化)
    // 这个接口通常很快 (<200ms)
    await ref.read(userProvider.notifier).fetchProfile();

   // =========================================================
    // 第二步：后台加载 (Background Fetch)
    // =========================================================
    // 不加 await！让它们在后台悄悄跑，用户立马能跳转进首页
    // 钱包余额和系统配置会在 1秒左右后自动刷新出来
    Future.wait<void>([
      ref.read(walletProvider.notifier).fetchBalance(),
      ref.read(configProvider.notifier).fetchLatest(),
    ]).then((_) {
      if(kDebugMode){
        print('[LOGIN]==> background data loaded: wallet and config refreshed');
      }
    }).catchError((e) {
      if(kDebugMode){
        print('[LOGIN]==> background data load error: $e');
      }
    });
  }

  void updateTokens(String access, String? refresh) {
    state = state.copyWith(
      accessToken: access,
      refreshToken: refresh,
      isAuthenticated: true,
    );
  }

  Future<void> logout() async {
    // Clear token for HTTP requests
    await storage.clear();
    await Http.clearToken();
    await LocalDatabaseService.close();
    state = AuthState.initial();
    appRouter.replace('/home');
  }
}
