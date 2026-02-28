import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_compress/video_compress.dart';

import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_app/ui/chat/services/network/offline_queue_manager.dart';
import 'package:flutter_app/utils/upload/global_upload_service.dart';
import 'package:flutter_app/utils/upload/upload_types.dart';

import '../../../core/api/lucky_api.dart';
import '../../../utils/asset/web/web_blob_url.dart';
import '../providers/chat_view_model.dart';
import '../repository/message_repository.dart';
import '../../../utils/media/url_resolver.dart';
import '../pipeline/pipeline_types.dart';
import '../pipeline/pipeline_steps.dart';
import 'blurHash/blur_hash_service.dart';
import 'chat_message_factory.dart';
import 'compression/image_compression_service.dart';
import 'media/web_video_thumbnail_service.dart';

class ChatActionService {
  final String conversationId;
  final Ref _ref;
  final GlobalUploadService _uploadService;

  ChatActionService(this.conversationId, this._ref, this._uploadService);

  MessageRepository get repo => _ref.read(messageRepositoryProvider);

  /// Static session cache to maintain local file paths for the duration of the app session
  static final Map<String, String> _sessionPathCache = {};

  static String? getPathFromCache(String msgId) {
    if (_sessionPathCache.containsKey(msgId)) return _sessionPathCache[msgId];
    return null;
  }

  ChatMessageFactory get _msg => ChatMessageFactory(conversationId: conversationId);

  Future<String> uploadChatFile(XFile file) {
    return _uploadService.uploadFile(
      file: file,
      module: UploadModule.chat,
      onProgress: (_) {},
    );
  }

  // ===========================================================================
  // Core Pipeline Executor
  // ===========================================================================

  /// Orchestrates the execution of multiple processing steps for a message.
  Future<void> _runPipeline(PipelineContext ctx, List<PipelineStep> steps) async {
    try {
      // 1. Initial persistence: Store local path and preview bytes immediately to avoid UI flicker
      await repo.saveOrUpdate(ctx.initialMsg);

      // 2. Update conversation list snapshot
      _updateConversationSnapshot(
        ctx.initialMsg.content,
        ctx.initialMsg.createdAt,
      );

      // 3. Sequential execution of pipeline steps
      for (final step in steps) {
        await step.execute(ctx, this);
      }
      debugPrint("Pipeline Success: ${ctx.initialMsg.id}");
    } catch (e, st) {
      debugPrint("Pipeline Crashed: $e");
      final failedMsg = ctx.initialMsg.copyWith(status: MessageStatus.failed);
      await repo.saveOrUpdate(failedMsg);

      final errStr = e.toString();
      // Halt retries for fatal integrity errors
      if (errStr.contains("Fatal") ||
          errStr.contains("File missing") ||
          errStr.contains("Sync aborted")) {
        return;
      }
      // Trigger offline queue for transient network failures
      OfflineQueueManager().startFlush();
    }
  }

  // ===========================================================================
  // Message Transmission Entries
  // ===========================================================================

  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;
    final msg = _msg.text(text);
    await _runPipeline(PipelineContext(msg), [SyncStep()]);
  }

  Future<void> sendImage(XFile file) async {
    final XFile processedFile = await ImageCompressionService.compressForUpload(file);
    Uint8List? quickPreview;
    try {
      quickPreview = await ImageCompressionService.getTinyThumbnail(processedFile);
    } catch (e) {
      debugPrint("Preview generation failed: $e");
    }

    final msg = _msg.image(
      localPath: processedFile.path,
      previewBytes: quickPreview,
      meta: {
        'fileExt': processedFile.name.split('.').last,
        'fileName': processedFile.name,
      },
    );

    _sessionPathCache[msg.id] = processedFile.path;

    // Immediate save to prevent UI lag
    await repo.saveOrUpdate(msg);

    final ctx = PipelineContext(msg)..sourceFile = processedFile;
    await _runPipeline(ctx, [PersistStep(), ImageProcessStep(), UploadStep(), SyncStep()]);
  }

  Future<void> sendVideo(XFile file) async {
    XFile fileToUse = file;

    // Web Platform Implementation: Enforce Blob URL generation
    if (kIsWeb) {
      bool invalidPath = file.path.isEmpty || !file.path.startsWith('blob:');
      if (invalidPath) {
        try {
          final bytes = await file.readAsBytes();
          final blobUrl = WebBlobUrl.fromBytes(bytes, mime: 'video/mp4');
          fileToUse = XFile(blobUrl, name: file.name, bytes: bytes);
        } catch (e) {
          debugPrint("Web video blob generation failed: $e");
        }
      }
    }

    Uint8List? quickPreview;
    String? blurHash;
    int? w;
    int? h;
    XFile? webThumbFile;

    // Enhanced Thumbnail Generation Logic
    if (kIsWeb) {
      try {
        final videoBytes = await fileToUse.readAsBytes();
        final thumbJpeg = await WebVideoThumbnailService.extractJpegThumb(
          videoBytes,
          atSeconds: 0.1,
          maxWidth: 320,
          quality: 0.85,
        );

        if (thumbJpeg != null && thumbJpeg.isNotEmpty) {
          quickPreview = thumbJpeg;
          webThumbFile = XFile.fromData(
            thumbJpeg,
            name: 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg',
            mimeType: 'image/jpeg',
          );
          // Calculate BlurHash for placeholder rendering
          final blur = await ThumbBlurHashService.build(thumbJpeg);
          if (blur != null) {
            blurHash = blur.blurHash;
            w = blur.thumbW;
            h = blur.thumbH;
          }
        }
      } catch (e) {
        debugPrint("Web video thumbnail generation failed: $e");
      }
    } else {
      // Mobile Implementation: Dual-layer thumbnail retrieval
      try {
        quickPreview = await VideoCompress.getByteThumbnail(fileToUse.path, quality: 30);

        if (quickPreview == null || quickPreview.isEmpty) {
          final File thumbFile = await VideoCompress.getFileThumbnail(fileToUse.path, quality: 30);
          if (await thumbFile.exists()) {
            quickPreview = await thumbFile.readAsBytes();
          }
        }
      } catch (e) {
        debugPrint("Video preview generation failed: $e");
      }
    }

    final msg = _msg.video(
      localPath: fileToUse.path,
      previewBytes: quickPreview,
      meta: {
        if (blurHash != null && blurHash.isNotEmpty) 'blurHash': blurHash,
        if (w != null) 'w': w,
        if (h != null) 'h': h,
      },
    );

    _sessionPathCache[msg.id] = fileToUse.path;

    await repo.saveOrUpdate(msg);

    final ctx = PipelineContext(msg)
      ..sourceFile = fileToUse
      ..webThumbFile = webThumbFile;

    ctx.metadata.addAll(msg.meta ?? {});

    await _runPipeline(ctx, [
      PersistStep(),
      VideoProcessStep(),
      UploadStep(),
      SyncStep(),
    ]);
  }

  Future<void> sendFile([PlatformFile? pFile]) async {
    try {
      PlatformFile? fileToUse = pFile;

      if (fileToUse == null) {
        final result = await FilePicker.platform.pickFiles(
          allowMultiple: false,
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'zip', 'rar', 'txt', 'apk'],
          withData: kIsWeb,
          withReadStream: !kIsWeb,
        );
        if (result == null || result.files.isEmpty) return;
        fileToUse = result.files.first;
      }

      final fileName = fileToUse.name;
      final fileSize = fileToUse.size;
      final fileExt = fileToUse.extension ?? (fileName.contains('.') ? fileName.split('.').last : 'bin');

      XFile xFile;
      if (kIsWeb) {
        if (fileToUse.bytes == null) return;
        final blobUrl = WebBlobUrl.fromBytes(fileToUse.bytes!);
        xFile = XFile(blobUrl, name: fileName, bytes: fileToUse.bytes!);
      } else {
        if (fileToUse.path == null) return;
        xFile = XFile(fileToUse.path!, name: fileName);
      }

      final msg = _msg.file(
        localPath: xFile.path,
        fileName: fileName,
        fileSize: fileSize,
        fileExt: fileExt,
      );

      if (msg.localPath != null) _sessionPathCache[msg.id] = msg.localPath!;

      await repo.saveOrUpdate(msg);

      final ctx = PipelineContext(msg)..sourceFile = xFile;
      await _runPipeline(ctx, [PersistStep(), UploadStep(), SyncStep()]);
    } catch (e, st) {
      debugPrint("Send file failed: $e\n$st");
    }
  }

  Future<void> sendVoiceMessage(String path, int duration) async {
    final msg = _msg.voice(localPath: path, duration: duration);
    await repo.saveOrUpdate(msg);
    await _runPipeline(PipelineContext(msg), [PersistStep(), UploadStep(), SyncStep()]);
  }

  Future<void> sendLocation({
    required double latitude,
    required double longitude,
    required String address,
    String? title,
  }) async {
    final staticMapUrl = UrlResolver.getStaticMapUrl(latitude, longitude);
    final msg = _msg.location(
      latitude: latitude,
      longitude: longitude,
      address: address,
      title: title,
      thumb: staticMapUrl,
    );
    await repo.saveOrUpdate(msg);
    await _runPipeline(PipelineContext(msg), [SyncStep()]);
  }

  /// Re-triggers the pipeline for a failed message
  Future<void> resend(String msgId) async {
    final target = await repo.get(msgId);
    if (target == null) return;
    final msg = target.copyWith(
      status: MessageStatus.sending,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await repo.saveOrUpdate(msg);
    await _runPipeline(PipelineContext(msg), [RecoverStep(), UploadStep(), SyncStep()]);
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

  /// Forwards an existing message to one or multiple target conversations.
  Future<void> forwardMessage(String originalMessageId, List<String> targetIds) async {
    try {
      await Api.messageForwardApi(
        originalMessageId: originalMessageId,
        targetConversationIds: targetIds,
      );

      // Invalidate specific view models if the current conversation is one of the targets
      if (targetIds.contains(conversationId)) {
        _ref.invalidate(chatViewModelProvider(conversationId));
      }
    } catch (e) {
      rethrow;
    }
  }
}

final chatActionServiceProvider = Provider.family.autoDispose<ChatActionService, String>((ref, conversationId) {
  return ChatActionService(conversationId, ref, GlobalUploadService());
});