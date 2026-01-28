import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

import '../../models/chat_ui_model.dart';
import '../../../img/app_image.dart';
import '../../services/media/video_playback_service.dart';
import '../../video_player_page.dart';

class VideoMsgBubble extends StatefulWidget {
  final ChatUiModel message;

  const VideoMsgBubble({super.key, required this.message});

  @override
  State<VideoMsgBubble> createState() => _VideoMsgBubbleState();
}

class _VideoMsgBubbleState extends State<VideoMsgBubble> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isInitializing = false;

  final _playbackService = VideoPlaybackService();

  @override
  void dispose() {
    if (_controller != null && _isPlaying) {
      _controller!.pause();
    }
    super.dispose();
  }

  /// 计算降采样宽度：根据屏占比和DPR计算真实的物理像素需求
  int _getCacheWidth(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dpr = MediaQuery.of(context).devicePixelRatio;
    return (screenWidth * 0.6 * dpr).toInt();
  }

  /// 核心逻辑：播放/暂停切换
  Future<void> _playVideo() async {
    if (_controller != null && _controller!.value.isInitialized) {
      setState(() {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
          _isPlaying = false;
        } else {
          _playbackService.requestPlay(_controller!);
          _controller!.play();
          _isPlaying = true;
        }
      });
      return;
    }

    setState(() => _isInitializing = true);

    final source = await _playbackService.getPlayableSource(widget.message);
    if (source.isEmpty) {
      setState(() => _isInitializing = false);
      return;
    }

    try {
      _controller = _playbackService.createController(source);
      await _controller!.initialize();
      _playbackService.requestPlay(_controller!);
      await _controller!.play();

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _isPlaying = true;
        });
      }

      _controller!.addListener(() {
        if (!mounted) return;
        if (_controller!.value.isInitialized &&
            _controller!.value.position >= _controller!.value.duration &&
            _isPlaying) {
          setState(() {
            _isPlaying = false;
            _controller!.seekTo(Duration.zero);
            _controller!.pause();
          });
        }
      });

    } catch (e) {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  void _openFullScreen() async {
    _controller?.pause();
    if (mounted) setState(() => _isPlaying = false);

    final source = await _playbackService.getPlayableSource(widget.message);

    // 全屏页也可以优先尝试用 resolvedThumbPath，没有再用 meta
    final String thumbSource = widget.message.resolvedThumbPath ??
        widget.message.meta?['thumb'] ??
        widget.message.meta?['remote_thumb'] ?? "";

    if (source.isNotEmpty) {
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => VideoPlayerPage(
            videoSource: source,
            heroTag: widget.message.id,
            thumbSource: thumbSource,
          ),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.message.meta ?? {};
    final int w = _parseInt(meta['w']) ?? 16;
    final int h = _parseInt(meta['h']) ?? 9;
    final double aspectRatio = (w / h).clamp(0.6, 1.8);
    final double maxWidth = 0.6.sw;
    final double height = maxWidth / aspectRatio;
    final String durationStr = _formatDuration(_parseInt(meta['duration']) ?? 0);

    final bool isSending = widget.message.status == MessageStatus.sending;

    //  性能优化：RepaintBoundary 隔离重绘
    return RepaintBoundary(
      child: Hero(
        tag: widget.message.id,
        child: Material(
          color: Colors.black, // 底色设为纯黑，防止透明穿透
          borderRadius: BorderRadius.circular(12.r),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: maxWidth,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ============================================
                // Layer 1: 封面渲染 ( 彻底移除了 FutureBuilder)
                // ============================================
                _buildThumbnail(maxWidth, height),

                // ============================================
                // Layer 2: 视频渲染层
                // ============================================
                if (_controller != null && _controller!.value.isInitialized)
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  ),

                // ============================================
                // Layer 3: 交互层 (全屏 GestureDetector)
                // ============================================
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isSending ? null : _playVideo,
                  onDoubleTap: isSending ? null : _openFullScreen,
                  child: Container(color: Colors.transparent),
                ),

                // ============================================
                // Layer 4: UI 状态展示 (Loading/Play Button/Duration)
                // ============================================
                _buildUIOverlays(isSending, durationStr),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ///  核心修改：同步构建封面 (No FutureBuilder) 
  Widget _buildThumbnail(double w, double h) {
    final msg = widget.message;
    final int cacheWidth = _getCacheWidth(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        // ------------------------------------------------
        // Level 1: 同步内存缩略图 (极速响应，解决黑屏)
        // ------------------------------------------------
        if (msg.previewBytes != null)
          Image.memory(
            msg.previewBytes!,
            width: w,
            height: h,
            cacheWidth: cacheWidth, // 内存降准
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),

        // ------------------------------------------------
        // Level 2 & 3: 预热好的物理路径 (同步读取，拒绝 IO 等待)
        // ------------------------------------------------
        if (msg.resolvedThumbPath != null && msg.resolvedThumbPath!.isNotEmpty)
          _buildResolvedImage(msg.resolvedThumbPath!, w, h, cacheWidth),
      ],
    );
  }

  /// 辅助方法：构建本地或网络图 (纯同步)
  Widget _buildResolvedImage(String path, double w, double h, int cacheWidth) {
    // A. 网络图
    if (path.startsWith('http') || path.startsWith('blob:')) {
      return AppCachedImage(path, width: w, height: h, fit: BoxFit.cover);
    }

    // B. 本地文件 (Service 已经确认过文件存在了，直接读)
    // 这里不再需要 FutureBuilder 去 AssetManager 查，因为 resolvedThumbPath 已经是查好的结果
    return Image.file(
      File(path),
      width: w,
      height: h,
      cacheWidth: cacheWidth, // 内存降准
      fit: BoxFit.cover,
      gaplessPlayback: true, // 防止重绘闪烁
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  // --- UI 覆盖层 (保持原样) ---
  Widget _buildUIOverlays(bool isSending, String durationStr) {
    return Stack(
      children: [
        if (isSending)
          Container(
            color: Colors.black26,
            child: Center(
              child: SizedBox(
                width: 24.w,
                height: 24.w,
                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            ),
          ),
        if (!isSending && !_isPlaying && !_isInitializing)
          Center(
            child: IgnorePointer(
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(Icons.play_arrow, color: Colors.white, size: 30.sp),
              ),
            ),
          ),
        if (_isInitializing && !isSending)
          Center(
            child: SizedBox(
              width: 30.w,
              height: 30.w,
              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ),
          ),
        if (!_isPlaying && !isSending)
          Positioned(
            bottom: 8.h,
            right: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(durationStr, style: TextStyle(color: Colors.white, fontSize: 10.sp)),
            ),
          ),
      ],
    );
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}