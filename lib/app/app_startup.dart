import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_startup.g.dart';

@Riverpod(keepAlive: true)
Future<void> appStartup(AppStartupRef ref) async {
  // 1. [Fix] Do not await the future, simply watch to keep it alive.
  // Since AuthNotifier initializes by reading the Token synchronously,
  // it has its state immediately upon startup.
  ref.watch(authProvider);

  final authState = ref.read(authProvider);

  // 2. If authenticated
  if (authState.isAuthenticated) {
    String? userId;

    // ---------------------------------------------------------
    // Speed Solution: Bypass the Store and read UserID directly from disk (SP)
    // ---------------------------------------------------------
    try {
      final prefs = await SharedPreferences.getInstance();
      // 'lucky_state' is the storageKey defined in your LuckyNotifier
      final String? jsonStr = prefs.getString('lucky_state');

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        // Manual parsing: root -> userInfo -> id
        if (data['userInfo'] != null) {
          userId = data['userInfo']['id'];
          debugPrint("[AppStartup] UserID hit directly from disk: $userId");
        }
      }
    } catch (e) {
      debugPrint("[AppStartup] Disk read/parse failed: $e");
    }

    // ---------------------------------------------------------
    // 3. Initialize database (Millisecond level, no lag)
    // ---------------------------------------------------------
    if (userId != null && userId.isNotEmpty) {
      // As long as we have the ID, initialize DB immediately.
      // This ensures the database is Ready when the Socket receives messages!
      await LocalDatabaseService.init(userId);
      debugPrint("[AppStartup] Database initialized instantly (No network needed)");
    } else {
      // Only happens on fresh install or corrupted data.
      // Skip for now, let lazy load handle it after entering the main page.
      debugPrint("[AppStartup] No local cache, skipping initialization");
    }
  } else {
    debugPrint("[AppStartup] Not logged in, skipping DB initialization");
  }
}