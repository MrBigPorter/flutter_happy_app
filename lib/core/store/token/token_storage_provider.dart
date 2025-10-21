import 'package:flutter/foundation.dart';
import 'package:flutter_app/core/store/token/secure_token_storage.dart';
import 'package:flutter_app/core/store/token/token_storage.dart';
import 'package:flutter_app/core/store/token/web_shared_preferences_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// TokenStorage provider
/// Provides different implementations based on the platform
/// - WebPreferencesStorage for web platform
/// - SecureTokenStorage for other platforms
/// Returns: TokenStorage instance
/// Usage:
/// ```dart
/// final tokenStorage = ref.watch(tokenStorageProvider);
/// ```
final tokenStorageProvider = Provider<TokenStorage>((ref){
  if(kIsWeb){
    // Use WebPreferencesStorage for web platform
    return WebPreferencesStorage();
  }else{
    // Use SecureTokenStorage for other platforms
    return SecureTokenStorage();
  }
});