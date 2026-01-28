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

  // 新增：本地封面“记忆锁”
  String? _latchedLocalThumb;

  @override
  void dispose() {
    if (_controller != null && _isPlaying) {
      _controller!.pause();
    }
    super.dispose();
  }

  //  核心逻辑：一旦发现有本地路径，立刻锁死
  void _checkLocalThumb() {
    final meta = widget.message.meta ?? {};
    final String current = meta['thumb'] ?? "";

    // 如果当前 thumb 是有效的本地路径（非 http），就把它缓存起来
    // 注意：blob: 是 Web 端的本地路径，也要算在内
    if (current.isNotEmpty && !current.startsWith('http')) {
      _latchedLocalThumb = current;
    }
  }

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

    final source = _playbackService.getPlayableSource(widget.message);
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
        if (_controller!.value.position >= _controller!.value.duration && _isPlaying) {
          setState(() {
            _isPlaying = false;
            _controller!.seekTo(Duration.zero);
            _controller!.pause();
          });
        }
      });

    } catch (e) {
      debugPrint("Inline video play failed: $e");
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  void _openFullScreen() {
    _controller?.pause();
    if (mounted) setState(() => _isPlaying = false);

    final source = _playbackService.getPlayableSource(widget.message);
    final meta = widget.message.meta ?? {};

    final String thumbSource = meta['thumb'] ?? "";

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

    //  优化1：使用安全解析，防止 double/string 导致的类型崩溃
    final int w = _parseInt(meta['w']) ?? 16;
    final int h = _parseInt(meta['h']) ?? 9;

    final double aspectRatio = (w / h).clamp(0.6, 1.8);
    final double maxWidth = 0.6.sw;
    final double height = maxWidth / aspectRatio;

    //  优化2：安全解析时长
    final int durationSec = _parseInt(meta['duration']) ?? 0;
    final String durationStr = _formatDuration(durationSec);
    //  关键修改：优先使用“记忆”中的本地路径
    // 即使数据库被 socket 改成了 http，只要 _latchedLocalThumb 有值，我们依然显示本地文件
    final String thumbSource = _latchedLocalThumb ?? meta['thumb'] ?? "";

    final bool isSending = widget.message.status == MessageStatus.sending;
    

    return Hero(
      tag: widget.message.id,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            width: maxWidth,
            height: height,
            color: Colors.black12,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildThumbnail(thumbSource, maxWidth, height),

                if (_controller != null && _controller!.value.isInitialized)
                  AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),

                GestureDetector(
                  onTap: isSending ? null : _playVideo,
                  onDoubleTap: isSending ? null : _openFullScreen,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),

                if (isSending)
                  Container(
                    color: Colors.black26,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ],
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
                      child: Text(
                        durationStr,
                        style: TextStyle(color: Colors.white, fontSize: 10.sp),
                      ),
                    ),
                  ),

                if (_isPlaying && _controller != null) ...[
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: GestureDetector(
                      onTap: _openFullScreen,
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Icon(Icons.fullscreen, color: Colors.white, size: 20.sp),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8.h,
                    left: 8.w,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isMuted = !_isMuted;
                          _controller!.setVolume(_isMuted ? 0 : 1.0);
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(
                          _isMuted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String source, double w, double h) {
    // 1. 定义网络图 (垫底用)
    // 如果 source 是网络地址，它就是主角；如果 source 是本地文件，它作为兜底（虽然本地文件不需要兜底）
    Widget networkLayer = const SizedBox.shrink();
    if (source.startsWith('http')) {
      networkLayer = AppCachedImage(source, width: w, height: h, fit: BoxFit.cover);
    }

    // 2. 定义本地图 (覆盖用)
    Widget? localLayer;

    // 尝试解析是否为本地文件
    // 注意：这里我们假设 source 可能是本地路径，也可能是 URL
    // 如果是 URL，localLayer 保持 null
    if (!kIsWeb && !source.startsWith('http') && source.isNotEmpty) {
      final File file = File(source);
      if (file.existsSync()) {
        localLayer = Image.file(
          file,
          width: w,
          height: h,
          fit: BoxFit.cover,
          gaplessPlayback: true, // 防止重绘闪烁的关键参数
        );
      }
    }

    // 3. 异步查找 AssetManager (终极本地兜底)
    // 如果 source 是相对路径 (如 "chat/video_thumb.jpg")，需要异步转绝对路径
    return Stack(
      fit: StackFit.expand,
      children: [
        // 层级 1: 网络图 (如果是 URL，显示这个；如果是本地路径，这层是空的)
        networkLayer,

        // 层级 2: 同步本地文件 (最快，这就是你图片气泡不闪的原因)
        if (localLayer != null) localLayer,

        // 层级 3: 异步 AssetManager (处理相对路径的情况)
        if (localLayer == null && !source.startsWith('http') && source.isNotEmpty)
          FutureBuilder<String?>(
            future: AssetManager.getFullPath(source, MessageType.image),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final path = snapshot.data!;
                // 再次检查是本地还是网络 (防止 AssetManager 返回 URL)
                if (kIsWeb || path.startsWith('http')) {
                  return AppCachedImage(path, width: w, height: h, fit: BoxFit.cover);
                }
                return Image.file(File(path), width: w, height: h, fit: BoxFit.cover);
              }
              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }

  //  辅助方法：安全解析 int (防止 double/string 报错)
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