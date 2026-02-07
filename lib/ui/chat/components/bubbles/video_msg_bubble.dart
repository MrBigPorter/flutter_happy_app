import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_app/ui/chat/video_player_page.dart';
import 'package:flutter_app/ui/img/app_image.dart';
import 'package:flutter_app/utils/asset/asset_manager.dart';

// 全局互斥锁
final ValueNotifier<String?> _playingMsgId = ValueNotifier(null);

class VideoMsgBubble extends StatefulWidget {
  final ChatUiModel message;
  final bool isMe;

  const VideoMsgBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  State<VideoMsgBubble> createState() => _VideoMsgBubbleState();
}

class _VideoMsgBubbleState extends State<VideoMsgBubble> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _playingMsgId.addListener(_onGlobalPlayChanged);
  }

  @override
  void dispose() {
    _playingMsgId.removeListener(_onGlobalPlayChanged);
    _disposeController();
    super.dispose();
  }

  void _onGlobalPlayChanged() {
    if (_playingMsgId.value != widget.message.id) {
      if (_controller != null) {
        _disposeController();
        if (mounted) setState(() {});
      }
    }
  }

  void _disposeController() {
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    _isPlaying = false;
    _isLoading = false;
  }

  // 优化 1：利用 AssetManager 极简解析路径
  Future<String> _resolvePlayableUrl() async {
    final String? local = widget.message.localPath;

    if (kDebugMode) {
      debugPrint(" [Video Debug] ID: ${widget.message.id} | RawLocal: $local");
    }

    // 1. 检查 AssetManager 是否认为本地文件有效（同步检查）
    if (AssetManager.existsSync(local)) {
      final String fullPath = AssetManager.getRuntimePath(local);
      debugPrint("   [Video] 命中本地文件: $fullPath");
      return fullPath;
    }

    // 2. 如果是 Web 端的 Blob (虽然 AssetManager 也会处理，但这里显式处理下逻辑更清晰)
    if (kIsWeb && local != null && local.startsWith('blob:')) {
      debugPrint("    [Video] 命中 Web Blob: $local");
      return local;
    }

    // 3. 兜底：走网络
    final String remoteUrl = UrlResolver.resolveVideo(widget.message.content);
    debugPrint("    [Video] 本地缺失或无效，走网络: $remoteUrl");
    return remoteUrl;
  }

  // 优化 2：播放逻辑同步化（因为路径解析变快了）
  Future<void> _togglePlay() async {
    if (_isPlaying && _controller != null) {
      _controller!.pause();
      setState(() => _isPlaying = false);
      return;
    }

    if (_controller != null && _controller!.value.isInitialized) {
      _playingMsgId.value = widget.message.id;
      await _controller!.play();
      setState(() => _isPlaying = true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = await _resolvePlayableUrl();
      if (url.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      _playingMsgId.value = widget.message.id;

      // 判断是网络还是本地（AssetManager 统一了路径格式，判断变得很简单）
      if (kIsWeb || url.startsWith('http') || url.startsWith('blob:')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        _controller = VideoPlayerController.file(File(url));
      }

      await _controller!.initialize();
      // ... 监听和播放逻辑保持不变 ...
      await _controller!.play();
      if (mounted) setState(() { _isPlaying = true; _isLoading = false; });

    } catch (e) {
      debugPrint("❌ Video init failed: $e");
      _disposeController();
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _openFullScreen() async {
    _controller?.pause();
    if (mounted) setState(() => _isPlaying = false);

    //  全屏也需要异步解析路径
    final url = await _resolvePlayableUrl();
    if (url.isEmpty || !mounted) return;

    final remoteThumb = UrlResolver.resolveImage(context, widget.message.meta?['thumb']);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerPage(
          videoSource: url,
          heroTag: 'video_${widget.message.id}',
          thumbSource: widget.message.localPath ?? widget.message.meta?['thumb'] ?? '',
          cachedThumbUrl: remoteThumb,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.message.previewBytes ?? widget.message.meta?['thumb'];
    

    final double w = (widget.message.meta?['w'] ?? 16).toDouble();
    final double h = (widget.message.meta?['h'] ?? 9).toDouble();
    final double aspectRatio = (w / h).clamp(0.6, 1.8);

    final bool showVideo = _controller != null &&
        _controller!.value.isInitialized &&
        _isPlaying;

    return GestureDetector(
      onTap: _togglePlay,
      onDoubleTap: _openFullScreen,
      child: Container(
        width: 240,
        height: 240 / aspectRatio,
        constraints: const BoxConstraints(maxWidth: 240, maxHeight: 320),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          color: Colors.black,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. 封面图
              if (!showVideo)
                Positioned.fill(
                  child: AppCachedImage(
                    source,
                    fit: BoxFit.cover,
                    previewBytes: widget.message.previewBytes,
                    metadata: widget.message.meta,
                    placeholder: Container(color: Colors.black12),
                  ),
                ),

              // 2. 视频层 (Cover)
              if (showVideo)
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                ),

              // 3. UI 状态
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              else if (!_isPlaying)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                ),

              // 4. 时长
              if (!_isPlaying && widget.message.duration != null)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(widget.message.duration!),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),

              // 5. 发送状态
              if (widget.message.status == MessageStatus.sending)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final int min = seconds ~/ 60;
    final int sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}