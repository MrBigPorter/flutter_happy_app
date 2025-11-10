import 'package:flutter_app/core/store/auth/auth_notifier.dart';
import 'package:flutter_app/core/store/auth/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../token/token_storage_provider.dart';

/// authProvider put in global store
/// AuthProvider - StateNotifierProvider for AuthNotifier
/// Manages authentication state using AuthNotifier and AuthState
/// Depends on TokenStorage for token management
/// Returns an instance of AuthNotifier
/// Parameters:n
/// - ref: ProviderReference - Reference to the provider container
/// - storage: TokenStorage - Token storage instance
/// Returns:
/// - AuthNotifier instance
/// Usage:
/// ```dart
/// final authState = ref.watch(authProvider);
/// ```
/// Methods:
/// - StateNotifierProvider<'AuthNotifier, AuthState'> authProvider
/// - AuthNotifier(ref, storage)
/// - ref.watch(tokenStorageProvider)
///
final authProvider = StateNotifierProvider<AuthNotifier,AuthState>((ref){
  final storage = ref.watch(tokenStorageProvider);
  return AuthNotifier(ref,storage);
});