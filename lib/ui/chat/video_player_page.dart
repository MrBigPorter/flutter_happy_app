import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../img/app_image.dart';
import 'services/media/video_playback_service.dart';


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


    //  核心修改：不再盲目调用 Service，而是自己判断路径类型
    // 如果是本地文件，必须用 .file()，否则 iOS 必报 -12939 错误
    try {
      if (!kIsWeb && (widget.videoSource.startsWith('/') || widget.videoSource.startsWith('file://'))) {
        final f = File(widget.videoSource.replaceFirst('file://', ''));
        _controller = VideoPlayerController.file(f);
      } else {
        // 网络视频 (或 Web Blob)
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoSource));
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
            // ===========================================
            // Layer 1: 核心渲染层 (Hero 占位 + VideoPlayer)
            // ===========================================
            GestureDetector(
              onTap: _toggleControls,
              child: Center(
                // 核心修改：使用 Stack 叠加 Hero 占位图和真实播放器
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Hero 占位图层 (始终存在，作为背景)
                    // 当 _isInitialized 为 false 时，用户看到的是这个 Hero 飞过来的动画
                    Positioned.fill(
                      child: Hero(
                        tag: widget.heroTag,
                        // 占位图构建逻辑
                        child: _buildPlaceholderThumbnail(),
                      ),
                    ),

                    // 2. 真实视频层 (初始化完成后覆盖在上面)
                    if (_isInitialized)
                      AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),

                    // 注意：这里不需要再写 Loading 了，因为有 Hero 封面图垫底，
                    // 用户会觉得是在看封面，体验比转圈圈好得多。
                  ],
                ),
              ),
            ),

            // ===========================================
            // Layer 2: 返回按钮
            // ===========================================
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            // ===========================================
            // Layer 3: 大播放图标
            // ===========================================
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

            // ===========================================
            // Layer 4: 底部进度条
            // ===========================================
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

  //  新增：构建 Hero 占位缩略图
  // (逻辑与气泡里的一致，确保 Hero 动画平滑)
  Widget _buildPlaceholderThumbnail() {

    //  3. 核心修改：如果有 cachedThumbUrl，直接用 CachedNetworkImage 加载它
    // 这样能 100% 命中列表页的缓存，实现零延迟
    if (widget.cachedThumbUrl != null && widget.cachedThumbUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.cachedThumbUrl!,
        fit: BoxFit.contain,
        // 既然是缓存图，不需要再做淡入动画，直接显示
        fadeInDuration: Duration.zero,
        placeholder: (context, url) => Container(color: Colors.black),
      );
    }

    if (widget.thumbSource.isEmpty) {
      return const SizedBox.shrink();
    }

    //  核心修改 1: 优先处理本地绝对路径 (发送者视角)
    if (!kIsWeb && (widget.thumbSource.startsWith('/') || widget.thumbSource.startsWith('file://'))) {
      final f = File(widget.thumbSource.replaceFirst('file://', ''));
      if (f.existsSync()) {
        return Image.file(f, fit: BoxFit.contain);
      }
    }

    //  核心修改 2: 其他情况 (http, uploads/..., blob) 统统交给 AppCachedImage
    // 我们之前已经修复了 AppCachedImage，它会自动把 uploads/ 拼上域名
    return AppCachedImage(
      widget.thumbSource,
      fit: BoxFit.contain, // 保持比例
      enablePreview: false,
    );
  }
}