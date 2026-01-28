import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

import '../../models/chat_ui_model.dart';
import '../../../../utils/asset/asset_manager.dart';
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
  bool _isMuted = false;

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
    // 气泡最大宽度是 0.6.sw，乘以设备像素比得到真实物理像素
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
    final meta = widget.message.meta ?? {};
    String thumbSource = meta['thumb'] ?? meta['remote_thumb'] ?? "";

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

    String thumbSource = meta['thumb'] ?? "";
    if (thumbSource.isEmpty) thumbSource = meta['remote_thumb'] ?? "";

    final bool isSending = widget.message.status == MessageStatus.sending;

    return RepaintBoundary( //  性能优化：隔离重绘区域
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
                // Layer 1: 三级封面逻辑 (同步预览 -> 异步本地 -> 网络兜底)
                // ============================================
                _buildThumbnail(thumbSource, maxWidth, height),

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

  /// 封面构建器：实现三级视觉缓冲
  Widget _buildThumbnail(String source, double w, double h) {
    final cacheWidth = _getCacheWidth(context);
    

    return Stack(
      fit: StackFit.expand,
      children: [
        // Level 1: 同步内存缩略图 (解决瞬间黑屏的关键)
        if (widget.message.previewBytes != null)
          Image.memory(
            widget.message.previewBytes!,
            width: w,
            height: h,
            cacheWidth: cacheWidth, //  内存降准优化
            fit: BoxFit.cover,
          ),

        // Level 2 & 3: 异步/网络封面
        _buildAsyncImageLayer(source, w, h, cacheWidth),
      ],
    );
  }

  Widget _buildAsyncImageLayer(String source, double w, double h, int cacheWidth) {
    if (source.isEmpty) return const SizedBox.shrink();

    // 网络源处理
    if (source.startsWith('http') || source.startsWith('blob:')) {
      return AppCachedImage(source, width: w, height: h, fit: BoxFit.cover);
    }

    // 本地源异步解析
    return FutureBuilder<String?>(
      future: AssetManager.getFullPath(source, MessageType.image),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final path = snapshot.data!;
          if (kIsWeb || path.startsWith('http')) {
            return AppCachedImage(path, width: w, height: h, fit: BoxFit.cover);
          }

          final file = File(path);
          if (file.existsSync()) {
            return Image.file(
              file,
              width: w,
              height: h,
              cacheWidth: cacheWidth, //  内存降准优化
              fit: BoxFit.cover,
              gaplessPlayback: true, // 防止路径切换时闪烁
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            );
          }
        }
        // 解析中返回 shrink，因为底层有 Image.memory 垫着，不会黑屏
        return const SizedBox.shrink();
      },
    );
  }

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