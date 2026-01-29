import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart'; // kIsWeb
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
import 'package:video_compress/video_compress.dart';

import '../services/media/video_processor.dart';
import '../services/compression/image_compression_service.dart';

// ===========================================================================
// 1. 管道核心定义
// ===========================================================================

class PipelineContext {
  final ChatUiModel initialMsg;
  String? currentAbsolutePath;
  String? thumbAssetId; // 可能是 AssetID (Mobile) 或 Blob URL (Web)
  String? remoteUrl;
  String? remoteThumbUrl;
  Map<String, dynamic> metadata = {};

  PipelineContext(this.initialMsg) {
    if (initialMsg.meta != null) metadata.addAll(initialMsg.meta!);
    remoteThumbUrl = initialMsg.meta?['remote_thumb'];

    // 初始化时就接住原始路径 (Blob URL)
    currentAbsolutePath = initialMsg.localPath;
  }
}

abstract class PipelineStep {
  Future<void> execute(PipelineContext ctx, ChatActionService service);
}

// ===========================================================================
// 2. ChatActionService：业务调度中心
// ===========================================================================

class ChatActionService {
  final String conversationId;
  final dynamic _ref;
  final GlobalUploadService _uploadService;

  static final Map<String, String> _sessionPathCache = {};

  static String? getPathFromCache(String msgId) => _sessionPathCache[msgId];

  ChatActionService(this.conversationId, this._ref, this._uploadService);

  Future<void> _runPipeline(
      PipelineContext ctx,
      List<PipelineStep> steps,
      ) async {
    try {
      await LocalDatabaseService().saveMessage(ctx.initialMsg);
      _updateConversationSnapshot(
        ctx.initialMsg.content,
        ctx.initialMsg.createdAt,
      );

      for (final step in steps) {
        await step.execute(ctx, this);
      }
      debugPrint("✅ Pipeline Success: ${ctx.initialMsg.id}");
    } catch (e) {
      debugPrint("❌ Pipeline Crashed: $e");
      await LocalDatabaseService().updateMessageStatus(
        ctx.initialMsg.id,
        MessageStatus.pending,
      );
      OfflineQueueManager().startFlush();
    }
  }

  // ===========================================================================
  // 发送入口
  // ===========================================================================

  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;
    final msg = _createBaseMessage(content: text, type: MessageType.text);
    await _runPipeline(PipelineContext(msg), [SyncStep()]);
  }

  Future<void> sendImage(XFile file) async {
    final msg = _createBaseMessage(
      content: "[Image]",
      type: MessageType.image,
      localPath: file.path,
    );
    _sessionPathCache[msg.id] = file.path;

    await _runPipeline(PipelineContext(msg), [
      PersistStep(),
      ImageProcessStep(),
      UploadStep(),
      SyncStep(),
    ]);
  }

  Future<void> sendVoiceMessage(String path, int duration) async {
    final msg = _createBaseMessage(
      content: "[Voice]",
      type: MessageType.audio,
      localPath: path,
      duration: duration,
      meta: {'duration': duration},
    );
    await _runPipeline(PipelineContext(msg), [
      PersistStep(),
      UploadStep(),
      SyncStep(),
    ]);
  }

  Future<void> sendVideo(XFile file) async {
    Uint8List? quickPreview;
    try {
      quickPreview = await VideoCompress.getByteThumbnail(
        file.path,
        quality: 20,
      );
    } catch (e) {
      debugPrint("Pre-process preview failed: $e");
    }

    final msg = _createBaseMessage(
      content: "[Video]",
      type: MessageType.video,
      localPath: file.path,
      previewBytes: quickPreview,
    );
    _sessionPathCache[msg.id] = file.path;

    await _runPipeline(PipelineContext(msg), [
      PersistStep(),
      VideoProcessStep(),
      UploadStep(),
      SyncStep(),
    ]);
  }

  Future<void> resend(String msgId) async {
    final target = await LocalDatabaseService().getMessageById(msgId);
    if (target == null) return;

    final msg = target.copyWith(
      status: MessageStatus.sending,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await LocalDatabaseService().updateMessageStatus(
      msgId,
      MessageStatus.sending,
    );

    await _runPipeline(PipelineContext(msg), [
      RecoverStep(),
      UploadStep(),
      SyncStep(),
    ]);
  }

  // ... 辅助方法保持不变 ...
  ChatUiModel _createBaseMessage({
    required String content,
    required MessageType type,
    String? localPath,
    Map<String, dynamic>? meta,
    int? duration,
    Uint8List? previewBytes,
  }) {
    return ChatUiModel(
      id: const Uuid().v4(),
      conversationId: conversationId,
      content: content,
      type: type,
      isMe: true,
      status: MessageStatus.sending,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      localPath: localPath,
      meta: meta,
      duration: duration,
      previewBytes: previewBytes,
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
}

// ===========================================================================
// 3. 原子步骤实现
// ===========================================================================

class PersistStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, ChatActionService service) async {
    if (kIsWeb) {
      ctx.currentAbsolutePath = ctx.initialMsg.localPath;
      return;
    }

    final assetId = await AssetManager.save(
      XFile(ctx.initialMsg.localPath!),
      ctx.initialMsg.type,
    );

    final String? resolved = await AssetManager.getFullPath(
      assetId,
      ctx.initialMsg.type,
    );

    if (resolved != null) {
      ctx.currentAbsolutePath = resolved;
    }

    await LocalDatabaseService().updateMessage(ctx.initialMsg.id, {
      'localPath': assetId,
    });
  }
}

class RecoverStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, ChatActionService service) async {
    final assetId = ctx.initialMsg.localPath;
    if (assetId != null && !assetId.startsWith('http')) {
      ctx.currentAbsolutePath = await AssetManager.getFullPath(
        assetId,
        ctx.initialMsg.type,
      );

      if (!kIsWeb) {
        if (ctx.currentAbsolutePath == null ||
            !File(ctx.currentAbsolutePath!).existsSync()) {
          final fileName = assetId.split('/').last;
          ctx.currentAbsolutePath = await AssetManager.getFullPath(
            fileName,
            ctx.initialMsg.type,
          );
        }
      }
    }

    final thumbId = ctx.initialMsg.meta?['thumb'];
    if (thumbId != null && !thumbId.toString().startsWith('http')) {
      ctx.thumbAssetId = thumbId.toString();
    }
  }
}

class VideoProcessStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, ChatActionService service) async {
    if (kIsWeb) {
      // Web端：从 previewBytes 恢复封面上传逻辑
      if (ctx.initialMsg.previewBytes != null && ctx.initialMsg.previewBytes!.isNotEmpty) {
        final xFile = XFile.fromData(
            ctx.initialMsg.previewBytes!,
            name: 'video_thumb.jpg',
            mimeType: 'image/jpeg'
        );
        ctx.thumbAssetId = xFile.path;

        if (ctx.metadata['w'] == null) {
          try {
            final codec = await ui.instantiateImageCodec(ctx.initialMsg.previewBytes!);
            final frame = await codec.getNextFrame();
            ctx.metadata.addAll({
              'w': frame.image.width,
              'h': frame.image.height
            });
          } catch (_) {}
        }
      }
      return;
    }

    // Mobile 端
    final result = await VideoProcessor.process(
      XFile(ctx.currentAbsolutePath!),
    );
    if (result == null) throw "Compression Failed";

    ctx.currentAbsolutePath = result.videoFile.path;
    ctx.thumbAssetId = await AssetManager.save(
      XFile(result.thumbnailFile.path),
      MessageType.image,
    );
    ctx.metadata.addAll({
      'w': result.width,
      'h': result.height,
      'duration': result.duration,
      'thumb': ctx.thumbAssetId,
    });

    await LocalDatabaseService().updateMessage(ctx.initialMsg.id, {
      'meta': ctx.metadata,
    });
  }
}

class ImageProcessStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, ChatActionService service) async {
    final path = ctx.currentAbsolutePath ?? ctx.initialMsg.localPath;
    if (path == null) return;

    try {
      final bytes = await XFile(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      ctx.metadata.addAll({'w': frame.image.width, 'h': frame.image.height});

      final preview = await ImageCompressionService.getTinyThumbnail(XFile(path));

      await LocalDatabaseService().updateMessage(ctx.initialMsg.id, {
        'meta': ctx.metadata,
        'previewBytes': preview,
      });
    } catch (e) {
      debugPrint("⚠️ [ImageProcessStep] 预览生成失败: $e");
    }
  }
}

class UploadStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, ChatActionService service) async {
    // 1. 封面上传
    //  修复点1：允许 uploads/ 开头的相对路径，不要只认 http
    bool hasRemoteThumb = ctx.remoteThumbUrl != null &&
        (ctx.remoteThumbUrl!.startsWith('http') || ctx.remoteThumbUrl!.startsWith('uploads/'));

    if (!hasRemoteThumb) {
      if (ctx.thumbAssetId != null) {
        String? path;

        if (kIsWeb && (ctx.thumbAssetId!.startsWith('blob:') || ctx.thumbAssetId!.length > 200)) {
          path = ctx.thumbAssetId;
        } else {
          path = await AssetManager.getFullPath(
            ctx.thumbAssetId!,
            MessageType.image,
          );
        }

        bool canUploadThumb = kIsWeb
            ? (path != null)
            : (path != null && File(path).existsSync());

        if (canUploadThumb) {
          debugPrint("🚀 [UploadStep] 上传视频封面: $path");
          ctx.remoteThumbUrl = await service._uploadService.uploadFile(
            file: XFile(path!),
            module: UploadModule.chat,
            onProgress: (_) {},
          );
        }
      }
    }

    // 2. 附件主体上传
    //  修复点2：同理，主体也放开
    bool hasRemoteContent = ctx.initialMsg.content.startsWith('http') || ctx.initialMsg.content.startsWith('uploads/');

    if (!hasRemoteContent) {
      final String? uploadPath = ctx.currentAbsolutePath ?? ctx.initialMsg.localPath;

      bool canUploadMain = kIsWeb
          ? (uploadPath != null && uploadPath.isNotEmpty)
          : (uploadPath != null && File(uploadPath).existsSync());

      if (canUploadMain) {
        debugPrint("🚀 [UploadStep] 启动真实上传: $uploadPath");
        ctx.remoteUrl = await service._uploadService.uploadFile(
          file: XFile(uploadPath!),
          module: UploadModule.chat,
          onProgress: (_) {},
        );
        debugPrint("✅ [UploadStep] 上传成功 Key: ${ctx.remoteUrl}");
      }
    } else {
      ctx.remoteUrl = ctx.initialMsg.content;
    }
  }
}

class SyncStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, ChatActionService service) async {
    if (ctx.initialMsg.type == MessageType.image || ctx.initialMsg.type == MessageType.video) {
      if (ctx.remoteUrl == null || ctx.remoteUrl!.isEmpty || ctx.remoteUrl == '[Image]') {
        throw "【同步中止】上传未完成。";
      }
    }

    final Map<String, dynamic> apiMeta = Map.from(ctx.metadata);

    //  修复点3：彻底放开 thumb 校验
    // 只要有值（无论是 http 还是 uploads/），就认定为有效 URL
    String finalThumbUrl = "";
    if (ctx.remoteThumbUrl != null && ctx.remoteThumbUrl!.isNotEmpty) {
      finalThumbUrl = ctx.remoteThumbUrl!;
    } else if (ctx.metadata['remote_thumb'] != null && ctx.metadata['remote_thumb'].isNotEmpty) {
      finalThumbUrl = ctx.metadata['remote_thumb'];
    }

    // 确保把上传好的封面 URL 塞进 meta
    apiMeta['thumb'] = finalThumbUrl;
    apiMeta['remote_thumb'] = finalThumbUrl; // 双保险

    debugPrint("🌐 [SyncStep] API Request thumb: ${apiMeta['thumb']}");

    final serverMsg = await Api.sendMessage(
      id: ctx.initialMsg.id,
      conversationId: service.conversationId,
      content: ctx.remoteUrl!,
      type: ctx.initialMsg.type.value,
      meta: apiMeta,
    );

    final Map<String, dynamic> dbMeta = Map.from(ctx.metadata);
    if (serverMsg.meta != null && serverMsg.meta!['thumb'] != null) {
      dbMeta['remote_thumb'] = serverMsg.meta!['thumb'];
    }

    await LocalDatabaseService().updateMessage(ctx.initialMsg.id, {
      'status': MessageStatus.success.name,
      'content': serverMsg.content,
      'meta': dbMeta,
    });
  }
}