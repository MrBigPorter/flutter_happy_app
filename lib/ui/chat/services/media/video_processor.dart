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

/// 视频处理结果 DTO
class VideoMediaResult {
  final XFile videoFile;
  final File thumbnailFile;
  final int width;
  final int height;
  final int duration; // 单位：秒
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
  // ---  1.1 全局串行锁：防止并发压缩导致 OOM ---
  static Completer<void>? _processingLock;

  // --- 1.3 熔断机制：硬性拦截超大文件 ---
  static const int kMaxProcessSize = 500 * 1024 * 1024; // 500MB
  //  核心配置
  static const int kMaxShortSide = 720;
  static const int kCrf = 26;
  static const int kFps = 24;

  /// 核心处理入口
  /// [onProgress] 回调压缩进度 (0.0 ~ 1.0)
  static Future<VideoMediaResult?> process(
    XFile rawVideo, {
    Function(double)? onProgress, //  1.2 增加进度回调
  }) async {
    // 熔断：检查原始大小
    final int fileSize = await File(rawVideo.path).length();
    if (fileSize > kMaxProcessSize) {
      debugPrint(" [VideoProcessor] 文件过大，拒绝处理: $fileSize");
      return null;
    }

    // --- 抢占串行锁：如果有任务在跑，就排队等待 ---
    while (_processingLock != null) {
      debugPrint(" [VideoProcessor] 任务排队中...");
      await _processingLock!.future;
    }
    _processingLock = Completer<void>();

    try {
      final String inputPath = rawVideo.path;

      // 获取视频信息 (双引擎)
      final mediaInfo = await _getSafeMediaInfo(inputPath);
      final int oriWidth = mediaInfo['width'] ?? 720;
      final int oriHeight = mediaInfo['height'] ?? 1280;
      int durationMs = mediaInfo['duration'] ?? 0;

      if (durationMs <= 0) {
        final info = await vc.VideoCompress.getMediaInfo(inputPath);
        durationMs = info.duration?.toInt() ?? 0;
      }

      final int durationSec = max(1, (durationMs / 1000).round());

      // 智能直传策略
      if (fileSize < 10 * 1024 * 1024 &&
          min(oriWidth, oriHeight) <= kMaxShortSide) {
        debugPrint(" [VideoProcessor] 跳过压缩");
        onProgress?.call(1.0); // 直传进度直接 100%
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

      // FFmpeg 压缩逻辑
      final Directory tempDir = await getTemporaryDirectory();
      final String outputPath =
          '${tempDir.path}/cmp_${DateTime.now().millisecondsSinceEpoch}.mp4';

      String scaleFilter = min(oriWidth, oriHeight) > kMaxShortSide
          ? (oriWidth < oriHeight
                ? "scale=$kMaxShortSide:-2"
                : "scale=-2:$kMaxShortSide")
          : "scale=-2:-2";

      final String command =
          '-i "$inputPath" -c:v libx264 -crf $kCrf -preset veryfast -r $kFps -vf "$scaleFilter" -c:a aac -b:a 128k -movflags +faststart -y "$outputPath"';

      debugPrint(" [VideoProcessor] 开始压缩: $command");

      // 执行压缩并监听进度
      final completer = Completer<bool>();
      FFmpegKit.executeAsync(
        command,
        (FFmpegSession session) async {
          final returnCode = await session.getReturnCode();
          completer.complete(ReturnCode.isSuccess(returnCode));
        },
        null, // LogCallback
        (Statistics stats) {
          //  实时解析进度
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
      debugPrint("Process Error: $e");
      return null;
    } finally {
      // --- 释放锁：允许队列中下一个任务开始 ---
      _processingLock?.complete();
      _processingLock = null;
    }
  }

  ///  清理缓存
  static Future<void> clearCache() async {
    await vc.VideoCompress.deleteAllCache();
  }

  ///  安全获取媒体信息 (双引擎：FFprobe + VideoCompress)
  static Future<Map<String, int>> _getSafeMediaInfo(String path) async {
    Map<String, int> result = {'width': 0, 'height': 0, 'duration': 0};

    // 引擎 1: 尝试 FFprobe
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final info = session.getMediaInformation();
      if (info != null) {
        final streams = info.getStreams();
        // 修复：防止 firstWhere 找不到崩溃
        if (streams.isNotEmpty) {
          try {
            final videoStream = streams.firstWhere(
              (s) => s.getType() == 'video',
            );
            result['width'] = videoStream.getWidth() ?? 0;
            result['height'] = videoStream.getHeight() ?? 0;
          } catch (_) {}
        }

        // 解析时长 (FFprobe 返回的是秒，如 "12.5")
        final String? durStr = info.getDuration();
        if (durStr != null) {
          //  修复：安全解析 double
          final double? d = double.tryParse(durStr);
          if (d != null) {
            result['duration'] = (d * 1000).toInt();
          }
        }
      }
    } catch (e) {
      debugPrint("FFprobe info failed: $e");
    }

    // 引擎 2: 如果时长或宽高为0，使用 VideoCompress (原生 MediaMetadataRetriever) 补救
    // 这是解决时长为 0 的关键！
    if (result['duration'] == 0 || result['width'] == 0) {
      try {
        final info = await vc.VideoCompress.getMediaInfo(path);
        if (result['width'] == 0) result['width'] = info.width ?? 0;
        if (result['height'] == 0) result['height'] = info.height ?? 0;
        if (result['duration'] == 0)
          result['duration'] = info.duration?.toInt() ?? 0; // 毫秒
      } catch (e) {
        debugPrint("VideoCompress info failed: $e");
      }
    }

    debugPrint(
      " [MediaInfo] w:${result['width']} h:${result['height']} d:${result['duration']}ms",
    );
    return result;
  }
}
