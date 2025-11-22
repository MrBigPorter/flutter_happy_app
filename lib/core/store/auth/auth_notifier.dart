import 'package:flutter/cupertino.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/store/auth/auth_state.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_app/core/store/token/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    ref.read(luckyProvider.notifier).refreshAll();
    debugPrint('[Auth] login() called==> access=$access, refresh=$refresh');
  }

  Future<void> logout() async {
    // Clear token for HTTP requests
    await storage.clear();
    await Http.clearToken();
    state = AuthState.initial();
  }
}
