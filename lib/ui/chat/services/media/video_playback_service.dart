import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../../../../utils/asset/asset_manager.dart';
import '../../models/chat_ui_model.dart';
import '../chat_action_service.dart';

class VideoPlaybackService {
  // Singleton Pattern
  static final VideoPlaybackService _instance = VideoPlaybackService._internal();
  factory VideoPlaybackService() => _instance;
  VideoPlaybackService._internal();

  VideoPlayerController? _activeController;

  /// Core Refactoring: Asynchronous resolution of playable sources.
  /// Supports tiered resolution from Memory Cache, Asset IDs, and Network URLs.
  Future<String> getPlayableSource(ChatUiModel message) async {
    // Tier A: Prioritize memory cache for instant playback during the sending phase.
    final cachePath = ChatActionService.getPathFromCache(message.id);
    if (cachePath != null && File(cachePath).existsSync()) return cachePath;

    // Tier B: Resolve Local Asset ID.
    // Facilitates persistent file access regardless of iOS sandbox path shifts.
    if (!kIsWeb && message.localPath != null) {
      final String? absPath = await AssetManager.getFullPath(message.localPath!, message.type);
      if (absPath != null && File(absPath).existsSync()) {
        return absPath;
      }
    }

    // Tier C: Fallback to Network URL (content).
    if (message.content.startsWith('http')) {
      return message.content;
    }

    return ""; // Invalid path
  }

  /// Unified Controller Creation.
  VideoPlayerController createController(String source) {
    if (source.startsWith('http') || source.startsWith('blob:')) {
      // Configures Range headers to support HTTP 206 Partial Content (Nginx optimization).
      // Enables instant start by only downloading initial segments and partial seeking.
      return VideoPlayerController.networkUrl(
        Uri.parse(source),
        httpHeaders: const {'Range': 'bytes=0-'},
      );
    } else {
      return VideoPlayerController.file(File(source));
    }
  }

  /// Requests Exclusive Playback: Automatically pauses any other active video streams.
  void requestPlay(VideoPlayerController newController) {
    if (_activeController != null &&
        _activeController != newController &&
        _activeController!.value.isPlaying) {
      _activeController!.pause();
    }
    _activeController = newController;
  }

  /// Stops all active playback instances.
  void stopAll() {
    _activeController?.pause();
    _activeController = null;
  }
}