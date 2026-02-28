import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import 'package:flutter_app/ui/chat/services/chat_action_service.dart';

class OfflineQueueManager with WidgetsBindingObserver {
  // Singleton Pattern
  static final OfflineQueueManager _instance = OfflineQueueManager._internal();
  factory OfflineQueueManager() => _instance;
  OfflineQueueManager._internal();

  bool _isProcessing = false;
  StreamSubscription? _connectivitySubscription;

  /// Global container for accessing providers outside of the widget tree
  ProviderContainer? _container;

  /// Tracks retry counts for specific message IDs to prevent infinite loops
  final Map<String, int> _retryRegistry = {};
  static const int maxRetries = 5;

  /// Initializes the manager with a ProviderContainer for dependency injection.
  void init(ProviderContainer container) {
    _container = container;
    debugPrint("[OfflineQueue] Manager initialized.");

    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    // Monitor network status changes to trigger an automatic queue flush
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (result != ConnectivityResult.none) {
        debugPrint("[OfflineQueue] Network restored; triggering automatic flush...");
        startFlush();
      }
    });

    WidgetsBinding.instance.addObserver(this);
    startFlush();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Automatically attempt to flush the queue when the app returns to the foreground
    if (state == AppLifecycleState.resumed) {
      startFlush();
    }
  }

  /// Entry point for processing the pending message queue.
  Future<void> startFlush() async {
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      await _doFlush();
    } catch (e) {
      debugPrint("[OfflineQueue] Flush error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  /// Internal logic for iterating through and resending pending messages.
  Future<void> _doFlush() async {
    if (_container == null) return;

    List<ChatUiModel> pendingMessages = [];
    try {
      pendingMessages = await LocalDatabaseService().getPendingMessages();
    } catch (e) {
      return;
    }

    if (pendingMessages.isEmpty) return;

    for (var msg in pendingMessages) {
      // Immediate network check before each resend attempt
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) break;

      final retries = _retryRegistry[msg.id] ?? 0;
      if (retries >= maxRetries) {
        // Mark message as permanently failed after exceeding maximum retries
        await LocalDatabaseService().updateMessageStatus(msg.id, MessageStatus.failed);
        _retryRegistry.remove(msg.id);
        continue;
      }

      bool success = await _resendViaPipeline(msg);

      if (!success) {
        _retryRegistry[msg.id] = retries + 1;
      } else {
        _retryRegistry.remove(msg.id);
      }

      // Throttle resend attempts to avoid server thundering herd issues
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Dispatches the resend operation through the existing ChatActionService pipeline.
  Future<bool> _resendViaPipeline(ChatUiModel msg) async {
    if (_container == null) return false;

    try {
      debugPrint("[OfflineQueue] Attempting resend for message: ${msg.id}");
      final service = _container!.read(chatActionServiceProvider(msg.conversationId));
      await service.resend(msg.id);
      return true;
    } catch (e) {
      debugPrint("[OfflineQueue] Pipeline resend failed: $e");
      return false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _retryRegistry.clear();
    WidgetsBinding.instance.removeObserver(this);
    _container = null;
  }
}