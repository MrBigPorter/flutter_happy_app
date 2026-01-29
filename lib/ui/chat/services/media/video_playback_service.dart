import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../../../../utils/asset/asset_manager.dart';
import '../../models/chat_ui_model.dart';
import '../../providers/chat_room_provider.dart';
import '../chat_action_service.dart';

class VideoPlaybackService {
  // 单例模式
  static final VideoPlaybackService _instance = VideoPlaybackService._internal();
  factory VideoPlaybackService() => _instance;
  VideoPlaybackService._internal();

  VideoPlayerController? _activeController;

  ///  核心重构：异步获取可播放源
  /// 支持从 Asset ID、内存缓存以及网络 URL 中进行三级解析
  Future<String> getPlayableSource(ChatUiModel message) async {
    // A. 优先查内存缓存 (秒开原片，为了发送瞬间的极致体验)
    final cachePath = ChatActionService.getPathFromCache(message.id);
    if (cachePath != null && File(cachePath).existsSync()) return cachePath;

    // B. 解析本地 Asset ID
    // 无论 iOS 沙盒路径如何变化，通过相对文件名 ID 永远能找回物理文件
    if (!kIsWeb && message.localPath != null) {
      final String? absPath = await AssetManager.getFullPath(message.localPath!, message.type);
      if (absPath != null && File(absPath).existsSync()) {
        return absPath;
      }
    }

    // C. 兜底使用网络 URL (content)
    if (message.content.startsWith('http')) {
      return message.content;
    }

    return ""; // 无效路径
  }

  /// 2. 统一创建控制器
  VideoPlayerController createController(String source) {
    if (source.startsWith('http') || source.startsWith('blob:')) {
      return VideoPlayerController.networkUrl(Uri.parse(source));
    } else {
      return VideoPlayerController.file(File(source));
    }
  }

  /// 3. 请求独占播放 (自动暂停当前正在播放的其他视频)
  void requestPlay(VideoPlayerController newController) {
    if (_activeController != null &&
        _activeController != newController &&
        _activeController!.value.isPlaying) {
      _activeController!.pause();
    }
    _activeController = newController;
  }

  void stopAll() {
    _activeController?.pause();
    _activeController = null;
  }
}