import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../img/app_image.dart';
import 'services/media/video_playback_service.dart';

//  CHANGED: 引入统一路径判断工具
import 'package:flutter_app/utils/media/media_path.dart';

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
    //】 CHANGED: trim + 统一判断类型
    final src = widget.videoSource.trim();
    final t = MediaPath.classify(src);

    //  核心修改：不再盲目调用 Service，而是自己判断路径类型
    // 如果是本地文件，必须用 .file()，否则 iOS 必报 -12939 错误
    try {
      if (!kIsWeb && (t == MediaPathType.localAbs || t == MediaPathType.fileUri)) {
        //  CHANGED: file:// 统一转成本地路径
        final filePath = src.startsWith('file://') ? Uri.parse(src).toFilePath() : src;
        final f = File(filePath);
        _controller = VideoPlayerController.file(f);
      } else {
        //  CHANGED: 防呆：这里必须是远端/可 parse 的 URI（http/blob 等）
        _controller = VideoPlayerController.networkUrl(Uri.parse(src));
      }

      await _controller.initialize();

      // 停止列表里的小窗播放
      VideoPlaybackService().stopAll();

      await _controller.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Full screen init failed: $e");
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
    //  CHANGED: cachedThumbUrl 也必须分流（可能传进来的是本地路径）
    final cached = widget.cachedThumbUrl?.trim();
    if (cached != null && cached.isNotEmpty) {
      final ct = MediaPath.classify(cached);
      if (!kIsWeb && (ct == MediaPathType.localAbs || ct == MediaPathType.fileUri)) {
        final filePath = cached.startsWith('file://') ? Uri.parse(cached).toFilePath() : cached;
        final f = File(filePath);
        if (f.existsSync()) return Image.file(f, fit: BoxFit.contain);
      }

      // 远端才用 CachedNetworkImage
      return CachedNetworkImage(
        imageUrl: cached,
        fit: BoxFit.contain,
        fadeInDuration: Duration.zero,
        placeholder: (context, url) => Container(color: Colors.black),
      );
    }

    final thumb = widget.thumbSource.trim(); //  CHANGED
    if (thumb.isEmpty) return const SizedBox.shrink();

    //  CHANGED: 本地缩略图分流用 MediaPath
    final tt = MediaPath.classify(thumb);
    if (!kIsWeb && (tt == MediaPathType.localAbs || tt == MediaPathType.fileUri)) {
      final filePath = thumb.startsWith('file://') ? Uri.parse(thumb).toFilePath() : thumb;
      final f = File(filePath);
      if (f.existsSync()) {
        return Image.file(f, fit: BoxFit.contain);
      }
    }

    // 其他情况交给 AppCachedImage（它内部已经用 MediaPath 分流 + uploads 拼接）
    return AppCachedImage(
      thumb,
      fit: BoxFit.contain,
      enablePreview: false,
    );
  }
}