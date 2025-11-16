import 'package:flutter/foundation.dart';
import 'package:flutter_app/core/store/token/secure_token_storage.dart';
import 'package:flutter_app/core/store/token/token_storage.dart';
import '../token/web_shared_preferences_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

TokenStorage authInitialTokenStorage() {
  // Return a TokenStorage implementation for initial auth state
  // This can be replaced with a mock or in-memory storage if needed
  if(kIsWeb){
    return WebPreferencesStorage();
  }else{
    // For non-web platforms, return a default implementation
    return SecureTokenStorage();
  }
}


/// (accessToken, refreshToken)
final initialTokensProvider = Provider<(String?, String?)>((_) => (null, null));