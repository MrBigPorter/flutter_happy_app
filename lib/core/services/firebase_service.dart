import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/firebase_options.dart';

/// Firebase Service - Unified authentication layer for all platforms
/// Solves iOS H5 OAuth interception issues by using Firebase Authentication
class FirebaseService {
  FirebaseService._();

  static bool _initialized = false;

  /// Initialize Firebase - must be called before using any Firebase services
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      _log('Firebase initialized successfully');
    } catch (e) {
      _log('Firebase initialization failed: $e');
      rethrow;
    }
  }

  /// Check if Firebase is initialized
  static bool get isInitialized => _initialized;

  static void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[FirebaseService] $message');
  }
}

