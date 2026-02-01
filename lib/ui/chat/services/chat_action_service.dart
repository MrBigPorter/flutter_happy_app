import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
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

import '../../../utils/upload/image_utils.dart';
import '../services/media/video_processor.dart';
import 'blurHash/blur_hash_service.dart';
import 'compression/image_compression_service.dart';

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
      debugPrint(" Pipeline Crashed: $e");
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
    // 1.  前置压缩：解决上传慢、流量大的问题
    // (Web 端会走 Canvas 加速，不卡顿；App 端走 Native，飞快)
    final XFile processedFile = await ImageCompressionService.compressForUpload(file);

    // 2.  秒出预览图：解决消息上屏白屏的问题
    // (因为是对 150KB 的小图做处理，耗时 <10ms，几乎无感)
    Uint8List? quickPreview;
    try {
      quickPreview = await ImageCompressionService.getTinyThumbnail(processedFile);
    } catch (e) {
      debugPrint(" 预览图生成失败: $e");
    }

    // 3. 创建消息 (直接带上 previewBytes，UI 渲染时直接显示，无需等待)
    final msg = _createBaseMessage(
      content: "[Image]",
      type: MessageType.image,
      localPath: processedFile.path,
      previewBytes: quickPreview,
    );

    _sessionPathCache[msg.id] = processedFile.path;

    // 4. 初始化 Pipeline
    final ctx = PipelineContext(msg);
    //  核心逻辑：必须把【处理后的文件】传给 Pipeline，否则 Web 端会传原图！
    ctx.sourceFile = processedFile;

    // 5. 执行管道
    await _runPipeline(ctx, [
      PersistStep(),
      ImageProcessStep(), // 这里的 BlurHash 计算现在是锦上添花，因为 previewBytes 已经有了
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

  Future<void> sendFile() async {
    try{
      // 1. 唤起系统文件选择器
      ///核心修复：Web 端强制使用 FileType.any，防止 MIME Type 识别失败导致不弹窗
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        // Web端：为了兼容性，允许所有类型 (any)
        // Native端：为了体验，只允许特定后缀 (custom)
        type: kIsWeb ? FileType.any : FileType.custom,
        // Native端才传后缀列表，Web端传了可能会导致不弹窗
        allowedExtensions: kIsWeb ? null : [
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
          'zip', 'rar', 'txt', 'apk'
        ],
        withData: kIsWeb,// Web 端必须读入内存
        withReadStream: !kIsWeb,// App 端可以用流式读取优化
      );

      if (result == null || result.files.isEmpty) return; // 用户取消选择

      final PlatformFile pFile = result.files.first;

      // 2. 兼容性处理：构建 XFile (Web 拿 blob, App 拿 path)
      XFile xFile;
      if(kIsWeb){
        // Web 端用内存字节流构建 XFile
        if(pFile.bytes == null) return;
        xFile = XFile.fromData(pFile.bytes!,name: pFile.name);
      }else{
        if(pFile.path == null) return;
        xFile = XFile(pFile.path!,name: pFile.name);
      }

      // 5. 元数据解析
      final String fileName = pFile.name;
      final int fileSize = pFile.size; // 字节大小
      // 优先用 pick 出来的后缀，如果没有则从文件名解析
      final String fileExt = pFile.extension ??
          (fileName.contains('.') ? fileName.split('.').last : 'bin');

      // 6. 创建消息模型
      final msg = _createBaseMessage(
        content: "[File]",
        type: MessageType.file,
        localPath: xFile.path,
        meta: {
          'fileName': fileName,
          'fileSize': fileSize,
          'fileExt': fileExt,
        },
      );

    // 5. Cache (UI 零抖动)
    // 此时 fullPath 就是 xFile.path，UI 会先读这个临时路径显示
    if (msg.localPath != null) {
    _sessionPathCache[msg.id] = msg.localPath!;
    }

      // 7. 初始化管道上下文
      final ctx = PipelineContext(msg);
      ctx.sourceFile = xFile; // 传递原始 XFile 以保留文件名等信息

      // 8. 执行管道 (文件不需要压缩/处理，直接上传 + 同步)
      await _runPipeline(ctx, [
        PersistStep(),
        UploadStep(),
        SyncStep(),
      ]);

    }catch(e){
      debugPrint(" Send file failed: $e");
    }
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
    // 1. Web 端逻辑：直接从预热的 previewBytes 恢复
    if (kIsWeb) {
      final bytes = ctx.initialMsg.previewBytes;
      if (bytes != null && bytes.isNotEmpty) {
        final result = await ThumbBlurHashService.build(bytes);
        if (result != null) {
          ctx.metadata.addAll({'w': result.thumbW, 'h': result.thumbH, 'blurHash': result.blurHash});
          await LocalDatabaseService().updateMessage(ctx.initialMsg.id, {'meta': ctx.metadata});
        }
      }
      return;
    }

    // 2. Mobile 端逻辑：压缩 + 封面指纹化
    final result = await VideoProcessor.process(XFile(ctx.currentAbsolutePath!));
    if (result == null) throw "Video Compression Failed";

    final thumbBytes = await File(result.thumbnailFile.path).readAsBytes();

    //  关键：给视频封面也跑一遍图片服务，获取微缩图和 BlurHash
    final thumbResult = await ThumbBlurHashService.build(thumbBytes);

    ctx.currentAbsolutePath = result.videoFile.path;
    ctx.thumbAssetId = await AssetManager.save(XFile(result.thumbnailFile.path), MessageType.image);

    ctx.metadata.addAll({
      'w': result.width,
      'h': result.height,
      'duration': result.duration,
      'thumb': ctx.thumbAssetId,
      'blurHash': thumbResult?.blurHash ?? "",
    });

    await LocalDatabaseService().updateMessage(ctx.initialMsg.id, {
      'meta': ctx.metadata,
      'previewBytes': thumbResult?.thumbBytes ?? thumbBytes,
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

      //  一站式服务：处理缩放、指纹、宽高
      final result = await ThumbBlurHashService.build(bytes);

      if (result != null) {
        ctx.metadata.addAll({
          'blurHash': result.blurHash,
          'w': result.thumbW,
          'h': result.thumbH,
        });

        // 写入本地 DB，UI 监听到 previewBytes 后会立刻显示微缩图
        await LocalDatabaseService().updateMessage(ctx.initialMsg.id, {
          'meta': ctx.metadata,
          'previewBytes': result.thumbBytes,
        });
      }
    } catch (e) {
      debugPrint(" [ImageProcessStep] 异常: $e");
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
            // 尝试从 meta 获取后缀，没有则根据类型判断
            String ext = ctx.metadata['fileExt'] ?? 'bin';
            if (ext == 'bin') {
              if (ctx.initialMsg.type == MessageType.video) {
                ext = 'mp4';
              } else if (ctx.initialMsg.type == MessageType.image) {
                ext = 'jpg';
              }
            }
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

      //  新增：文件字段 (从 ctx.metadata 透传给后端)
      'fileName': ctx.metadata['fileName'],
      'fileSize': ctx.metadata['fileSize'],
      'fileExt': ctx.metadata['fileExt'],
    };

    // 移除 null 值，保持 Payload 干净
    apiMeta.removeWhere((key, value) => value == null || value == "");

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