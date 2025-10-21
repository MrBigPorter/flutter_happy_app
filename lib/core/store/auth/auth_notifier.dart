import 'package:flutter_app/core/store/auth/auth_state.dart';
import 'package:flutter_app/core/store/token/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  AuthNotifier(this.ref,this.storage) : super(AuthState.initial()){
     _rehydrate();
  }

  final Ref ref;
  final TokenStorage storage;

  Future<void> _rehydrate() async {
    final (access,refresh) = await storage.read();
    if(access != null){
      state = state.copyWith(accessToken:access, refreshToken: refresh,isAuthenticated: true);
    }
  }

  Future<void> login(String access, String? refresh) async {
    await storage.save(access, refresh);
    state = state.copyWith(accessToken: access, refreshToken: refresh,isAuthenticated: true);
  }

  Future<void> logout() async {
    await storage.clear();
    state = AuthState.initial();
  }
}