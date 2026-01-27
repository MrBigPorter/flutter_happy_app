import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'services/media/video_playback_service.dart'; // 引入我们刚写的服务

class VideoPlayerPage extends StatefulWidget {
  final String videoSource; // 接收处理好的路径 (本地或网络)

  const VideoPlayerPage({super.key, required this.videoSource});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;

  // 状态变量
  bool _isInitialized = false;
  bool _isPlaying = true;       // 默认进入就播放
  bool _showControls = false;   // 控制条显隐状态

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    // 1.  使用 Service 创建控制器 (核心修改)
    // Service 会自动判断是 file(...) 还是 networkUrl(...)
    _controller = VideoPlaybackService().createController(widget.videoSource);

    try {
      await _controller.initialize();

      // 2.  停止列表里的气泡播放 (核心修改)
      // 进入全屏后，为了防止声音冲突，强制暂停外部的小窗播放
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
    // 退出全屏时销毁控制器
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
        _showControls = true; // 暂停时强制显示控制条
      } else {
        _controller.play();
        _isPlaying = true;
        _showControls = false; // 播放时隐藏，沉浸式体验
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
      backgroundColor: Colors.black, // 沉浸式黑色背景
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ===========================================
            // Layer 1: 视频渲染层 + 点击交互
            // ===========================================
            GestureDetector(
              onTap: _toggleControls, // 点击屏幕任意位置切换控制条
              child: Center(
                child: _isInitialized
                    ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                )
                    : const CircularProgressIndicator(color: Colors.white),
              ),
            ),

            // ===========================================
            // Layer 2: 返回按钮 (始终显示)
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
            // Layer 3: 中间的大播放图标 (暂停时显示)
            // ===========================================
            if (_isInitialized && !_isPlaying)
              IgnorePointer( // 让点击穿透，方便用户点击任意位置恢复播放
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),

            // ===========================================
            // Layer 4: 底部进度条控制栏
            // ===========================================
            if (_isInitialized && (_showControls || !_isPlaying))
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54, // 半透明底，看字幕更清楚
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // 左侧小播放/暂停按钮
                      GestureDetector(
                        onTap: _togglePlay,
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // 进度条 (支持拖拽)
                      Expanded(
                        child: VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true, // 允许拖动进度条
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
}