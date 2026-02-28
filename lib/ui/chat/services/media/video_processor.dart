import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart' as vc;

/// Data Transfer Object for Video Processing Results
class VideoMediaResult {
  final XFile videoFile;
  final File thumbnailFile;
  final int width;
  final int height;
  final int duration; // Unit: Seconds
  final bool isOriginal;

  VideoMediaResult({
    required this.videoFile,
    required this.thumbnailFile,
    required this.width,
    required this.height,
    required this.duration,
    this.isOriginal = false,
  });
}

class VideoProcessor {
  // --- 1.1 Global Serial Lock: Prevents OOM caused by concurrent compression tasks ---
  static Completer<void>? _processingLock;

  // --- 1.3 Circuit Breaker: Hard limit for oversized files ---
  static const int kMaxProcessSize = 500 * 1024 * 1024; // 500MB

  // Core Compression Configuration
  static const int kMaxShortSide = 720;
  static const int kCrf = 26;
  static const int kFps = 24;

  /// Main entry point for video processing.
  /// [onProgress] returns compression progress (0.0 ~ 1.0).
  static Future<VideoMediaResult?> process(
      XFile rawVideo, {
        Function(double)? onProgress,
      }) async {
    // Validation: Check original file size
    final int fileSize = await File(rawVideo.path).length();
    if (fileSize > kMaxProcessSize) {
      debugPrint("[VideoProcessor] File too large, rejecting: $fileSize");
      return null;
    }

    // --- Acquire Serial Lock: Queue tasks if another process is running ---
    while (_processingLock != null) {
      debugPrint("[VideoProcessor] Task queued, waiting for previous task to complete...");
      await _processingLock!.future;
    }
    _processingLock = Completer<void>();

    try {
      final String inputPath = rawVideo.path;

      // Fetch metadata using dual-engine (FFprobe + VideoCompress)
      final mediaInfo = await _getSafeMediaInfo(inputPath);
      final int oriWidth = mediaInfo['width'] ?? 720;
      final int oriHeight = mediaInfo['height'] ?? 1280;
      int durationMs = mediaInfo['duration'] ?? 0;

      if (durationMs <= 0) {
        final info = await vc.VideoCompress.getMediaInfo(inputPath);
        durationMs = info.duration?.toInt() ?? 0;
      }

      final int durationSec = max(1, (durationMs / 1000).round());

      // Intelligent Passthrough Strategy
      if (fileSize < 10 * 1024 * 1024 &&
          min(oriWidth, oriHeight) <= kMaxShortSide) {
        debugPrint("[VideoProcessor] Skipping compression; file meets optimization criteria");
        onProgress?.call(1.0);
        final File thumb = await vc.VideoCompress.getFileThumbnail(
          inputPath,
          quality: 60,
          position: 1000,
        );
        return VideoMediaResult(
          videoFile: rawVideo,
          thumbnailFile: thumb,
          width: oriWidth,
          height: oriHeight,
          duration: durationSec,
          isOriginal: true,
        );
      }

      // FFmpeg Compression Logic
      final Directory tempDir = await getTemporaryDirectory();
      final String outputPath =
          '${tempDir.path}/cmp_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // Calculate scale filter based on aspect ratio
      String scaleFilter = min(oriWidth, oriHeight) > kMaxShortSide
          ? (oriWidth < oriHeight
          ? "scale=$kMaxShortSide:-2"
          : "scale=-2:$kMaxShortSide")
          : "scale=-2:-2";

      // Command explanation:
      // -crf 26: Balances quality and size
      // -movflags +faststart: Moves MOOV atom to the front for instant web playback
      final String command =
          '-i "$inputPath" -c:v libx264 -crf $kCrf -preset veryfast -r $kFps -vf "$scaleFilter" -c:a aac -b:a 128k -movflags +faststart -y "$outputPath"';

      debugPrint("[VideoProcessor] Starting compression: $command");

      final completer = Completer<bool>();
      FFmpegKit.executeAsync(
        command,
            (FFmpegSession session) async {
          final returnCode = await session.getReturnCode();
          completer.complete(ReturnCode.isSuccess(returnCode));
        },
        null, // LogCallback
            (Statistics stats) {
          // Real-time progress parsing
          if (onProgress != null && durationMs > 0) {
            double progress = stats.getTime() / durationMs;
            onProgress(progress.clamp(0.0, 1.0));
          }
        },
      );

      final success = await completer.future;
      if (!success) return null;

      final File thumbnailFile = await vc.VideoCompress.getFileThumbnail(
        outputPath,
        quality: 60,
        position: 1000,
      );

      final newInfo = await _getSafeMediaInfo(outputPath);

      return VideoMediaResult(
        videoFile: XFile(outputPath),
        thumbnailFile: thumbnailFile,
        width: newInfo['width'] ?? oriWidth,
        height: newInfo['height'] ?? oriHeight,
        duration: durationSec,
        isOriginal: false,
      );
    } catch (e) {
      debugPrint("[VideoProcessor] Processing failed: $e");
      return null;
    } finally {
      // --- Release Lock: Allow next task in queue to start ---
      _processingLock?.complete();
      _processingLock = null;
    }
  }

  /// Clears temporary compression cache
  static Future<void> clearCache() async {
    await vc.VideoCompress.deleteAllCache();
  }

  /// Safely retrieves media information using a dual-engine approach (FFprobe + VideoCompress)
  static Future<Map<String, int>> _getSafeMediaInfo(String path) async {
    Map<String, int> result = {'width': 0, 'height': 0, 'duration': 0};

    // Engine 1: Primary attempt with FFprobe
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final info = session.getMediaInformation();
      if (info != null) {
        final streams = info.getStreams();
        if (streams.isNotEmpty) {
          try {
            final videoStream = streams.firstWhere(
                  (s) => s.getType() == 'video',
            );
            result['width'] = videoStream.getWidth() ?? 0;
            result['height'] = videoStream.getHeight() ?? 0;
          } catch (_) {}
        }

        final String? durStr = info.getDuration();
        if (durStr != null) {
          final double? d = double.tryParse(durStr);
          if (d != null) {
            result['duration'] = (d * 1000).toInt();
          }
        }
      }
    } catch (e) {
      debugPrint("[VideoProcessor] FFprobe parsing failed: $e");
    }

    // Engine 2: Fallback to VideoCompress (Native MediaMetadataRetriever)
    if (result['duration'] == 0 || result['width'] == 0) {
      try {
        final info = await vc.VideoCompress.getMediaInfo(path);
        if (result['width'] == 0) result['width'] = info.width ?? 0;
        if (result['height'] == 0) result['height'] = info.height ?? 0;
        if (result['duration'] == 0)
          result['duration'] = info.duration?.toInt() ?? 0;
      } catch (e) {
        debugPrint("[VideoProcessor] VideoCompress parsing failed: $e");
      }
    }

    debugPrint(
      "[VideoProcessor] Resolved MediaInfo: w:${result['width']} h:${result['height']} d:${result['duration']}ms",
    );
    return result;
  }
}