import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:cross_file/cross_file.dart';

import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/services/network/offline_queue_manager.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_app/utils/asset/asset_manager.dart';
import 'package:flutter_app/utils/upload/global_upload_service.dart';
import 'package:flutter_app/utils/upload/upload_types.dart';
import 'package:flutter_app/core/api/lucky_api.dart';

import '../services/media/video_processor.dart';
import '../services/compression/image_compression_service.dart';

class ChatActionService {
  final String conversationId;
  final Ref _ref;
  final GlobalUploadService _uploadService;

  // 缓存本地路径，防止 UI 闪烁
  static final Map<String, String> _sessionPathCache = {};
  static String? getPathFromCache(String msgId) => _sessionPathCache[msgId];

  ChatActionService(this.conversationId, this._ref, this._uploadService);

  // ===========================================================================
  //  核心管道 (Pipeline)
  // ===========================================================================

  Future<void> _sendPipeline({
    required ChatUiModel msg,
    required Future<String> Function() getContentTask,
    Map<String, dynamic>? extraMeta,
  }) async {
    try {
      // 1. 本地乐观保存 & 更新会话列表
      await LocalDatabaseService().saveMessage(msg);
      _updateConversationSnapshot(msg.content, msg.createdAt);

      // 2. 执行耗时任务 (上传/压缩)
      final finalContent = await getContentTask();

      // 3. 组装 Meta (合并基础 meta 和额外 meta)
      final Map<String, dynamic> combinedMeta = <String, dynamic>{
        if (msg.meta != null) ...msg.meta!,
        if (extraMeta != null) ...extraMeta,
      };

      // 4. API 发送
      final serverMsg = await Api.sendMessage(
        id: msg.id,
        conversationId: conversationId,
        content: finalContent,
        type: msg.type.value,
        meta: combinedMeta.isEmpty ? null : combinedMeta,
      );

      // 5. 更新成功状态
      await LocalDatabaseService().updateMessage(msg.id, {
        'status': MessageStatus.success.name,
        'seqId': serverMsg.seqId,
        'createdAt': _timeToInt(serverMsg.createdAt),
        if (serverMsg.meta != null) 'meta': serverMsg.meta,
        if (msg.type != MessageType.text) 'content': serverMsg.content,
      });
    } catch (e) {
      debugPrint("Send Pipeline Error: $e");
      await LocalDatabaseService().updateMessageStatus(msg.id, MessageStatus.pending);
      // 触发离线队列
      OfflineQueueManager().startFlush();
    }
  }

  // ===========================================================================
  //  发送方法
  // ===========================================================================

  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;
    final msg = _createBaseMessage(content: text, type: MessageType.text);
    await _sendPipeline(msg: msg, getContentTask: () async => text);
  }

  Future<void> sendImage(XFile file) async {
    final msgId = const Uuid().v4();
    // 并行处理：生成缩略图 + 保存文件 + 计算尺寸
    final results = await Future.wait([
      ImageCompressionService.getTinyThumbnail(file),
      AssetManager.save(file, MessageType.image),
      _calculateImageSize(file),
    ]);

    final fileName = results[1] as String;
    final meta = results[2] as Map<String, dynamic>;

    _cacheLocalPath(msgId, fileName, MessageType.image);

    final msg = _createBaseMessage(
      id: msgId,
      content: "[Image]",
      type: MessageType.image,
      localPath: fileName,
      previewBytes: results[0] as Uint8List,
      meta: meta,
    );

    await _sendPipeline(
      msg: msg,
      getContentTask: () => _uploadAttachment(fileName, MessageType.image, fallbackPath: file.path),
    );
  }

  Future<void> sendVoiceMessage(String path, int duration) async {
    final msgId = const Uuid().v4();
    final fileName = await AssetManager.save(XFile(path), MessageType.audio);

    _cacheLocalPath(msgId, fileName, MessageType.audio);

    final msg = _createBaseMessage(
      id: msgId,
      content: "[Voice]",
      type: MessageType.audio,
      localPath: fileName,
      duration: duration,
      meta: {'duration': duration},
    );

    await _sendPipeline(
      msg: msg,
      getContentTask: () => _uploadAttachment(fileName, MessageType.audio, fallbackPath: path),
    );
  }

  Future<void> sendVideo(XFile file) async {
    final msgId = const Uuid().v4();
    final result = await VideoProcessor.process(file);
    if (result == null) return; // 处理失败

    final videoName = await AssetManager.save(result.videoFile, MessageType.video);
    final thumbName = await AssetManager.save(XFile(result.thumbnailFile.path), MessageType.image);

    _cacheLocalPath(msgId, videoName, MessageType.video);

    final Map<String, dynamic> videoMeta = {
      'thumb': thumbName,
      'w': result.width,
      'h': result.height,
      'duration': result.duration,
    };

    final msg = _createBaseMessage(
      id: msgId,
      content: "[Video]",
      type: MessageType.video,
      localPath: videoName,
      meta: videoMeta,
    );

    await _sendPipeline(
      msg: msg,
      getContentTask: () async {
        // 双重上传：先封面，后视频
        final thumbUrl = await _uploadService.uploadFile(
          file: XFile(result.thumbnailFile.path),
          module: UploadModule.chat,
          onProgress: (double p1) {  },
        );
        videoMeta['thumb'] = thumbUrl; // 更新 meta 为网络地址
        return await _uploadAttachment(videoName, MessageType.video);
      },
      extraMeta: videoMeta,
    );
    VideoProcessor.clearCache();
  }

  Future<void> resend(String msgId) async {
    final target = await LocalDatabaseService().getMessageById(msgId);
    if (target == null) return;

    final msg = target.copyWith(
      status: MessageStatus.sending,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _sendPipeline(
      msg: msg,
      getContentTask: () async {
        if (msg.type == MessageType.text) return msg.content;
        // 如果还不是 HTTP 链接，说明还没传完
        if (!msg.content.startsWith('http')) {
          return await _uploadAttachment(msg.localPath, msg.type);
        }
        return msg.content;
      },
    );
  }

  // ===========================================================================
  //  辅助方法
  // ===========================================================================

  ChatUiModel _createBaseMessage({
    String? id,
    required String content,
    required MessageType type,
    String? localPath,
    Uint8List? previewBytes,
    Map<String, dynamic>? meta,
    int? duration,
  }) {
    return ChatUiModel(
      id: id ?? const Uuid().v4(),
      conversationId: conversationId,
      content: content,
      type: type,
      isMe: true,
      status: MessageStatus.sending,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      localPath: localPath,
      previewBytes: previewBytes,
      meta: meta,
      duration: duration,
    );
  }

  Future<void> _cacheLocalPath(String msgId, String fileName, MessageType type) async {
    final absPath = await AssetManager.getFullPath(fileName, type);
    if (absPath != null) _sessionPathCache[msgId] = absPath;
  }

  Future<String> _uploadAttachment(String? localName, MessageType type, {String? fallbackPath}) async {
    if (localName == null && fallbackPath == null) return "";
    final fullPath = await AssetManager.getFullPath(localName, type);
    final uploadPath = fullPath ?? fallbackPath;
    if (uploadPath == null) throw Exception("Local file not found");

    return await _uploadService.uploadFile(
      file: XFile(uploadPath),
      module: UploadModule.chat, onProgress: (double p1) {  },
    );
  }

  void _updateConversationSnapshot(String content, int time) {
    try {
      _ref.read(conversationListProvider.notifier).updateLocalItem(
        conversationId: conversationId,
        lastMsgContent: content,
        lastMsgTime: time,
      );
    } catch (_) {}
  }

  int _timeToInt(dynamic value) {
    if (value is int) return value;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    return DateTime.now().millisecondsSinceEpoch;
  }

  Future<Map<String, dynamic>> _calculateImageSize(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      return {'w': frameInfo.image.width, 'h': frameInfo.image.height};
    } catch (_) {
      return {};
    }
  }
}