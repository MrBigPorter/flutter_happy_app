import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import 'package:flutter_app/ui/chat/services/chat_action_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OfflineQueueManager with WidgetsBindingObserver {
  static final OfflineQueueManager _instance = OfflineQueueManager._internal();
  factory OfflineQueueManager() => _instance;
  OfflineQueueManager._internal();

  bool _isProcessing = false;
  StreamSubscription? _connectivitySubscription;

  //  修复 1：将 Ref 改为 ProviderContainer
  // 因为 main.dart 里使用的是 container，而不是 ref
  WidgetRef? _container;

  final Map<String, int> _retryRegistry = {};
  static const int maxRetries = 5;

  /// 初始化并监听网络
  ///  修复 2：参数类型改为 ProviderContainer
  void init(WidgetRef container) {
    _container = container;
    debugPrint(" [OfflineQueue] Manager initialized.");

    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (result != ConnectivityResult.none) {
        debugPrint(" [OfflineQueue] Network restored, triggering flush...");
        startFlush();
      }
    });

    WidgetsBinding.instance.addObserver(this);
    startFlush();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("🔌 [OfflineQueue] App resumed, checking pending tasks.");
      startFlush();
    }
  }

  Future<void> startFlush() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      await _doFlush();
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _doFlush() async {
    //  修复 3：检查 _container 是否为空
    if (_container == null) return;

    List<ChatUiModel> pendingMessages = [];

    try {
      pendingMessages = await LocalDatabaseService().getPendingMessages();
    } catch (e) {
      debugPrint(" [OfflineQueue] Database not ready yet. Skipping flush.");
      return;
    }

    if (pendingMessages.isEmpty) return;

    debugPrint(" [OfflineQueue] Found ${pendingMessages.length} pending messages to resend.");

    for (var msg in pendingMessages) {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        debugPrint("🔌 [OfflineQueue] Flush interrupted: Network lost.");
        break;
      }

      final retries = _retryRegistry[msg.id] ?? 0;
      if (retries >= maxRetries) {
        debugPrint(" [OfflineQueue] Message ${msg.id} max retries reached. Marking as failed.");
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
      debugPrint(" [OfflineQueue] Resending via pipeline: ${msg.id}");

      //  修复 4：使用 _container!.read()
      // ProviderContainer 也有 read 方法，用法和 Ref 一样
      final service = _container!.read(chatActionServiceProvider(msg.conversationId));

      await service.resend(msg.id);

      return true;
    } catch (e) {
      debugPrint(" [OfflineQueue] Pipeline failed for ${msg.id}: $e");
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