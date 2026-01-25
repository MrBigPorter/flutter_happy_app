import 'dart:async';
import 'dart:io' show File;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_app/core/api/lucky_api.dart';
import 'package:flutter_app/utils/upload/global_upload_service.dart';
import 'package:flutter_app/utils/upload/upload_types.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';


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

      if (msg.type != MessageType.text) {
        bool canUpload = false;
        // 用于存储动态拼接后的完整路径
        String? fullPath; // 用于存储动态拼接后的完整路径

        if (kIsWeb) {
          canUpload = msg.content.startsWith('http') || (msg.localPath != null);
        } else {
          //核心修复：动态获取当前的 Documents 目录，并拼接文件名
          if(msg.localPath != null) {
            final appDir = await getApplicationDocumentsDirectory();

            //根据类型分流目录
            String subDir = 'chat_images';
            if (msg.type == MessageType.audio) {
              subDir = 'chat_audio';
            }
            // 假设你存入的是文件名，这里拼成完整路径
            fullPath = p.join(appDir.path, subDir, msg.localPath!);
            canUpload = File(fullPath).existsSync();
          }
        }

        // 如果本地没找到文件且也不是 URL，说明真的丢了
        if (!canUpload && !msg.content.startsWith('http')) {
          debugPrint("[OfflineQueue] File not found for ${msg.id}. Marking failed.");
          await LocalDatabaseService().updateMessageStatus(msg.id, MessageStatus.failed);
          return false;
        }

        if (!msg.content.startsWith('http')) {
          debugPrint("[OfflineQueue] Uploading resource for ${msg.id}...");
          contentToSend = await _uploadService.uploadFile(
            //核心修复：使用动态生成的 fullPath
            file: XFile(
                fullPath ?? "",
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

      debugPrint("[OfflineQueue] Executing API send for: ${msg.id}");
      final serverMsg = await Api.sendMessage(
        msg.id,
        msg.conversationId,
        contentToSend,
        msg.type.value,
        width: width,
        height: height,
        duration: duration,
      );

      await LocalDatabaseService().updateMessage(msg.id, {
        'status': MessageStatus.success.name,
        'seqId': serverMsg.seqId,
        'createdAt': serverMsg.createdAt,
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