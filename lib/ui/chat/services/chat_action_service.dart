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
import 'blurHash/blur_hash_service.dart';

// ===========================================================================
// 1. 管道核心定义
// ===========================================================================

class PipelineContext {
  final ChatUiModel initialMsg;
  String? currentAbsolutePath;
  String? thumbAssetId;
  String? remoteUrl;
  String? remoteThumbUrl;
  Map<String, dynamic> metadata = {};

  //  核心修复 A：增加 sourceFile 字段
  // 专门用于在 Web 端传递原始的 XFile，防止文件名和后缀丢失
  XFile? sourceFile;

  PipelineContext(this.initialMsg) {
    if (initialMsg.meta != null) metadata.addAll(initialMsg.meta!);
    remoteThumbUrl = initialMsg.meta?['remote_thumb'];
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
  final Ref _ref;
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
      debugPrint("Pipeline Success: ${ctx.initialMsg.id}");
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

    //  核心修复 B：初始化 Context 时把 sourceFile 塞进去
    final ctx = PipelineContext(msg);
    ctx.sourceFile = file;

    await _runPipeline(ctx, [
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
    // 语音通常是录音文件，路径是确定的，一般不需要 sourceFile
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

    //  核心修复 B：初始化 Context 时把 sourceFile 塞进去
    final ctx = PipelineContext(msg);
    ctx.sourceFile = file;

    await _runPipeline(ctx, [
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

    // 重发时没有 sourceFile，只能依赖 UploadStep 里的兜底逻辑
    await _runPipeline(PipelineContext(msg), [
      RecoverStep(),
      UploadStep(),
      SyncStep(),
    ]);
  }

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
// 3. 原子步骤实现 (严格对齐 w, h 协议)
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
      if (ctx.initialMsg.previewBytes != null && ctx.initialMsg.previewBytes!.isNotEmpty) {
        final xFile = XFile.fromData(
            ctx.initialMsg.previewBytes!,
            name: 'video_thumb_${const Uuid().v4()}.jpg',
            mimeType: 'image/jpeg'
        );
        ctx.thumbAssetId = xFile.path;

        if (ctx.metadata['w'] == null) {
          try {
            final codec = await ui.instantiateImageCodec(ctx.initialMsg.previewBytes!);
            final frame = await codec.getNextFrame();
            //  Web 端对齐 w, h
            ctx.metadata.addAll({
              'w': frame.image.width,
              'h': frame.image.height
            });
            //  计算 Web 端视频封面 BlurHash
            ctx.metadata['blurHash'] = await BlurHashService.create(ctx.initialMsg.previewBytes!);
          } catch (_) {}
        }
      }
      return;
    }

    // Mobile 端
    final result = await VideoProcessor.process(XFile(ctx.currentAbsolutePath!));
    if (result == null) throw "Compression Failed";

    final File thumbFile = result.thumbnailFile;
    final Uint8List thumbBytes = await thumbFile.readAsBytes();

    //  核心补强：计算视频封面视觉指纹
    final String coverHash = await BlurHashService.create(thumbBytes);

    ctx.currentAbsolutePath = result.videoFile.path;
    ctx.thumbAssetId = await AssetManager.save(XFile(thumbFile.path), MessageType.image);

    //  严格对齐 w, h 字段
    ctx.metadata.addAll({
      'w': result.width,
      'h': result.height,
      'duration': result.duration,
      'thumb': ctx.thumbAssetId,
      'blurHash': coverHash,
    });

    await LocalDatabaseService().updateMessage(ctx.initialMsg.id, {
      'meta': ctx.metadata,
      'previewBytes': thumbBytes,
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

      //  严格对齐 w, h
      ctx.metadata.addAll({'w': frame.image.width, 'h': frame.image.height});

      //  并行执行：缩略图生成 + BlurHash 计算
      final List<dynamic> results = await Future.wait([
        ImageCompressionService.getTinyThumbnail(XFile(path)),
        BlurHashService.create(bytes),
      ]);

      final Uint8List? preview = results[0];
      ctx.metadata['blurHash'] = results[1];

      await LocalDatabaseService().updateMessage(ctx.initialMsg.id, {
        'meta': ctx.metadata,
        'previewBytes': preview, //  使用并行结果，移除冗余调用
      });
    } catch (e) {
      debugPrint(" [ImageProcessStep] 处理失败: $e");
    }
  }
}

class UploadStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, ChatActionService service) async {
    // 1. 封面上传
    bool hasRemoteThumb = ctx.remoteThumbUrl != null &&
        (ctx.remoteThumbUrl!.startsWith('http') || ctx.remoteThumbUrl!.startsWith('uploads/'));

    if (!hasRemoteThumb) {
      if (ctx.thumbAssetId != null) {
        String? path;
        if (kIsWeb && (ctx.thumbAssetId!.startsWith('blob:') || ctx.thumbAssetId!.length > 200)) {
          path = ctx.thumbAssetId;
        } else {
          path = await AssetManager.getFullPath(ctx.thumbAssetId!, MessageType.image);
        }

        if (path != null && (kIsWeb || File(path).existsSync())) {
          XFile thumbFile = XFile(path);
          if (kIsWeb && (thumbFile.name.isEmpty || !thumbFile.name.contains('.'))) {
            thumbFile = XFile(path, name: 'thumb_${const Uuid().v4()}.jpg');
          }
          ctx.remoteThumbUrl = await service._uploadService.uploadFile(
            file: thumbFile,
            module: UploadModule.chat,
            onProgress: (_) {},
          );
        }
      }
    }

    // 2. 主文件上传
    bool hasRemoteContent = ctx.initialMsg.content.startsWith('http') || ctx.initialMsg.content.startsWith('uploads/');
    if (!hasRemoteContent) {
      final String? uploadPath = ctx.currentAbsolutePath ?? ctx.initialMsg.localPath;
      if (uploadPath != null && (kIsWeb || File(uploadPath).existsSync())) {
        XFile fileToUpload;
        if (kIsWeb && ctx.sourceFile != null && uploadPath == ctx.sourceFile!.path) {
          fileToUpload = ctx.sourceFile!;
        } else {
          fileToUpload = XFile(uploadPath);
          if (kIsWeb && (fileToUpload.name.isEmpty || !fileToUpload.name.contains('.'))) {
            final ext = ctx.initialMsg.type == MessageType.video ? 'mp4' : 'jpg';
            fileToUpload = XFile(uploadPath, name: 'upload_${const Uuid().v4()}.$ext');
          }
        }
        ctx.remoteUrl = await service._uploadService.uploadFile(
          file: fileToUpload,
          module: UploadModule.chat,
          onProgress: (_) {},
        );
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
      if (ctx.remoteUrl == null || ctx.remoteUrl!.isEmpty) throw "【同步中止】上传未完成";
    }

    //  严格按照后端 DTO 构建 meta 命名空间
    final Map<String, dynamic> apiMeta = {
      'blurHash': ctx.metadata['blurHash'],
      'w': ctx.metadata['w'],
      'h': ctx.metadata['h'],
      'duration': ctx.metadata['duration'],
      'thumb': ctx.remoteThumbUrl ?? ctx.metadata['remote_thumb'] ?? "",
    };

    final serverMsg = await Api.sendMessage(
      id: ctx.initialMsg.id,
      conversationId: service.conversationId,
      content: ctx.remoteUrl ?? ctx.initialMsg.content,
      type: ctx.initialMsg.type.value,
      meta: apiMeta,
    );

    //  数据回写：合并后端权威数据 (如 seqId) 并清理本地 meta
    final Map<String, dynamic> dbMeta = {
      ...ctx.metadata,
      ...serverMsg.meta ?? {},
      'remote_thumb': serverMsg.meta?['thumb'] ?? ctx.remoteThumbUrl,
    };

    await LocalDatabaseService().updateMessage(ctx.initialMsg.id, {
      'status': MessageStatus.success.name,
      'content': serverMsg.content,
      'meta': dbMeta,
    });
  }
}

// ===========================================================================
// 4. Provider 定义
// ===========================================================================

final chatActionServiceProvider = Provider.family.autoDispose<ChatActionService, String>(
      (ref, conversationId) {
    return ChatActionService(
      conversationId,
      ref,
      GlobalUploadService(),
    );
  },
);