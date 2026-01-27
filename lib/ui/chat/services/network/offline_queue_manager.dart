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

  final GlobalUploadService _uploadService = GlobalUploadService();
  final Map<String, int> _retryRegistry = {};
  static const int maxRetries = 5;

  /// Initializes the manager and starts monitoring network connectivity.
  void init() {
    debugPrint("[OfflineQueue] Manager initialized.");

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (result != ConnectivityResult.none) {
        debugPrint("[OfflineQueue] Network restored. Flushing queue...");
        startFlush();
      }
    });

    WidgetsBinding.instance.addObserver(this);
    startFlush();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("[OfflineQueue] App resumed. Checking for pending tasks.");
      startFlush();
    }
  }

  /// Entry point to trigger the queue processing.
  Future<void> startFlush() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      await _doFlush();
    } finally {
      _isProcessing = false;
    }
  }

  /// Loops through all messages currently marked as 'pending' in the local database.
  Future<void> _doFlush() async {
    final pendingMessages = await LocalDatabaseService().getPendingMessages();
    if (pendingMessages.isEmpty) return;

    debugPrint("[OfflineQueue] Resending ${pendingMessages.length} items.");

    for (var msg in pendingMessages) {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        debugPrint("[OfflineQueue] Flush aborted: Connection lost.");
        break;
      }

      final retries = _retryRegistry[msg.id] ?? 0;
      if (retries >= maxRetries) {
        debugPrint("[OfflineQueue] Max retries hit for ${msg.id}. Failing permanently.");
        await LocalDatabaseService().updateMessageStatus(msg.id, MessageStatus.failed);
        _retryRegistry.remove(msg.id);
        continue;
      }

      bool success = await _resend(msg);
      if (!success) {
        _retryRegistry[msg.id] = retries + 1;
      } else {
        _retryRegistry.remove(msg.id);
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Handles the actual re-upload and API re-submission for a single message.
  Future<bool> _resend(ChatUiModel msg) async {
    try {
      await LocalDatabaseService().updateMessageStatus(msg.id, MessageStatus.sending);

      String contentToSend = msg.content;

      // --- Media Handling Logic ---
      if (msg.type != MessageType.text) {
        String? fullPath;

        // Use AssetManager to resolve the physical path for the media file.
        if (msg.localPath != null) {
          fullPath = await AssetManager.getFullPath(msg.localPath, msg.type);
        }

        bool canUpload = (fullPath != null);

        // If the file is missing locally and we don't have a server URL, we cannot proceed.
        if (!canUpload && !msg.content.startsWith('http')) {
          debugPrint("❌ [OfflineQueue] File lost, cannot resend ID: ${msg.id}");
          await LocalDatabaseService().updateMessageStatus(msg.id, MessageStatus.failed);
          return false;
        }

        // Re-upload the file if the content field doesn't contain a valid URL yet.
        if (!msg.content.startsWith('http')) {
          debugPrint("[OfflineQueue] Re-uploading media for ${msg.id}...");

          contentToSend = await _uploadService.uploadFile(
            file: XFile(
              fullPath!,
              mimeType: msg.type == MessageType.audio ? 'audio/mp4' : null,
            ),
            module: UploadModule.chat,
            onProgress: (p) => debugPrint("[OfflineQueue] Upload Progress: $p"),
          );
        }
      }

      // --- API Synchronization ---
      debugPrint("[OfflineQueue] Syncing with server: ${msg.id}");

      // Use the new named parameter signature.
      final serverMsg = await Api.sendMessage(
        id: msg.id,
        conversationId: msg.conversationId,
        content: contentToSend,
        type: msg.type.value,
        meta: msg.meta, // Pass the consolidated meta map.
      );

      // Update local database with server confirmation data.
      await LocalDatabaseService().updateMessage(msg.id, {
        'status': MessageStatus.success.name,
        'seqId': serverMsg.seqId,
        'createdAt': timeToInt(serverMsg.createdAt),
        if (serverMsg.meta != null) 'meta': serverMsg.meta,
        if (msg.type != MessageType.text) 'content': contentToSend,
      });

      return true;

    } catch (e) {
      debugPrint("[OfflineQueue] Error resending ${msg.id}: $e");
      await LocalDatabaseService().updateMessageStatus(msg.id, MessageStatus.pending);
      return false;
    }
  }

  /// Helper to ensure timestamp consistency.
  int timeToInt(dynamic value) {
    if (value is int) return value;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    if (value is String) return DateTime.parse(value).millisecondsSinceEpoch;
    return DateTime.now().millisecondsSinceEpoch;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _retryRegistry.clear();
    WidgetsBinding.instance.removeObserver(this);
  }
}