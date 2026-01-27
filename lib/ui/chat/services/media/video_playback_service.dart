import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../../models/chat_ui_model.dart';

class VideoPlaybackService {
  // 单例模式
  static final VideoPlaybackService _instance = VideoPlaybackService._internal();
  factory VideoPlaybackService() => _instance;
  VideoPlaybackService._internal();

  VideoPlayerController? _activeController;

  /// 1. 核心逻辑：获取可播放的源路径 (解析本地/网络兜底)
  String getPlayableSource(ChatUiModel message) {
    // 优先用本地路径
    if (!kIsWeb && message.localPath != null) {
      final file = File(message.localPath!);
      // 如果本地文件存在，直接返回
      if (file.existsSync()) {
        return message.localPath!;
      }
    }

    // 本地没了，或者是在 Web 端，用网络链接兜底
    if (message.content.startsWith('http')) {
      return message.content;
    }

    return ""; // 无效路径
  }

  /// 2. 核心逻辑：创建控制器 (统一入口)
  VideoPlayerController createController(String source) {
    if (source.startsWith('http')) {
      return VideoPlayerController.networkUrl(Uri.parse(source));
    } else {
      return VideoPlayerController.file(File(source));
    }
  }

  /// 3. 核心逻辑：请求独占播放 (暂停其他人)
  void requestPlay(VideoPlayerController newController) {
    // 如果当前有别的在播，且不是同一个，先暂停旧的
    if (_activeController != null &&
        _activeController != newController &&
        _activeController!.value.isPlaying) {
      _activeController!.pause();
    }
    _activeController = newController;
  }

  /// (可选) 停止所有播放
  void stopAll() {
    _activeController?.pause();
    _activeController = null;
  }
}