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

import '../services/media/video_processor.dart';
import '../services/compression/image_compression_service.dart';

// ===========================================================================
//  1. 声明式管道核心定义 (The Pipeline Engine)
// ===========================================================================

/// 管道上下文：在加工步骤之间传递的数据托盘
class PipelineContext {
  final ChatUiModel initialMsg;
  String? currentAbsolutePath;  // 内存中的物理路径 (用于加工/上传)
  String? thumbAssetId;         // 本地缩略图 ID
  String? remoteUrl;            // 网络 URL
  String? remoteThumbUrl;       // 缩略图 URL
  Map<String, dynamic> metadata = {}; // 宽高、时长等

  PipelineContext(this.initialMsg) {
    if (initialMsg.meta != null) metadata.addAll(initialMsg.meta!);
  }
}

/// 管道原子步骤接口
abstract class PipelineStep {
  Future<void> execute(PipelineContext ctx, ChatActionService service);
}

// ===========================================================================
//  2. ChatActionService 实现
// ===========================================================================

class ChatActionService {
  final String conversationId;
  final Ref _ref;
  final GlobalUploadService _uploadService;

  // 内存缓存：用于秒开刚发送的文件，不入库
  static final Map<String, String> _sessionPathCache = {};
  static String? getPathFromCache(String msgId) => _sessionPathCache[msgId];

  ChatActionService(this.conversationId, this._ref, this._uploadService);

  /// 核心流水线调度器
  Future<void> _runPipeline(PipelineContext ctx, List<PipelineStep> steps) async {
    try {
      // Step 0: 初始乐观落库 (UI 瞬间显示)
      await LocalDatabaseService().saveMessage(ctx.initialMsg);
      _updateConversationSnapshot(ctx.initialMsg.content, ctx.initialMsg.createdAt);

      // Step 1: 依次执行声明的步骤
      for (final step in steps) {
        await step.execute(ctx, this);
      }
      debugPrint("✅ 消息管道流程执行成功: ${ctx.initialMsg.id}");
    } catch (e) {
      debugPrint("❌ 消息管道流程崩溃: $e");
      // 失败则标记 Pending，触发离线队列
      await LocalDatabaseService().updateMessageStatus(ctx.initialMsg.id, MessageStatus.pending);
      OfflineQueueManager().startFlush();
    }
  }

  // ===========================================================================
  //  发送方法 (声明式声明)
  // ===========================================================================

  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;
    final msg = _createBaseMessage(content: text, type: MessageType.text);
    await _runPipeline(PipelineContext(msg), [SyncStep()]);
  }

  Future<void> sendImage(XFile file) async {
    final msg = _createBaseMessage(content: "[Image]", type: MessageType.image, localPath: file.path);
    await _runPipeline(PipelineContext(msg), [
      PersistStep(),      // 落地永久化
      ImageProcessStep(), // 压缩并提尺寸
      UploadStep(),       // 上传
      SyncStep(),         // API同步
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
    final msg = _createBaseMessage(content: "[Video]", type: MessageType.video, localPath: file.path);
    _sessionPathCache[msg.id] = file.path; // 放入缓存以便秒开

    await _runPipeline(PipelineContext(msg), [
      PersistStep(),      // 1. 落地原视频
      VideoProcessStep(), // 2. 压缩提取封面
      UploadStep(),       // 3. 上传
      SyncStep(),         // 4. 同步
    ]);
  }

  Future<void> resend(String msgId) async {
    final target = await LocalDatabaseService().getMessageById(msgId);
    if (target == null) return;

    final msg = target.copyWith(
      status: MessageStatus.sending,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await LocalDatabaseService().updateMessageStatus(msgId, MessageStatus.sending);

    await _runPipeline(PipelineContext(msg), [
      RecoverStep(), // 尝试从本地 ID 恢复绝对路径
      UploadStep(),  // 补传
      SyncStep(),    // 同步
    ]);
  }

  // ===========================================================================
  //  辅助方法
  // ===========================================================================

  ChatUiModel _createBaseMessage({
    String? id,
    required String content,
    required MessageType type,
    String? localPath,
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
      meta: meta,
      duration: duration,
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
}

// ===========================================================================
//  3. 原子步骤实现 (The Steps)
// ===========================================================================

/// 落地步：解决临时路径过期/离线丢失
class PersistStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, ChatActionService service) async {
    final String tempPath = ctx.initialMsg.localPath!;
    // 强制存入永久目录，拿到 AssetID (相对路径)
    final String assetId = await AssetManager.save(XFile(tempPath), ctx.initialMsg.type);

    // 更新上下文中的绝对路径
    ctx.currentAbsolutePath = await AssetManager.getFullPath(assetId, ctx.initialMsg.type);

    // 数据库记下相对 ID
    await LocalDatabaseService().updateMessage(ctx.initialMsg.id, {'localPath': assetId});
  }
}

/// 恢复步：离线重发时，从相对 ID 找回物理文件
class RecoverStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, ChatActionService service) async {
    final assetId = ctx.initialMsg.localPath;
    if (assetId == null || assetId.startsWith('http')) return;

    String? absPath = await AssetManager.getFullPath(assetId, ctx.initialMsg.type);

    // 抢救逻辑
    if (absPath == null || !File(absPath).existsSync()) {
      if (assetId.contains('/')) {
        final fileName = assetId.split('/').last;
        absPath = await AssetManager.getFullPath(fileName, ctx.initialMsg.type);
      }
    }

    if (absPath == null || !File(absPath).existsSync()) throw Exception("File Lost");
    ctx.currentAbsolutePath = absPath;
  }
}

/// 视频加工步
class VideoProcessStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, ChatActionService service) async {
    if (ctx.currentAbsolutePath == null) return;

    final result = await VideoProcessor.process(XFile(ctx.currentAbsolutePath!));
    if (result == null) throw Exception("Compression Failed");

    ctx.currentAbsolutePath = result.videoFile.path;
    // 封面也持久化为 AssetID
    ctx.thumbAssetId = await AssetManager.save(XFile(result.thumbnailFile.path), MessageType.image);

    ctx.metadata.addAll({
      'w': result.width,
      'h': result.height,
      'duration': result.duration,
      'thumb': ctx.thumbAssetId, // 数据库存相对 ID
    });

    await LocalDatabaseService().updateMessage(ctx.initialMsg.id, {'meta': ctx.metadata});
  }
}

/// 图片加工步
class ImageProcessStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, ChatActionService service) async {
    if (ctx.currentAbsolutePath == null) return;
    final file = XFile(ctx.currentAbsolutePath!);

    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    ctx.metadata.addAll({'w': frame.image.width, 'h': frame.image.height});
    final preview = await ImageCompressionService.getTinyThumbnail(file);

    await LocalDatabaseService().updateMessage(ctx.initialMsg.id, {
      'meta': ctx.metadata,
      'previewBytes': preview,
    });
  }
}

/// 上传步
class UploadStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, ChatActionService service) async {
    // 补传封面
    if (ctx.thumbAssetId != null && ctx.remoteThumbUrl == null) {
      final thumbPath = await AssetManager.getFullPath(ctx.thumbAssetId!, MessageType.image);
      if (thumbPath != null && File(thumbPath).existsSync()) {
        ctx.remoteThumbUrl = await service._uploadService.uploadFile(
            file: XFile(thumbPath), module: UploadModule.chat, onProgress: (_) {}
        );
      }
    }

    // 上传主体
    if (ctx.initialMsg.content.startsWith('http')) {
      ctx.remoteUrl = ctx.initialMsg.content;
    } else if (ctx.currentAbsolutePath != null) {
      ctx.remoteUrl = await service._uploadService.uploadFile(
          file: XFile(ctx.currentAbsolutePath!), module: UploadModule.chat, onProgress: (_) {}
      );
    }
  }
}

/// 同步步：解决对方收到本地路径 & UI闪烁的核心
class SyncStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, ChatActionService service) async {
    // A. 净化发送 Meta：绝不发本地路径给服务器
    final Map<String, dynamic> apiMeta = Map.from(ctx.metadata);
    apiMeta['thumb'] = ctx.remoteThumbUrl ?? "";

    // B. 发送 API
    final serverMsg = await Api.sendMessage(
      id: ctx.initialMsg.id,
      conversationId: service.conversationId,
      content: ctx.remoteUrl ?? ctx.initialMsg.content,
      type: ctx.initialMsg.type.value,
      meta: apiMeta.isEmpty ? null : apiMeta,
    );

    // C. [防闪烁] 回写本地：thumb 保持为 AssetID，URL 存入 remote_thumb
    final Map<String, dynamic> dbMeta = Map.from(ctx.metadata);
    if (serverMsg.meta != null && serverMsg.meta!['thumb'] != null) {
      dbMeta['remote_thumb'] = serverMsg.meta!['thumb'];
    }

    await LocalDatabaseService().updateMessage(ctx.initialMsg.id, {
      'status': MessageStatus.success.name,
      'content': serverMsg.content,
      'meta': dbMeta, // 这里的 thumb 字段没变，UI 就不会切换重绘
    });
  }
}