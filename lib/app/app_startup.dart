

import 'package:flutter/cupertino.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/store/auth/auth_provider.dart';
import '../ui/chat/services/database/local_database_service.dart';

final appStartupProvider = FutureProvider<void>((ref) async{
  debugPrint("[AppStartup] Starting initialization...");

  final isAuthenticated = ref.read(authProvider.select((s) => s.isAuthenticated));
  // get current user id
  final userId = ref.read(luckyProvider.select((s) => s.userInfo?.id));

  if(isAuthenticated && userId != null && userId.isNotEmpty){
    await LocalDatabaseService.init(userId);
    debugPrint("[AppStartup] Lucky store initialized for user: $userId");
  } else {
    debugPrint("[AppStartup] User not authenticated. Skipping Lucky store initialization.");
  }

  debugPrint("[AppStartup] Initialization complete.");

});

