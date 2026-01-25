import 'dart:async';
import 'dart:io' show File;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:flutter_app/utils/helper.dart';

import 'package:flutter_app/core/api/lucky_api.dart';
import 'package:flutter_app/utils/upload/global_upload_service.dart';
import 'package:flutter_app/utils/upload/upload_types.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';

import '../../../../utils/asset/asset_manager.dart';


class OfflineQueueManager with WidgetsBindingObserver {
  static final OfflineQueueManager _instance = OfflineQueueManager._internal();
  factory OfflineQueueManager() => _instance;
  OfflineQueueManager._internal();

  bool _isProcessing = false;
  StreamSubscription? _connectivitySubscription;

  // Instance reuse
  final GlobalUploadService _uploadService = GlobalUploadService();

  final Map<String, int> _retryRegistry = {};
  static const int maxRetries = 5;

  void init() {
    debugPrint("[OfflineQueue] Manager initialized.");

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (result != ConnectivityResult.none) {
        debugPrint("[OfflineQueue] Network state changed to: $result. Flushing queue.");
        startFlush();
      }
    });

    WidgetsBinding.instance.addObserver(this);
    startFlush();
  }

  //  ADDED: Handle app resuming from background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("[OfflineQueue] App resumed. Checking for pending tasks.");
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
    final pendingMessages = await LocalDatabaseService().getPendingMessages();
    if (pendingMessages.isEmpty) {
      debugPrint("[OfflineQueue] No pending messages.");
      return;
    }

    debugPrint("[OfflineQueue] Resending ${pendingMessages.length} items.");

    for (var msg in pendingMessages) {
      // check connectivity before each attempt
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        debugPrint("[OfflineQueue] Aborting flush: Network lost.");
        break;
      }

      final retries = _retryRegistry[msg.id] ?? 0;
      if (retries >= maxRetries) {
        debugPrint("[OfflineQueue] Max retries reached for ${msg.id}. Marking failed.");
        await LocalDatabaseService().updateMessageStatus(msg.id, MessageStatus.failed);
        _retryRegistry.remove(msg.id);
        continue;
      }

      // Attempt resend
      bool success = await _resend(msg);

      if (!success) {
        _retryRegistry[msg.id] = retries + 1;
        debugPrint("[OfflineQueue] Task failed for ${msg.id}. Count: ${_retryRegistry[msg.id]}");
      } else {
        _retryRegistry.remove(msg.id);
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<bool> _resend(ChatUiModel msg) async {
    try {
      await LocalDatabaseService().updateMessageStatus(msg.id, MessageStatus.sending);

      String contentToSend = msg.content;
      int? width, height, duration = msg.duration;

      // ==========================================
      //  核心修改开始：使用 AssetManager 接管路径查找
      // ==========================================
      if (msg.type != MessageType.text) {
        String? fullPath;

        // 1. 直接问管家要路径 (管家内部处理了 Web/App、Audio/Image、路径清洗等所有逻辑)
        if (msg.localPath != null) {
          fullPath = await AssetManager.getFullPath(msg.localPath, msg.type);
        }

        // 2. 判断是否可以上传 (全路径不为空)
        bool canUpload = (fullPath != null);

        // 3. 兜底判断：如果本地找不到文件，且 content 也不是网络链接，说明彻底丢了
        if (!canUpload && !msg.content.startsWith('http')) {
          debugPrint("❌ [OfflineQueue] 文件丢失，无法重发 ID: ${msg.id}");
          await LocalDatabaseService().updateMessageStatus(msg.id, MessageStatus.failed);
          return false;
        }

        // 4. 执行上传
        if (!msg.content.startsWith('http')) {
          // 注意：如果 fullPath 为 null 但 content 是 http，这段代码不会执行，逻辑是安全的
          // 如果走到这里 fullPath 一定不是 null (因为上面的 check)
          debugPrint("[OfflineQueue] Uploading resource for ${msg.id}...");

          contentToSend = await _uploadService.uploadFile(
            file: XFile(
              fullPath!, // 这里肯定是安全的非空值
              mimeType: msg.type == MessageType.audio ? 'audio/mp4' : null,
            ),
            module: UploadModule.chat,
            onProgress: (p) => debugPrint("[OfflineQueue] Progress: $p"),
          );
        }

        if (msg.meta != null) {
          width = (msg.meta!['w'] as num?)?.toInt();
          height = (msg.meta!['h'] as num?)?.toInt();
        }
      }
      // ==========================================
      //  核心修改结束
      // ==========================================

      debugPrint("[OfflineQueue] Executing API send for: ${msg.id}");
      // ... 下面的代码保持不变 ...
      final serverMsg = await Api.sendMessage(
        msg.id,
        msg.conversationId,
        contentToSend,
        msg.type.value,
        width: width,
        height: height,
        duration: duration,
      );

      // ... 保存数据库逻辑保持不变 ...
      await LocalDatabaseService().updateMessage(msg.id, {
        'status': MessageStatus.success.name,
        'seqId': serverMsg.seqId,
        'createdAt': timeToInt(serverMsg.createdAt),
        if (serverMsg.meta != null) 'meta': serverMsg.meta,
        if (msg.type != MessageType.text) 'content': contentToSend,
      });

      debugPrint("[OfflineQueue] Sync completed for ${msg.id}.");
      return true;

    } catch (e) {
      debugPrint("[OfflineQueue] Error for ${msg.id}: $e");
      await LocalDatabaseService().updateMessageStatus(msg.id, MessageStatus.pending);
      return false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _retryRegistry.clear();
    WidgetsBinding.instance.removeObserver(this);
  }
}