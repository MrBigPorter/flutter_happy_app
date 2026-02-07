import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_app/core/api/lucky_api.dart';
import 'package:flutter_app/utils/asset/asset_manager.dart';

import '../../../../utils/media/media_path.dart';
import '../../../utils/asset/web/web_blob_url.dart';
import '../models/chat_ui_model.dart';
import '../services/blurHash/blur_hash_service.dart';
import '../services/media/video_processor.dart';
import '../services/media/web_video_thumbnail_service.dart';
import 'pipeline_types.dart';

// ===========================================================================
// 1. 本地持久化 (Persist)
// ===========================================================================
class PersistStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, dynamic service) async {
    // 🔥 Web 端物理隔绝：不需要搬运文件到沙盒
    if (kIsWeb) return;

    final lp = ctx.initialMsg.localPath;
    if (lp == null || lp.isEmpty) return;

    // 1) 保存到本地沙盒 (仅 Mobile)
    final assetId = await AssetManager.save(
      XFile(ctx.initialMsg.localPath!),
      ctx.initialMsg.type,
    );

    // 2) 解析出绝对路径
    final resolved = await AssetManager.getFullPath(
      assetId,
      ctx.initialMsg.type,
    );

    if (resolved != null) {
      ctx.currentAbsolutePath = resolved;
    }

    // 3) 🔥 Patch 更新：只更新路径，不动其他字段
    await service.repo.patchFields(ctx.initialMsg.id, {
      'localPath': assetId,
      'resolvedPath': resolved
    });
  }
}

// ===========================================================================
// 2. 恢复步骤 (Recover - 重发专用)
// ===========================================================================
class RecoverStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, dynamic service) async {
    final assetId = ctx.initialMsg.localPath;
    if (assetId == null) return;

    // Web 端直接信任 blob 路径
    if (kIsWeb) {
      ctx.currentAbsolutePath = assetId;
      return;
    }

    if (!assetId.startsWith('http')) {
      // 1. 尝试标准解析
      ctx.currentAbsolutePath = await AssetManager.getFullPath(
        assetId,
        ctx.initialMsg.type,
      );

      // 2. 暴力查找兜底 (仅 Mobile)
      if (ctx.currentAbsolutePath == null ||
          !File(ctx.currentAbsolutePath!).existsSync()) {
        final foundPath = await _tryFindLocalFile(assetId, ctx.initialMsg.type);
        if (foundPath != null) {
          ctx.currentAbsolutePath = foundPath;
        }
      }
    }

    // 恢复缩略图 ID
    final thumbId = ctx.initialMsg.meta?['thumb'];
    if (thumbId != null && !thumbId.toString().startsWith('http')) {
      ctx.thumbAssetId = thumbId.toString();
    }
  }

  Future<String?> _tryFindLocalFile(String rawPath, MessageType type) async {
    if (rawPath.isEmpty) return null;
    // Web 环境下不跑文件检查
    if (kIsWeb) return null;

    if (File(rawPath).existsSync()) return rawPath;

    try {
      final docDir = await getApplicationDocumentsDirectory();
      String subDir = '';
      switch (type) {
        case MessageType.image: subDir = 'chat_images'; break;
        case MessageType.video: subDir = 'chat_video'; break;
        case MessageType.audio: subDir = 'chat_audio'; break;
        case MessageType.file: subDir = 'chat_files'; break;
        default: subDir = 'chat_images';
      }

      final fileName = rawPath.split('/').last;
      final fallback = p.join(docDir.path, subDir, fileName);

      if (File(fallback).existsSync()) return fallback;
    } catch (_) {}

    return null;
  }
}

// ===========================================================================
// 3. 视频处理 (VideoProcess)
// ===========================================================================
class VideoProcessStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, dynamic service) async {
    // ---------------- Web 处理 ----------------
    if (kIsWeb) {
      // Web 端通常在 sendVideo 入口已经生成了 webThumbFile
      // 如果没有，这里尝试补救
      if (ctx.webThumbFile == null) {
        final src = ctx.sourceFile;
        if (src == null) return;
        try {
          final videoBytes = await src.readAsBytes();
          final thumbJpeg = await WebVideoThumbnailService.extractJpegThumb(
            videoBytes,
            atSeconds: 0.1,
            maxWidth: 320,
            quality: 0.85,
          );

          if (thumbJpeg != null && thumbJpeg.isNotEmpty) {
            ctx.webThumbFile = XFile.fromData(
              thumbJpeg,
              name: 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg',
              mimeType: 'image/jpeg',
            );

            // 补全 BlurHash
            final blur = await ThumbBlurHashService.build(thumbJpeg);
            final metaUpdates = <String, dynamic>{
              ...(ctx.initialMsg.meta ?? {}),
              ...ctx.metadata
            };

            if (blur != null) {
              metaUpdates['blurHash'] = blur.blurHash;
              metaUpdates['w'] = blur.thumbW;
              metaUpdates['h'] = blur.thumbH;
            }

            // 🔥 Patch 更新：只更新 meta 和 previewBytes
            await service.repo.patchFields(ctx.initialMsg.id, {
              'meta': metaUpdates,
              'previewBytes': thumbJpeg
            });
          }
        } catch (_) {}
      }
      return;
    }

    // ---------------- Mobile 处理 ----------------
    final result = await VideoProcessor.process(XFile(ctx.currentAbsolutePath!));
    if (result == null) throw "Video Compression Failed";

    final thumbBytes = await File(result.thumbnailFile.path).readAsBytes();
    final thumbResult = await ThumbBlurHashService.build(thumbBytes);

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
      'blurHash': thumbResult?.blurHash ?? "",
    });

    // 🔥 Patch 更新：更新 meta, previewBytes 和 resolvedPath
    await service.repo.patchFields(ctx.initialMsg.id, {
      'meta': {
        ...(ctx.initialMsg.meta ?? {}),
        ...ctx.metadata
      },
      'previewBytes': thumbResult?.thumbBytes ?? thumbBytes,
      'resolvedPath': ctx.currentAbsolutePath
    });
  }
}

// ===========================================================================
// 4. 图片处理 (ImageProcess)
// ===========================================================================
class ImageProcessStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, dynamic service) async {
    final path = ctx.currentAbsolutePath ?? ctx.initialMsg.localPath;
    if (path == null) return;

    try {
      final bytes = await XFile(path).readAsBytes();
      final result = await ThumbBlurHashService.build(bytes);

      if (result != null) {
        ctx.metadata.addAll({
          'blurHash': result.blurHash,
          'w': result.thumbW,
          'h': result.thumbH,
        });

        // 🔥 Patch 更新：只更新 meta 和 previewBytes
        // 这样即使上传慢，本地 blurHash 也会先出来
        await service.repo.patchFields(ctx.initialMsg.id, {
          'meta': ctx.metadata,
          'previewBytes': result.thumbBytes,
        });
      }
    } catch (e) {
      debugPrint("[ImageProcessStep] Error: $e");
    }
  }
}

// ===========================================================================
// 5. 上传步骤 (Upload)
// ===========================================================================
class UploadStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, dynamic service) async {
    // -------------------------
    // A) 封面上传
    // -------------------------
    final hasRemoteThumb = MediaPath.isRemote(ctx.remoteThumbUrl);
    if (!hasRemoteThumb) {
      // 1) Web：直接上传内存封面 (最可靠)
      if (kIsWeb) {
        final webThumb = ctx.webThumbFile;
        if (webThumb != null) {
          ctx.remoteThumbUrl = await service.uploadChatFile(webThumb);
        }
      }

      // 2) Mobile：走本地文件系统
      if (!kIsWeb && ctx.remoteThumbUrl == null && ctx.thumbAssetId != null) {
        String? path = await AssetManager.getFullPath(
          ctx.thumbAssetId!,
          MessageType.image,
        );

        if (path != null && MediaPath.classify(path) == MediaPathType.fileUri) {
          try { path = Uri.parse(path).toFilePath(); } catch (_) {}
        }

        if (path != null && File(path).existsSync()) {
          ctx.remoteThumbUrl = await service.uploadChatFile(XFile(path));
        }
      }
    }

    // -------------------------
    // B) 主文件上传
    // -------------------------
    final hasRemoteContent = MediaPath.isRemote(ctx.initialMsg.content);

    if (!hasRemoteContent) {
      String? uploadPath = ctx.currentAbsolutePath ?? ctx.initialMsg.localPath;

      // Mobile 端路径检查
      if (!kIsWeb && uploadPath != null && uploadPath.isNotEmpty) {
        if (MediaPath.classify(uploadPath) == MediaPathType.fileUri) {
          try { uploadPath = Uri.parse(uploadPath).toFilePath(); } catch (_) {}
        }
        // 如果路径不存在，尝试最后的挣扎
        if (!File(uploadPath!).existsSync() && !MediaPath.isRemote(uploadPath)) {
          final found = await RecoverStep()._tryFindLocalFile(uploadPath, ctx.initialMsg.type);
          if (found != null) {
            uploadPath = found;
            ctx.currentAbsolutePath = found;
          }
        }
      }

      if (uploadPath != null && (kIsWeb || File(uploadPath).existsSync())) {
        XFile fileToUpload;

        if (kIsWeb && ctx.sourceFile != null && uploadPath == ctx.sourceFile!.path) {
          fileToUpload = ctx.sourceFile!;
        } else {
          fileToUpload = XFile(uploadPath);
          // Web 端自动补全后缀名防止后端报错
          if (kIsWeb && (fileToUpload.name.isEmpty || !fileToUpload.name.contains('.'))) {
            String ext = ctx.metadata['fileExt'] ?? 'bin';
            if (ext == 'bin') {
              if (ctx.initialMsg.type == MessageType.video) ext = 'mp4';
              if (ctx.initialMsg.type == MessageType.image) ext = 'jpg';
            }
            fileToUpload = XFile(uploadPath, name: 'upload_${DateTime.now().millisecondsSinceEpoch}.$ext');
          }
        }

        ctx.remoteUrl = await service.uploadChatFile(fileToUpload);
      } else {
        final errMsg = "Fatal: 本地文件已丢失，无法重发。\n路径: $uploadPath";
        debugPrint("【UploadStep】$errMsg");
        throw errMsg;
      }
    } else {
      ctx.remoteUrl = ctx.initialMsg.content;
    }

    // 🔥 Patch 更新：如果上传成功，只更新 content(URL) 和 remote_thumb
    // 绝对不覆盖 previewBytes
    if (ctx.remoteUrl != null) {
      final updates = <String, dynamic>{'content': ctx.remoteUrl};

      if (ctx.remoteThumbUrl != null) {
        updates['meta'] = {
          ...(ctx.initialMsg.meta ?? {}),
          ...ctx.metadata,
          'remote_thumb': ctx.remoteThumbUrl
        };
      }

      await service.repo.patchFields(ctx.initialMsg.id, updates);
    }
  }
}

// ===========================================================================
// 6. 同步步骤 (Sync)
// ===========================================================================
// ===========================================================================
// 6. 同步步骤 (Sync)
// ===========================================================================
// ===========================================================================
// 6. 同步步骤 (Sync)
// ===========================================================================
class SyncStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, dynamic service) async {
    // 1) 预检
    if (ctx.initialMsg.type == MessageType.image || ctx.initialMsg.type == MessageType.video) {
      if (ctx.remoteUrl == null || ctx.remoteUrl!.isEmpty) {
        throw "【同步中止】上传未完成";
      }
    }

    // 2) 准备给服务器的 Meta
    final apiMeta = <String, dynamic>{
      'blurHash': ctx.metadata['blurHash'],
      'w': ctx.metadata['w'],
      'h': ctx.metadata['h'],
      'duration': ctx.metadata['duration'],
      'thumb': ctx.remoteThumbUrl ?? ctx.metadata['remote_thumb'] ?? "",
      'fileName': ctx.metadata['fileName'],
      'fileSize': ctx.metadata['fileSize'],
      'fileExt': ctx.metadata['fileExt'],
      // ... 其他字段
    }..removeWhere((k, v) => v == null || v == "");

    // 3) 发送给服务器 (这一步只是为了告诉服务器“我发了”，拿回 seqId)
    final serverMsg = await Api.sendMessage(
      id: ctx.initialMsg.id,
      conversationId: service.conversationId,
      content: ctx.remoteUrl ?? ctx.initialMsg.content,
      type: ctx.initialMsg.type.value,
      meta: apiMeta,
    );

    // 4) 准备本地更新数据 (Patch)
    final serverMeta = serverMsg.meta ?? {};
    final mergedMeta = <String, dynamic>{
      ...(ctx.initialMsg.meta ?? {}),
      ...ctx.metadata,
      ...serverMeta
    };

    if (ctx.remoteThumbUrl != null) {
      mergedMeta['remote_thumb'] = ctx.remoteThumbUrl;
    }

    final updates = <String, dynamic>{
      'status': MessageStatus.success.name,
      // 🔥🔥🔥 关键点 1：这里把远程 URL 存进去了！🔥🔥🔥
      // 以后就算你清除缓存重新加载，或者分享给别人，用的就是这个 URL。
      'content': serverMsg.content.isNotEmpty ? serverMsg.content : ctx.remoteUrl,
      'meta': mergedMeta
    };

    // 🔥🔥🔥 关键点 2：强制保留本地 Blob！🔥🔥🔥
    // 我们在这里做“双保险”。
    // 数据库存了：content="http://...", localPath="blob:..."
    if (kIsWeb) {
      final initialPath = ctx.initialMsg.localPath;
      if (initialPath != null && initialPath.startsWith('blob:')) {
        updates['localPath'] = initialPath;
        updates['resolvedPath'] = initialPath;

        // 视频封面也保住
        if (ctx.initialMsg.previewBytes != null) {
          updates['previewBytes'] = ctx.initialMsg.previewBytes;
        }
      }
    }

    // 5) 执行更新
    // 这一步是“内部操作”，MessageRepository 会执行它。
    // 而 LocalDatabaseService.handleIncomingMessage (Socket) 里的拦截逻辑不会影响这里。
    await service.repo.patchFields(ctx.initialMsg.id, updates);
  }
}