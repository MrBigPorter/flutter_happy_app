import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../img/app_image.dart';
import 'services/media/video_playback_service.dart';

//  CHANGED: 引入统一路径判断工具
import 'package:flutter_app/utils/media/media_path.dart';
import 'package:flutter_app/utils/asset/asset_manager.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoSource;
  final String heroTag;
  final String thumbSource;
  final String? cachedThumbUrl;

  const VideoPlayerPage({
    super.key,
    required this.videoSource,
    required this.heroTag,
    required this.thumbSource,
    this.cachedThumbUrl,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;

  bool _isInitialized = false;
  bool _isPlaying = true;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    // 🔥 利用 AssetManager 统一还原路径（它是同步的，不需要 await）
    final String src = AssetManager.getRuntimePath(widget.videoSource.trim());

    try {
      // 这里的判断逻辑变得非常清晰：只要不是 http/blob，就是本地文件
      if (!kIsWeb && !src.startsWith('http') && !src.startsWith('blob:')) {
        _controller = VideoPlayerController.file(File(src));
      } else {
        _controller = VideoPlayerController.networkUrl(Uri.parse(src));
      }

      await _controller.initialize();
      VideoPlaybackService().stopAll(); // 停止小窗播放
      await _controller.play();

      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint("❌ Full screen init failed: $e, Source: $src");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
        _showControls = true;
      } else {
        _controller.play();
        _isPlaying = true;
        _showControls = false;
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: _toggleControls,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Hero(
                        tag: widget.heroTag,
                        child: _buildPlaceholderThumbnail(),
                      ),
                    ),
                    if (_isInitialized)
                      AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            if (_isInitialized && !_isPlaying)
              IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 50),
                ),
              ),

            if (_isInitialized && (_showControls || !_isPlaying))
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _togglePlay,
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Colors.white,
                            bufferedColor: Colors.white24,
                            backgroundColor: Colors.grey,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderThumbnail() {
    // 优先使用缓存的 URL，如果没有则使用原始缩略图源
    final String? source = (widget.cachedThumbUrl?.isNotEmpty == true)
        ? widget.cachedThumbUrl
        : widget.thumbSource;

    if (source == null || source.isEmpty) return const SizedBox.shrink();

    // 🔥 直接交给 AppCachedImage，它内部已经处理了：
    // 1. AssetManager.getRuntimePath 还原绝对路径
    // 2. 判断 File 还是 Network
    // 3. 处理自动拼接的域名/uploads前缀
    return AppCachedImage(
      source,
      fit: BoxFit.contain,
      enablePreview: false,
    );
  }
}