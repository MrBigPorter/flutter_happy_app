import 'dart:io';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_app/core/api/lucky_api.dart';
import 'package:flutter_app/utils/asset/asset_manager.dart';

import '../../../../utils/media/media_path.dart';
import '../models/chat_ui_model.dart';
import '../services/blurHash/blur_hash_service.dart';
import '../services/media/video_processor.dart';
import '../services/media/web_video_thumbnail_service.dart';
import 'pipeline_types.dart';

// ===========================================================================
// 1. Persist Step (Local Sandbox Storage)
// ===========================================================================
class PersistStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, dynamic service) async {
    // Web Isolation: Skip file system operations as Web relies on Blob URLs.
    if (kIsWeb) return;

    final lp = ctx.initialMsg.localPath;
    if (lp == null || lp.isEmpty) return;

    // 1) Save original file to local app sandbox (Mobile only).
    final assetId = await AssetManager.save(
      XFile(ctx.initialMsg.localPath!),
      ctx.initialMsg.type,
    );

    // 2) Resolve the unique AssetID into an absolute system path.
    final resolved = await AssetManager.getFullPath(
      assetId,
      ctx.initialMsg.type,
    );

    if (resolved != null) {
      ctx.currentAbsolutePath = resolved;
    }

    // 3) Patch Update: Synchronize the local asset identifiers to the repository.
    await service.repo.patchFields(ctx.initialMsg.id, {
      'localPath': assetId,
      'resolvedPath': resolved
    });
  }
}

// ===========================================================================
// 2. Recover Step (Resend / State Recovery)
// ===========================================================================
class RecoverStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, dynamic service) async {
    final assetId = ctx.initialMsg.localPath;
    if (assetId == null) return;

    // Web: Directly trust the existing Blob URL.
    if (kIsWeb) {
      ctx.currentAbsolutePath = assetId;
      return;
    }

    if (!assetId.startsWith('http')) {
      // 1. Attempt standard resolution via AssetManager.
      ctx.currentAbsolutePath = await AssetManager.getFullPath(
        assetId,
        ctx.initialMsg.type,
      );

      // 2. Brute-force fallback: Search known directories if primary lookup fails (Mobile only).
      if (ctx.currentAbsolutePath == null ||
          !File(ctx.currentAbsolutePath!).existsSync()) {
        final foundPath = await _tryFindLocalFile(assetId, ctx.initialMsg.type);
        if (foundPath != null) {
          ctx.currentAbsolutePath = foundPath;
        }
      }
    }

    // Recover thumbnail identifier from metadata.
    final thumbId = ctx.initialMsg.meta?['thumb'];
    if (thumbId != null && !thumbId.toString().startsWith('http')) {
      ctx.thumbAssetId = thumbId.toString();
    }
  }

  /// Attempts to locate lost local files in standard chat subdirectories.
  Future<String?> _tryFindLocalFile(String rawPath, MessageType type) async {
    if (rawPath.isEmpty || kIsWeb) return null;

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
// 3. Video Processing Step
// ===========================================================================
class VideoProcessStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, dynamic service) async {
    // --- Web Implementation ---
    if (kIsWeb) {
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

            // Generate BlurHash for visual transition optimization.
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

            // Partial update: Meta and preview bytes only to prevent flickering.
            await service.repo.patchFields(ctx.initialMsg.id, {
              'meta': metaUpdates,
              'previewBytes': thumbJpeg
            });
          }
        } catch (_) {}
      }
      return;
    }

    // --- Mobile Implementation (FFmpeg/Compression) ---
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
// 4. Image Processing Step
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

        // Early patch: Provide BlurHash and previewBytes to UI before upload finishes.
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
// 5. Upload Step (Dual-Target Upload: Thumbnail & Main Content)
// ===========================================================================
class UploadStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, dynamic service) async {
    // -------------------------
    // A) Thumbnail Upload
    // -------------------------
    final hasRemoteThumb = MediaPath.isRemote(ctx.remoteThumbUrl);
    if (!hasRemoteThumb) {
      if (kIsWeb) {
        final webThumb = ctx.webThumbFile;
        if (webThumb != null) {
          ctx.remoteThumbUrl = await service.uploadChatFile(webThumb);
        }
      } else if (ctx.remoteThumbUrl == null && ctx.thumbAssetId != null) {
        String? path = await AssetManager.getFullPath(
          ctx.thumbAssetId!,
          MessageType.image,
        );
        if (path != null && File(path).existsSync()) {
          ctx.remoteThumbUrl = await service.uploadChatFile(XFile(path));
        }
      }
    }

    // -------------------------
    // B) Main Content Upload
    // -------------------------
    final hasRemoteContent = MediaPath.isRemote(ctx.initialMsg.content);

    if (!hasRemoteContent) {
      String? uploadPath = ctx.currentAbsolutePath ?? ctx.initialMsg.localPath;

      // Mobile Path Validation & Recovery fallback.
      if (!kIsWeb && uploadPath != null && uploadPath.isNotEmpty) {
        if (!File(uploadPath).existsSync() && !MediaPath.isRemote(uploadPath)) {
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
          // Web: Ensure proper extension for cloud storage compatibility.
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
        throw "Fatal: Local file lost, cannot resend. Path: $uploadPath";
      }
    } else {
      ctx.remoteUrl = ctx.initialMsg.content;
    }

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
// 6. Sync Step (Server Communication)
// ===========================================================================
class SyncStep implements PipelineStep {
  @override
  Future<void> execute(PipelineContext ctx, dynamic service) async {
    // 1) Pre-sync validation.
    if (ctx.initialMsg.type == MessageType.image || ctx.initialMsg.type == MessageType.video) {
      if (ctx.remoteUrl == null || ctx.remoteUrl!.isEmpty) {
        throw "[Sync] Upload incomplete or failed.";
      }
    }

    // 2) Construct payload for the API endpoint.
    final apiMeta = <String, dynamic>{
      'blurHash': ctx.metadata['blurHash'],
      'w': ctx.metadata['w'],
      'h': ctx.metadata['h'],
      'duration': ctx.metadata['duration'],
      'thumb': ctx.remoteThumbUrl ?? ctx.metadata['remote_thumb'] ?? "",
      'fileName': ctx.metadata['fileName'],
      'fileSize': ctx.metadata['fileSize'],
      'fileExt': ctx.metadata['fileExt'],
    }..removeWhere((k, v) => v == null || v == "");

    // 3) Inform server to finalize the message and obtain authoritative seqId.
    final serverMsg = await Api.sendMessage(
      id: ctx.initialMsg.id,
      conversationId: service.conversationId,
      content: ctx.remoteUrl ?? ctx.initialMsg.content,
      type: ctx.initialMsg.type.value,
      meta: apiMeta,
    );

    // 4) Merge server-side authoritative metadata with local context.
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
      'content': serverMsg.content.isNotEmpty ? serverMsg.content : ctx.remoteUrl,
      'meta': mergedMeta
    };

    // Web Double-Insurance: Explicitly preserve local Blob paths to maintain
    // instant UI availability without needing to download back from the cloud.
    if (kIsWeb) {
      final initialPath = ctx.initialMsg.localPath;
      if (initialPath != null && initialPath.startsWith('blob:')) {
        updates['localPath'] = initialPath;
        updates['resolvedPath'] = initialPath;
        if (ctx.initialMsg.previewBytes != null) {
          updates['previewBytes'] = ctx.initialMsg.previewBytes;
        }
      }
    }

    // 5) Final repository patch.
    await service.repo.patchFields(ctx.initialMsg.id, updates);
  }
}