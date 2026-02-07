import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import 'package:flutter_app/ui/chat/services/chat_action_service.dart';

class OfflineQueueManager with WidgetsBindingObserver {
  static final OfflineQueueManager _instance = OfflineQueueManager._internal();
  factory OfflineQueueManager() => _instance;
  OfflineQueueManager._internal();

  bool _isProcessing = false;
  StreamSubscription? _connectivitySubscription;

  // 改用 ProviderContainer 以匹配 GlobalHandler
  ProviderContainer? _container;

  final Map<String, int> _retryRegistry = {};
  static const int maxRetries = 5;

  // 1. 参数改为 ProviderContainer
  void init(ProviderContainer container) {
    _container = container;
    debugPrint("🔌 [OfflineQueue] Manager initialized.");

    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (result != ConnectivityResult.none) {
        debugPrint("🔌 [OfflineQueue] Network restored, triggering flush...");
        startFlush();
      }
    });

    WidgetsBinding.instance.addObserver(this);
    startFlush();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      startFlush();
    }
  }

  Future<void> startFlush() async {
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      await _doFlush();
    } catch (e) {
      debugPrint("🔌 [OfflineQueue] Flush error: $e");
    } finally {
      _isProcessing = false;
    }
  }

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
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) break;

      final retries = _retryRegistry[msg.id] ?? 0;
      if (retries >= maxRetries) {
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

      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<bool> _resendViaPipeline(ChatUiModel msg) async {
    if (_container == null) return false;

    try {
      debugPrint("🔌 [OfflineQueue] Resending: ${msg.id}");
      // 2. 使用 container.read
      final service = _container!.read(chatActionServiceProvider(msg.conversationId));
      await service.resend(msg.id);
      return true;
    } catch (e) {
      debugPrint("🔌 [OfflineQueue] Pipeline failed: $e");
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