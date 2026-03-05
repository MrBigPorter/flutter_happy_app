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

/// AuthNotifier manages the authentication lifecycle of the application.
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
  ) {
    // Initialize HTTP client token if access token exists
    if (initialAccess != null && initialAccess.isNotEmpty) {
      Http.setToken(initialAccess);
      debugPrint('[Auth] Constructor: initialAccess set');
    }
  }

  final Ref ref;
  final TokenStorage storage;

  /// Handles user login by storing tokens and fetching initial profile data.
  Future<void> login(String access, String? refresh) async {
    Http.setToken(access);
    await storage.save(access, refresh);

    state = state.copyWith(
      accessToken: access,
      refreshToken: refresh,
      isAuthenticated: true,
    );

    // Critical Path: Fetch user profile synchronously to ensure UserID is available.
    await ref.read(userProvider.notifier).fetchProfile();

    // Background Tasks: Fetch non-critical data without blocking navigation.
    Future.wait<void>([
      ref.read(walletProvider.notifier).fetchBalance(),
    ]).then((_) {
      debugPrint('[Auth] Login: Background data loaded');
    }).catchError((e) {
      debugPrint('[Auth] Login: Background data error: $e');
    });
  }

  /// Updates current access and refresh tokens.
  void updateTokens(String access, String? refresh) {
    state = state.copyWith(
      accessToken: access,
      refreshToken: refresh,
      isAuthenticated: true,
    );
  }

  /// Handles user logout by clearing tokens, closing DB, and navigating to home.
  Future<void> logout() async {
    // 1. Clear local persistence and HTTP headers
    await storage.clear();
    await Http.clearToken();

    // 2. Close database services
    await LocalDatabaseService.close();

    // 3. Reset authentication state
    state = AuthState.initial();

    // 4. Navigate to home page safely.
    // Using go() instead of replace() is more robust for cross-ShellRoute navigation.
    // Microtask ensures navigation occurs after the current state-change build cycle.
    Future.microtask(() => appRouter.go('/home'));

    debugPrint('[Auth] Logout: State reset and navigating to home');
  }
}