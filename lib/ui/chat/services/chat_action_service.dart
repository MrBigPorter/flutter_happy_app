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

  // 替换 ChatActionService.dart 中的 _sendPipeline 方法
  Future<void> _sendPipeline({
    required ChatUiModel msg,
    required Future<String> Function() getContentTask,
    Map<String, dynamic>? extraMeta,
  }) async {
    try {
      // 1. 本地乐观保存
      await LocalDatabaseService().saveMessage(msg);
      _updateConversationSnapshot(msg.content, msg.createdAt);

      // 2. 执行耗时任务
      final finalContent = await getContentTask();

      // 3. 组装发给服务器的 Meta (这里 combinedMeta 包含 URL，发给服务器是对的)
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

      // 5.  [核心修复] 更新本地状态
      // 服务器虽然返回了 URL，但我们本地必须强制保留文件名，否则 UI 会闪烁！

      final Map<String, dynamic> finalMetaToSave = Map.from(serverMsg.meta ?? {});

      // 检查：如果原始消息有本地封面，且不是网络地址
      if (msg.meta != null && msg.meta!['thumb'] != null) {
        final String originalThumb = msg.meta!['thumb'];
        // 只要原本是本地路径，就强制覆盖回去，死守本地文件！
        if (originalThumb.isNotEmpty && !originalThumb.startsWith('http')) {
          finalMetaToSave['thumb'] = originalThumb;

          // (可选) 把服务器的 URL 存到备用字段，以备不时之需
          if (serverMsg.meta != null && serverMsg.meta!.containsKey('thumb')) {
            finalMetaToSave['remote_thumb'] = serverMsg.meta!['thumb'];
          }
        }
      }

      await LocalDatabaseService().updateMessage(msg.id, {
        'status': MessageStatus.success.name,
        'seqId': serverMsg.seqId,
        'createdAt': _timeToInt(serverMsg.createdAt),
        'meta': finalMetaToSave, // <--- 使用我们处理过的 meta，而不是 serverMsg.meta
        if (msg.type != MessageType.text) 'content': serverMsg.content,
      });

    } catch (e) {
      debugPrint("Send Pipeline Error: $e");
      await LocalDatabaseService().updateMessageStatus(msg.id, MessageStatus.pending);
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
    // ==========================================
    // 1. 准备阶段 (Mobile)
    // ==========================================
    File? tempThumbFile;
    int tempWidth = 1080;
    int tempHeight = 1920;
    int tempDuration = 1;

    if (!kIsWeb) {
      try {
        tempThumbFile = await VideoCompress.getFileThumbnail(file.path, quality: 30, position: 1000);
      } catch (_) {
        try { tempThumbFile = await VideoCompress.getFileThumbnail(file.path, quality: 30, position: 0); } catch (_) {}
      }
      try {
        final info = await VideoCompress.getMediaInfo(file.path);
        tempDuration = (info.duration ?? 0) ~/ 1000;
        if (tempDuration < 1) tempDuration = 1;
        tempWidth = info.width ?? 1080;
        tempHeight = info.height ?? 1920;
      } catch (_) {}
    }

    // 封面落地：获取【本地文件名】(e.g. "images/cover_123.jpg")
    String localThumbName = "";
    if (!kIsWeb && tempThumbFile != null && tempThumbFile.existsSync()) {
      localThumbName = await AssetManager.save(XFile(tempThumbFile.path), MessageType.image);
    }

    final msgId = const Uuid().v4();
    _sessionPathCache[msgId] = file.path;

    // ==========================================
    // 2. 乐观上屏 (使用本地文件名)
    // ==========================================
    final tempMsg = _createBaseMessage(
      id: msgId,
      content: "[Video]",
      type: MessageType.video,
      localPath: file.path,
      meta: {
        'thumb': localThumbName, //  初始状态：本地文件名
        'w': tempWidth,
        'h': tempHeight,
        'duration': tempDuration,
      },
    );

    await LocalDatabaseService().saveMessage(tempMsg);
    _updateConversationSnapshot("[Video]", tempMsg.createdAt);

    // ==========================================
    // 3. 定义【服务器专用】Meta 容器
    // ==========================================
    final Map<String, dynamic> serverMetaContainer = {
      'w': tempWidth,
      'h': tempHeight,
      'duration': tempDuration,
      // 注意：这里初始为空，后面填入 URL
    };

    // ==========================================
    // 4. 后台任务
    // ==========================================
    await _sendPipeline(
      msg: tempMsg,
      extraMeta: serverMetaContainer, // 传给 API 用

      getContentTask: () async {
        // --- A. 视频压缩 ---
        final result = await VideoProcessor.process(file);
        if (result == null) throw Exception("Video Processing Failed");

        final videoName = await AssetManager.save(result.videoFile, MessageType.video);
        _cacheLocalPath(msgId, videoName, MessageType.video);

        // --- B. 准备上传封面 ---
        String? cdnThumbUrl;

        // 找文件：优先用刚才的 localThumbName (保证画面一致)
        File? fileToUpload;
        final savedThumbPath = await AssetManager.getFullPath(localThumbName, MessageType.image);

        if (savedThumbPath != null && File(savedThumbPath).existsSync()) {
          fileToUpload = File(savedThumbPath);
        } else {
          // 兜底：用压缩结果
          fileToUpload = result.thumbnailFile;
          // 如果之前的 localThumbName 是空的，这里补救一下，确保本地也有图
          if (localThumbName.isEmpty) {
            localThumbName = await AssetManager.save(XFile(fileToUpload.path), MessageType.image);
          }
        }

        // --- C. 上传封面 ---
        try {
          if (fileToUpload.existsSync()) {
            cdnThumbUrl = await _uploadService.uploadFile(
                file: XFile(fileToUpload.path),
                module: UploadModule.chat,
                onProgress: (_) {}
            );
          }
        } catch (_) {}

        // --- D.  分歧点：本地存文件，服务器发URL ---

        // 1. 更新【服务器 Meta】 -> 必须是 URL
        serverMetaContainer['w'] = result.width;
        serverMetaContainer['h'] = result.height;
        serverMetaContainer['duration'] = result.duration;

        if (cdnThumbUrl != null && cdnThumbUrl.startsWith('http')) {
          serverMetaContainer['thumb'] = cdnThumbUrl; // 对方看 URL
        } else {
          serverMetaContainer.remove('thumb'); // 失败就不发 thumb 字段
        }

        // 2. 更新【本地数据库 Meta】 ->  死守本地文件名，绝不换成 URL！
        // 这样 UI 永远读本地文件，不需要重新加载网络图，所以不会闪！
        await LocalDatabaseService().updateMessage(msgId, {
          'meta': {
            ...tempMsg.meta!,
            'w': result.width,         // 更新精确宽高
            'h': result.height,
            'duration': result.duration,
            'thumb': localThumbName,   //  重点：强制保持本地文件名！
          }
        });

        // --- E. 返回视频内容 ---
        return await _uploadAttachment(videoName, MessageType.video);
      },
    );

    if (!kIsWeb) VideoProcessor.clearCache();
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