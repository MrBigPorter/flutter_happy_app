import 'dart:io';
import 'package:video_compress/video_compress.dart';
import 'package:image_picker/image_picker.dart';

class VideoMediaResult {
  final XFile videoFile;     // 压缩后的视频文件
  final File thumbnailFile;  // 视频首帧图
  final int width;           // 视频宽
  final int height;          // 视频高
  final int duration;        // 时长(秒)

  VideoMediaResult({
    required this.videoFile,
    required this.thumbnailFile,
    required this.width,
    required this.height,
    required this.duration,
  });
}

class VideoProcessor {
  static Future<VideoMediaResult?> process(XFile rawVideo) async {
    try {
      // 1. 获取缩略图 (用于秒显预览)
      final thumbnail = await VideoCompress.getFileThumbnail(
        rawVideo.path,
        quality: 50,
      );

      // 2. 压缩视频 (微信/Messenger 级别压缩)
      final info = await VideoCompress.compressVideo(
        rawVideo.path,
        quality: VideoQuality.DefaultQuality,
        includeAudio: true,
      );

      if (info == null || info.path == null) return null;

      return VideoMediaResult(
        videoFile: XFile(info.path!),
        thumbnailFile: thumbnail,
        width: info.width?.toInt() ?? 0,
        height: info.height?.toInt() ?? 0,
        duration: (info.duration ?? 0 / 1000).round(),
      );
    } catch (e) {
      return null;
    } finally {
      // 清理 video_compress 临时文件
      VideoCompress.deleteAllCache();
    }
  }
}