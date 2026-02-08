import 'dart:async'; // 引入 Timer
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../img/app_image.dart';
import 'services/media/video_playback_service.dart';
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
  final VideoPlaybackService _playbackService = VideoPlaybackService();

  bool _isInitialized = false;
  bool _isPlaying = true;
  bool _showControls = true; // 默认显示控制条
  Timer? _hideTimer; // 自动隐藏计时器

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    // 1. 还原路径 (这一步保留，很棒)
    final String src = AssetManager.getRuntimePath(widget.videoSource.trim());

    try {
      // Service 内部会自动添加 {'Range': 'bytes=0-'} 头
      // 从而激活后端的流式缓冲 (P2 任务闭环)
      _controller = _playbackService.createController(src);

      await _controller.initialize();

      // 独占播放逻辑
      _playbackService.requestPlay(_controller);

      await _controller.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _startHideTimer(); // 开始倒计时隐藏 UI
        });
      }
    } catch (e) {
      debugPrint(" Full screen init failed: $e, Source: $src");
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // 3秒无操作自动隐藏
  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
        _showControls = true; // 暂停时强制显示
        _hideTimer?.cancel();
      } else {
        _controller.play();
        _isPlaying = true;
        _startHideTimer(); // 播放时重新倒计时
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls && _isPlaying) {
      _startHideTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: _toggleControls, // 点击全屏切换 UI
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ===========================
              // 1. 视频层 (含 Hero 占位)
              // ===========================
              Center(
                child: Hero(
                  tag: widget.heroTag,
                  child: AspectRatio(
                    // 如果视频还没初始化，用 16:9 或者封面的比例占位
                    aspectRatio: _isInitialized ? _controller.value.aspectRatio : 16/9,
                    child: Stack(
                      children: [
                        // 底层：占位图 (AppCachedImage)
                        // 当视频加载出来后，它会被视频覆盖，或者你可以选择 opacity 动画隐藏它
                        Positioned.fill(
                          child: _buildPlaceholderThumbnail(),
                        ),

                        // 顶层：视频
                        if (_isInitialized)
                          VideoPlayer(_controller),
                      ],
                    ),
                  ),
                ),
              ),

              // ===========================
              // 2. 关闭按钮 (始终显示或随控制层显示)
              // ===========================
              if (_showControls)
                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

              // ===========================
              // 3. 中间的大播放按钮 (暂停时显示)
              // ===========================
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

              // ===========================
              // 4. 底部控制栏 (进度条)
              // ===========================
              if (_isInitialized && _showControls)
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
                        //  核心：进度条
                        Expanded(
                          child: VideoProgressIndicator(
                            _controller,
                            allowScrubbing: true, // 允许拖拽！
                            colors: const VideoProgressColors(
                              playedColor: Colors.white,
                              bufferedColor: Colors.white24, // 这里会显示流式缓冲进度
                              backgroundColor: Colors.grey,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 简单显示总时长
                        Text(
                          _formatDuration(_controller.value.duration),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  Widget _buildPlaceholderThumbnail() {
    final String? source = (widget.cachedThumbUrl?.isNotEmpty == true)
        ? widget.cachedThumbUrl
        : widget.thumbSource;

    if (source == null || source.isEmpty) return const SizedBox.shrink();

    return AppCachedImage(
      source,
      fit: BoxFit.contain,
      enablePreview: false,
    );
  }
}