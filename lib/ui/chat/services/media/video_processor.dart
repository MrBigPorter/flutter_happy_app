import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
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
  //  核心配置
  static const int kMaxShortSide = 720;
  static const int kCrf = 26;
  static const int kFps = 24;

  /// 核心处理入口
  static Future<VideoMediaResult?> process(XFile rawVideo) async {
    try {
      final String inputPath = rawVideo.path;

      // 1.  获取视频信息 (加了双重保险)
      // 如果 FFprobe 失败，会自动尝试 VideoCompress
      final mediaInfo = await _getSafeMediaInfo(inputPath);

      // 提取关键数据 (给默认值防止空指针)
      final int oriWidth = mediaInfo['width'] ?? 720;
      final int oriHeight = mediaInfo['height'] ?? 1280;
      int durationMs = mediaInfo['duration'] ?? 0; // 毫秒

      // 如果时长还是 0，尝试最后一种手段：VideoCompress 再次读取
      if (durationMs <= 0) {
        final info = await vc.VideoCompress.getMediaInfo(inputPath);
        durationMs = info.duration?.toInt() ?? 0;
      }

      // 转成秒，至少为 1秒
      final int durationSec = max(1, (durationMs / 1000).round());

      // 2.  智能直传策略
      // 如果视频小于 10MB 且分辨率不高，直接发原片
      final int fileSize = await File(inputPath).length();
      if (fileSize < 10 * 1024 * 1024 && min(oriWidth, oriHeight) <= kMaxShortSide) {
        debugPrint(" [VideoProcessor] 视频较小 ($fileSize bytes)，跳过压缩");
        //  修复：截取第 1 秒，防止黑屏
        final File thumb = await vc.VideoCompress.getFileThumbnail(
            inputPath,
            quality: 60,
            position: 1000 // 毫秒
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

      // 3.  FFmpeg 压缩逻辑
      final Directory tempDir = await getTemporaryDirectory();
      final String outputPath = '${tempDir.path}/cmp_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // 缩放计算
      String scaleFilter = "";
      if (min(oriWidth, oriHeight) > kMaxShortSide) {
        if (oriWidth < oriHeight) {
          scaleFilter = "scale=$kMaxShortSide:-2";
        } else {
          scaleFilter = "scale=-2:$kMaxShortSide";
        }
      } else {
        scaleFilter = "scale=-2:-2";
      }

      final String command =
          '-i "$inputPath" '
          '-c:v libx264 -crf $kCrf -preset veryfast '
          '-r $kFps '
          '-vf "$scaleFilter" '
          '-c:a aac -b:a 128k '
          '-movflags +faststart ' // 关键：边下边播支持
          '-y "$outputPath"';

      debugPrint(" [VideoProcessor] 开始压缩: $command");

      // 4. 执行压缩
      final completer = Completer<bool>();
      FFmpegKit.executeAsync(
          command,
              (FFmpegSession session) async {
            final returnCode = await session.getReturnCode();
            if (ReturnCode.isSuccess(returnCode)) {
              completer.complete(true);
            } else {
              debugPrint(" FFmpeg 失败: ${await session.getOutput()}");
              completer.complete(false);
            }
          },
          null,
          null
      );

      final success = await completer.future;
      if (!success) return null;

      // 5. 再次取封面 (用压缩后的文件取更准)
      //  修复：截取第 1 秒
      final File thumbnailFile = await vc.VideoCompress.getFileThumbnail(
          outputPath,
          quality: 60,
          position: 1000
      );

      // 读取新文件宽高，但保留原视频时长 (有时候压缩后 metadata 会丢失)
      final newInfo = await _getSafeMediaInfo(outputPath);

      return VideoMediaResult(
        videoFile: XFile(outputPath),
        thumbnailFile: thumbnailFile,
        width: newInfo['width'] ?? oriWidth,
        height: newInfo['height'] ?? oriHeight,
        duration: durationSec, // 使用最开始获取的准确时长
        isOriginal: false,
      );

    } catch (e) {
      debugPrint("Process Error: $e");
      return null;
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
            final videoStream = streams.firstWhere((s) => s.getType() == 'video');
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
        if (result['duration'] == 0) result['duration'] = info.duration?.toInt() ?? 0; // 毫秒
      } catch (e) {
        debugPrint("VideoCompress info failed: $e");
      }
    }

    debugPrint(" [MediaInfo] w:${result['width']} h:${result['height']} d:${result['duration']}ms");
    return result;
  }
}