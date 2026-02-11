import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/core/store/user_store.dart';
import 'package:flutter_app/ui/chat/pipeline/chat_pipeline_context.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_app/core/services/socket/socket_service.dart';

import '../../../core/pipeline/pipeline_runner.dart';
import '../../../core/providers/socket_provider.dart';
import '../pipeline/steps/parse_step.dart';
import '../pipeline/steps/persist_step.dart';

// Global Handler Provider
// This is a "Keep Alive" Provider; as long as it is being watched, it remains active.
final globalChatHandlerProvider = Provider<GlobalChatHandler>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  // Get the current logged-in user's ID
  final currentUserId = ref.watch(userProvider)?.id ?? "";

  // Return an empty Handler if not logged in
  if (currentUserId.isEmpty) return GlobalChatHandler.empty();

  return GlobalChatHandler(socketService, currentUserId, ref);
});

class GlobalChatHandler {
  final SocketService? _socketService;
  final String _currentUserId;
  final Ref? _ref;

  StreamSubscription? _msgSub;

  // Empty constructor (used when not logged in)
  GlobalChatHandler.empty() : _socketService = null, _currentUserId = "", _ref = null;

  GlobalChatHandler(this._socketService, this._currentUserId, this._ref) {
    _init();
  }

  void _init() {
    if (_socketService == null) return;

    debugPrint(" [GlobalHandler] Global message listener started...");

    // Listen to the Socket message stream
    _msgSub = _socketService!.chatMessageStream.listen((data) async {
      try {
        // 1. Prepare the box (Context)
        // Note: Using the ChatPipelineContext defined earlier
        final ctx = ChatPipelineContext(
          ref: _ref!,
          rawData: data,
          currentUserId: _currentUserId,
        );

        // 2. Execute the pipeline
        await PipelineRunner.run(ctx, [
          ParseStep(),   // Step 1: Parse + Filter
          PersistStep(), // Step 2: Persist to database
        ]);

      } catch (e) {
        debugPrint(" [GlobalHandler] Pipeline error: $e");
      }
    });
  }

  void dispose() {
    debugPrint(" [GlobalHandler] Stopping listener");
    _msgSub?.cancel();
  }
}