import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import 'package:flutter_app/ui/chat/services/chat_action_service.dart';
import 'package:flutter_app/utils/upload/global_upload_service.dart';

class OfflineQueueManager with WidgetsBindingObserver {
  static final OfflineQueueManager _instance = OfflineQueueManager._internal();
  factory OfflineQueueManager() => _instance;
  OfflineQueueManager._internal();

  bool _isProcessing = false;
  StreamSubscription? _connectivitySubscription;
  late dynamic _ref; //  这里改为 dynamic

  final GlobalUploadService _uploadService = GlobalUploadService();
  final Map<String, int> _retryRegistry = {};
  static const int maxRetries = 5;

  /// 初始化并监听网络
  void init(dynamic ref) {
    _ref = ref;
    debugPrint("[OfflineQueue] Manager initialized.");

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (result != ConnectivityResult.none) {
        debugPrint("[OfflineQueue] 网络恢复，开始清理队列...");
        startFlush();
      }
    });

    WidgetsBinding.instance.addObserver(this);
    startFlush();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("[OfflineQueue] App 回到前台，检查未完成任务.");
      startFlush();
    }
  }

  /// 触发清理
  Future<void> startFlush() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      await _doFlush();
    } finally {
      _isProcessing = false;
    }
  }

  /// 循环重发所有 Pending 消息
  Future<void> _doFlush() async {
    final pendingMessages = await LocalDatabaseService().getPendingMessages();
    if (pendingMessages.isEmpty) return;

    debugPrint("[OfflineQueue] 准备重发 ${pendingMessages.length} 条消息.");

    for (var msg in pendingMessages) {
      // 实时检查网络
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        debugPrint("[OfflineQueue] 清理中断：网络连接丢失.");
        break;
      }

      // 检查重试次数
      final retries = _retryRegistry[msg.id] ?? 0;
      if (retries >= maxRetries) {
        debugPrint("[OfflineQueue] 消息 ${msg.id} 达到最大重试次数，标记失败.");
        await LocalDatabaseService().updateMessageStatus(msg.id, MessageStatus.failed);
        _retryRegistry.remove(msg.id);
        continue;
      }

      //  核心调用：收编“游击队”，统一走管道
      bool success = await _resendViaPipeline(msg);

      if (!success) {
        _retryRegistry[msg.id] = retries + 1;
      } else {
        _retryRegistry.remove(msg.id);
      }

      // 避免请求过快
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// 内部方法：通过 Pipeline 重新发送
  Future<bool> _resendViaPipeline(ChatUiModel msg) async {
    try {
      debugPrint("[OfflineQueue] 正在通过管道重发消息: ${msg.id}");

      // 构造 Service 实例
      final service = ChatActionService(msg.conversationId, _ref, _uploadService);

      // 调用我们在 ChatActionService 里写好的重发管道
      // 它会自动执行：RecoverStep -> UploadStep -> SyncStep
      await service.resend(msg.id);

      return true;
    } catch (e) {
      debugPrint("[OfflineQueue] 管道重发失败 ${msg.id}: $e");
      return false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _retryRegistry.clear();
    WidgetsBinding.instance.removeObserver(this);
  }
}