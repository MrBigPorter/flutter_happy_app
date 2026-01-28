import 'dart:async';
import 'dart:io';
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
import 'package:video_compress/video_compress.dart';

import '../services/media/video_processor.dart';
import '../services/compression/image_compression_service.dart';

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

  PipelineContext(this.initialMsg) {
    if (initialMsg.meta != null) metadata.addAll(initialMsg.meta!);
    // 初始尝试从 meta 中找 remote_thumb
    remoteThumbUrl = initialMsg.meta?['remote_thumb'];
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
  final dynamic _ref; //  这里从 Ref 改为 dynamic，兼容 Ref 和 ProviderContainer
  final GlobalUploadService _uploadService;

  static final Map<String, String> _sessionPathCache = {};
  static String? getPathFromCache(String msgId) => _sessionPathCache[msgId];

  ChatActionService(this.conversationId, this._ref, this._uploadService);

  Future<void> _runPipeline(PipelineContext ctx, List<PipelineStep> steps) async {
    try {
      await LocalDatabaseService().saveMessage(ctx.initialMsg);
      _updateConversationSnapshot(ctx.initialMsg.content, ctx.initialMsg.createdAt);

      for (final step in steps) {
        await step.execute(ctx, this);
      }
      debugPrint("✅ Pipeline Success: ${ctx.initialMsg.id}");
    } catch (e) {
      debugPrint("❌ Pipeline Crashed: $e");
      await LocalDatabaseService().updateMessageStatus(ctx.initialMsg.id, MessageStatus.pending);
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
    final msg = _createBaseMessage(content: "[Image]", type: MessageType.image, localPath: file.path);
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
    await _runPipeline(PipelineContext(msg), [PersistStep(), UploadStep(), SyncStep()]);
  }

  Future<void> sendVideo(XFile file) async {
    final msg = _createBaseMessage(content: "[Video]", type: MessageType.video, localPath: file.path);
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
    final msg = target.copyWith(status: MessageStatus.sending, createdAt: DateTime.now().millisecondsSinceEpoch);
    await LocalDatabaseService().updateMessageStatus(msgId, MessageStatus.sending);

    // 重发管道：必须先执行 Recover 找回物理路径和 ID
    await _runPipeline(PipelineContext(msg), [RecoverStep(), UploadStep(), SyncStep()]);
  }

  // ===========================================================================
  // 辅助方法
  // ===========================================================================

  ChatUiModel _createBaseMessage({required String content, required MessageType type, String? localPath, Map<String, dynamic>? meta, int? duration}) {
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
    );
  }

  void _updateConversationSnapshot(String content, int time) {
    try {
      _ref.read(conversationListProvider.notifier).updateLocalItem(
          conversationId: conversationId, lastMsgContent: content, lastMsgTime: time);
    } catch (_) {}
  }

  int _timeToInt(dynamic value) {
    if (value is int) return value;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    return DateTime.now().millisecondsSinceEpoch;
  }
}

// ===========================================================================
// 3. 原子步骤实现
// ===========================================================================

class PersistStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, ChatActionService service) async {
    final assetId = await AssetManager.save(XFile(ctx.initialMsg.localPath!), ctx.initialMsg.type);
    ctx.currentAbsolutePath = await AssetManager.getFullPath(assetId, ctx.initialMsg.type);
    await LocalDatabaseService().updateMessage(ctx.initialMsg.id, {'localPath': assetId});
  }
}

/// 🔥 修正版 RecoverStep：不仅找回视频路径，还要认出本地封面 ID
class RecoverStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, ChatActionService service) async {
    // 1. 恢复主体路径
    final assetId = ctx.initialMsg.localPath;
    if (assetId != null && !assetId.startsWith('http')) {
      ctx.currentAbsolutePath = await AssetManager.getFullPath(assetId, ctx.initialMsg.type);
      if (ctx.currentAbsolutePath == null || !File(ctx.currentAbsolutePath!).existsSync()) {
        // 抢救一下绝对路径
        final fileName = assetId.split('/').last;
        ctx.currentAbsolutePath = await AssetManager.getFullPath(fileName, ctx.initialMsg.type);
      }
    }

    // 2. 🔥 关键：识别本地封面 ID，否则 UploadStep 会跳过上传！
    final thumbId = ctx.initialMsg.meta?['thumb'];
    if (thumbId != null && !thumbId.toString().startsWith('http')) {
      ctx.thumbAssetId = thumbId.toString();
    }
  }
}

class VideoProcessStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, ChatActionService service) async {
    final result = await VideoProcessor.process(XFile(ctx.currentAbsolutePath!));
    if (result == null) throw "Compression Failed";
    ctx.currentAbsolutePath = result.videoFile.path;
    ctx.thumbAssetId = await AssetManager.save(XFile(result.thumbnailFile.path), MessageType.image);
    ctx.metadata.addAll({'w': result.width, 'h': result.height, 'duration': result.duration, 'thumb': ctx.thumbAssetId});
    await LocalDatabaseService().updateMessage(ctx.initialMsg.id, {'meta': ctx.metadata});
  }
}

class ImageProcessStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, ChatActionService service) async {
    final path = ctx.currentAbsolutePath ?? ctx.initialMsg.localPath!;
    final bytes = await XFile(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    ctx.metadata.addAll({'w': frame.image.width, 'h': frame.image.height});
    final preview = await ImageCompressionService.getTinyThumbnail(XFile(path));
    await LocalDatabaseService().updateMessage(ctx.initialMsg.id, {'meta': ctx.metadata, 'previewBytes': preview});
  }
}

/// 🔥 修正版 UploadStep
class UploadStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, ChatActionService service) async {
    // 1. 检查封面是否需要上传
    // 如果已经有远程 URL 了，跳过；否则如果有本地 ID，就传
    if (ctx.remoteThumbUrl == null || !ctx.remoteThumbUrl!.startsWith('http')) {
      if (ctx.thumbAssetId != null) {
        final path = await AssetManager.getFullPath(ctx.thumbAssetId!, MessageType.image);
        if (path != null && File(path).existsSync()) {
          debugPrint("🌐 [上传] 正在上传补齐小图: ${ctx.thumbAssetId}");
          ctx.remoteThumbUrl = await service._uploadService.uploadFile(file: XFile(path), module: UploadModule.chat, onProgress: (_) {});
        }
      }
    }

    // 2. 检查附件主体
    if (!ctx.initialMsg.content.startsWith('http')) {
      if (ctx.currentAbsolutePath != null && File(ctx.currentAbsolutePath!).existsSync()) {
        ctx.remoteUrl = await service._uploadService.uploadFile(file: XFile(ctx.currentAbsolutePath!), module: UploadModule.chat, onProgress: (_) {});
      } else {
        // 极端兜底：如果没绝对路径也没 content URL，重试时可能会报错。这里取决于 resend 时的 Recover 状态。
      }
    } else {
      ctx.remoteUrl = ctx.initialMsg.content;
    }
  }
}

/// 🔥 修正版 SyncStep
class SyncStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, ChatActionService service) async {
    // 1. 彻底净化发送 Meta：绝不基于 msg.meta 盲目合并
    final Map<String, dynamic> apiMeta = Map.from(ctx.metadata);

    // 2. 强制性 URL 校验
    String finalThumbUrl = "";
    if (ctx.remoteThumbUrl != null && ctx.remoteThumbUrl!.startsWith('http')) {
      finalThumbUrl = ctx.remoteThumbUrl!;
    } else if (ctx.metadata['remote_thumb'] != null && ctx.metadata['remote_thumb'].startsWith('http')) {
      finalThumbUrl = ctx.metadata['remote_thumb'];
    }

    // 覆盖本地 ID：如果没拿到 URL，发出去的必须是空，绝不能是 .jpg ID
    apiMeta['thumb'] = finalThumbUrl;

    debugPrint("🌐 [同步] API Request thumb: ${apiMeta['thumb']}");

    final serverMsg = await Api.sendMessage(
      id: ctx.initialMsg.id,
      conversationId: service.conversationId,
      content: ctx.remoteUrl ?? ctx.initialMsg.content,
      type: ctx.initialMsg.type.value,
      meta: apiMeta,
    );

    // 3. 回写本地：thumb 还是 ID，remote_thumb 记下 URL
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