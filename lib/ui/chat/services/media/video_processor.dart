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
  final int duration;
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
  //  核心配置：根据微信标准设定
  static const int kMaxShortSide = 720; // 短边最大 720p
  static const int kCrf = 26;           // 压缩质量 (越小画质越好，23-28 是移动端最佳区间)
  static const int kFps = 24;           // 帧率限制 (IM 不需要 60fps)

  /// 核心处理入口
  static Future<VideoMediaResult?> process(XFile rawVideo) async {
    try {
      final String inputPath = rawVideo.path;

      // 1. 获取视频信息 (宽高、时长)
      final mediaInfo = await _getMediaInfo(inputPath);
      if (mediaInfo == null) return null;

      final int oriWidth = mediaInfo['width'];
      final int oriHeight = mediaInfo['height'];
      final int durationMs = mediaInfo['duration'];

      // 2.  智能直传策略 (Smart Bypass)
      // 如果视频小于 10MB 且分辨率不高，直接发原片，不浪费时间压缩
      final int fileSize = await File(inputPath).length();
      if (fileSize < 10 * 1024 * 1024 && min(oriWidth, oriHeight) <= kMaxShortSide) {
        debugPrint("🚀 视频较小 ($fileSize bytes)，跳过压缩，直传！");
        // 取个封面就走
        final File thumb = await vc.VideoCompress.getFileThumbnail(inputPath, quality: 60);
        return VideoMediaResult(
          videoFile: rawVideo,
          thumbnailFile: thumb,
          width: oriWidth,
          height: oriHeight,
          duration: (durationMs / 1000).round(),
          isOriginal: true,
        );
      }

      // 3.  FFmpeg 压缩命令构建
      final Directory tempDir = await getTemporaryDirectory();
      final String outputPath = '${tempDir.path}/cmp_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // 计算缩放：保持比例，让短边 = 720，-2 代表自动计算偶数宽度
      String scaleFilter = "";
      if (min(oriWidth, oriHeight) > kMaxShortSide) {
        if (oriWidth < oriHeight) {
          scaleFilter = "scale=$kMaxShortSide:-2"; // 宽是短边
        } else {
          scaleFilter = "scale=-2:$kMaxShortSide"; // 高是短边
        }
      } else {
        scaleFilter = "scale=-2:-2"; // 不缩放
      }

      // 命令详解：H.264编码 + CRF26质量 + 24帧 + 缩放 + AAC音频 + FastStart(边下边播)
      final String command =
          '-i "$inputPath" '
          '-c:v libx264 -crf $kCrf -preset veryfast '
          '-r $kFps '
          '-vf "$scaleFilter" '
          '-c:a aac -b:a 128k '
          '-movflags +faststart '
          '-y "$outputPath"';

      debugPrint("🎬 FFmpeg 开始压缩: $command");

      // 4. 执行压缩
      final completer = Completer<bool>();
      FFmpegKit.executeAsync(
          command,
              (FFmpegSession session) async {
            final returnCode = await session.getReturnCode();
            if (ReturnCode.isSuccess(returnCode)) {
              completer.complete(true);
            } else {
              debugPrint("❌ FFmpeg 失败: ${await session.getOutput()}");
              completer.complete(false);
            }
          },
          null,
              (Statistics stats) {
            // 这里可以打日志看进度: stats.getTime() / durationMs
          }
      );

      final success = await completer.future;
      if (!success) return null;

      // 5. 再次取封面 (用压缩后的文件取，更准)
      final File thumbnailFile = await vc.VideoCompress.getFileThumbnail(outputPath, quality: 60);

      // 读取新文件信息
      final newInfo = await _getMediaInfo(outputPath);

      return VideoMediaResult(
        videoFile: XFile(outputPath),
        thumbnailFile: thumbnailFile,
        width: newInfo?['width'] ?? oriWidth,
        height: newInfo?['height'] ?? oriHeight,
        duration: (durationMs / 1000).round(),
        isOriginal: false,
      );

    } catch (e) {
      debugPrint("Process Error: $e");
      return null;
    }
  }

  /// 辅助方法：读取视频元数据
  static Future<Map<String, dynamic>?> _getMediaInfo(String path) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final info = session.getMediaInformation();
      if (info == null) return null;

      final streams = info.getStreams();
      final videoStream = streams.firstWhere((s) => s.getType() == 'video');

      return {
        'width': videoStream.getWidth() ?? 0,
        'height': videoStream.getHeight() ?? 0,
        'duration': (double.tryParse(info.getDuration() ?? "0")! * 1000).toInt(),
      };
    } catch (e) {
      return null;
    }
  }
}