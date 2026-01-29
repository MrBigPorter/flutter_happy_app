import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

import '../../models/chat_ui_model.dart';
import '../../../img/app_image.dart';
import '../../services/media/video_playback_service.dart';
import '../../video_player_page.dart';
import '../../../../utils/image_url.dart';
import '../../services/chat_action_service.dart'; // 必须引入，用于查找缓存

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

  // 1. 生成网络链接 (HTTPS 强制)
  String _resolveNetworkUrl(String rawPath) {
    if (rawPath.startsWith('http')) {
      if (!kIsWeb && rawPath.startsWith('http://')) {
        return rawPath.replaceFirst('http://', 'https://');
      }
      return rawPath;
    }
    String gw = ImageUrl.gateway(useProd: kReleaseMode);
    if (!kIsWeb && gw.startsWith('http://')) {
      gw = gw.replaceFirst('http://', 'https://');
    }
    final clean = rawPath.startsWith('/') ? rawPath.substring(1) : rawPath;
    return '$gw/$clean';
  }

  // 2.  核心：无脑寻找本地文件 (确保播放不报错)
  File? _findLocalFile() {
    if (kIsWeb) return null;

    // 来源 A: localPath
    if (widget.message.localPath != null && widget.message.localPath!.startsWith('/')) {
      final f = File(widget.message.localPath!);
      if (f.existsSync()) return f;
    }

    // 来源 B: resolvedPath
    if (widget.message.resolvedPath != null && widget.message.resolvedPath!.startsWith('/')) {
      final f = File(widget.message.resolvedPath!);
      if (f.existsSync()) return f;
    }

    // 来源 C: 缓存
    final cachedPath = ChatActionService.getPathFromCache(widget.message.id);
    if (cachedPath != null && cachedPath.startsWith('/')) {
      final f = File(cachedPath);
      if (f.existsSync()) return f;
    }

    return null;
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

    try {
      VideoPlayerController? newController;

      //  第一步：判定本地文件
      final File? localFile = _findLocalFile();

      if (localFile != null) {
        debugPrint("🎬 [VideoMsg] 模式: 本地文件 | 路径: ${localFile.path}");
        newController = VideoPlayerController.file(localFile);
      } else {
        //  第二步：网络播放
        debugPrint("🌐 [VideoMsg] 模式: 网络流 | 原始: ${widget.message.content}");

        String netSource = widget.message.content;
        if (widget.message.resolvedPath != null && widget.message.resolvedPath!.startsWith('http')) {
          netSource = widget.message.resolvedPath!;
        }

        final secureUrl = _resolveNetworkUrl(netSource);
        newController = VideoPlayerController.networkUrl(Uri.parse(secureUrl));
      }

      _controller = newController;
      await _controller!.initialize();
      _playbackService.requestPlay(_controller!);
      await _controller!.play();

      if (mounted) setState(() { _isInitializing = false; _isPlaying = true; });

      _controller!.addListener(() {
        if (!mounted) return;
        if (_controller!.value.isInitialized &&
            _controller!.value.position >= _controller!.value.duration &&
            _isPlaying) {
          setState(() { _isPlaying = false; _controller!.seekTo(Duration.zero); _controller!.pause(); });
        }
      });

    } catch (e) {
      debugPrint("❌ [VideoMsg] 播放报错: $e");
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  void _openFullScreen() {
    _controller?.pause();
    if (mounted) setState(() => _isPlaying = false);

    String finalSource = "";
    final File? localFile = _findLocalFile();

    if (localFile != null) {
      finalSource = localFile.path;
    } else {
      finalSource = _resolveNetworkUrl(widget.message.content);
    }

    final String thumbRaw = widget.message.resolvedThumbPath ??
        widget.message.meta?['thumb'] ??
        widget.message.meta?['remote_thumb'] ?? "";

    if (finalSource.isNotEmpty) {
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => VideoPlayerPage(
            videoSource: finalSource,
            heroTag: widget.message.id,
            thumbSource: thumbRaw,
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

    // 获取封面路径
    final String? thumbPath = widget.message.resolvedThumbPath ??
        (meta['thumb'] != null && meta['thumb'] != '' ? meta['thumb'] : null) ??
        (meta['remote_thumb'] != null && meta['remote_thumb'] != '' ? meta['remote_thumb'] : null);

    return RepaintBoundary(
      child: Hero(
        tag: widget.message.id,
        child: Material(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12.r),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: maxWidth,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                //  核心修复：封面双层渲染 (解决上传中黑屏)
                // Layer 1: 内存预览图 (底图，最优先显示)
                if (widget.message.previewBytes != null && widget.message.previewBytes!.isNotEmpty)
                  Image.memory(
                    widget.message.previewBytes!,
                    width: maxWidth,
                    height: height,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),

                // Layer 2: 高清封面 (等上传成功后覆盖上来)
                if (thumbPath != null && thumbPath.isNotEmpty)
                  AppCachedImage(
                    thumbPath,
                    width: maxWidth,
                    height: height,
                    fit: BoxFit.cover,
                    enablePreview: false,
                    // 重要：如果加载失败或正在加载，不要显示红叉，保持透明，让底下的内存图露出来
                    error: const SizedBox.shrink(),
                    placeholder: const SizedBox.shrink(),
                  ),

                // Layer 3: 播放器
                if (_controller != null && _controller!.value.isInitialized)
                  Center(child: AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!))),

                // Layer 4: 交互
                GestureDetector(behavior: HitTestBehavior.opaque, onTap: isSending ? null : _playVideo, onDoubleTap: isSending ? null : _openFullScreen, child: Container(color: Colors.transparent)),

                // Layer 5: UI
                _buildUIOverlays(isSending, durationStr),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUIOverlays(bool isSending, String durationStr) {
    return Stack(
      children: [
        if (isSending)
          Container(color: Colors.black26, child: Center(child: SizedBox(width: 24.w, height: 24.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))),
        if (!isSending && !_isPlaying && !_isInitializing)
          Center(child: IgnorePointer(child: Container(padding: EdgeInsets.all(12.r), decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: Icon(Icons.play_arrow, color: Colors.white, size: 30.sp)))),
        if (_isInitializing && !isSending)
          Center(child: SizedBox(width: 30.w, height: 30.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3))),
        if (!_isPlaying && !isSending)
          Positioned(bottom: 8.h, right: 8.w, child: Container(padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h), decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(4.r)), child: Text(durationStr, style: TextStyle(color: Colors.white, fontSize: 10.sp)))),
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