import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

import '../../../../utils/media/media_path.dart';
import '../../models/chat_ui_model.dart';
import '../../../img/app_image.dart';
import '../../services/media/video_playback_service.dart';
import '../../video_player_page.dart';
import '../../services/chat_action_service.dart';

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
    if (_controller != null) {
      _controller!.pause();
      _controller!.dispose();
    }
    super.dispose();
  }

  /// 视频 URL：统一走 buildVideo（你现有策略）
  String _resolveNetworkUrl(String rawPath) {
    return UrlResolver.resolveVideo(rawPath);
  }

  /// 尽可能找到本地文件（避免在线播放失败）
  File? _findLocalFile() {
    if (kIsWeb) return null;

    // A: localPath
    final lp = widget.message.localPath;
    if (lp != null) {
      //  CHANGED
      final t = MediaPath.classify(lp);
      if (t == MediaPathType.localAbs || t == MediaPathType.fileUri) {
        final f = lp.startsWith('file://') ? File(Uri.parse(lp).toFilePath()) : File(lp);
        if (f.existsSync()) return f;
      }
    }

    // B: resolvedPath
    final rp = widget.message.resolvedPath;
    if (rp != null) {
      //  CHANGED
      final t = MediaPath.classify(rp);
      if (t == MediaPathType.localAbs || t == MediaPathType.fileUri) {
        final f = rp.startsWith('file://') ? File(Uri.parse(rp).toFilePath()) : File(rp);
        if (f.existsSync()) return f;
      }
    }

    // C: cache
    final cachedPath = ChatActionService.getPathFromCache(widget.message.id);
    if (cachedPath != null) {
      //  CHANGED
      final t = MediaPath.classify(cachedPath);
      if (t == MediaPathType.localAbs || t == MediaPathType.fileUri) {
        final f = cachedPath.startsWith('file://')
            ? File(Uri.parse(cachedPath).toFilePath())
            : File(cachedPath);
        if (f.existsSync()) return f;
      }
    }

    return null;
  }

  Future<void> _playVideo() async {
    // 已初始化：直接切换播放/暂停
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
      VideoPlayerController newController;

      final localFile = _findLocalFile();
      if (localFile != null) {
        newController = VideoPlayerController.file(localFile);
      } else {
        //  CHANGED: 选择远端源：优先 resolvedPath(若是远端)，否则 content
        String netSource = widget.message.content;
        final rp = widget.message.resolvedPath;

        if (rp != null && MediaPath.isRemote(rp)) {
          netSource = rp;
        }

        final url = _resolveNetworkUrl(netSource);

        //  CHANGED: 防呆：url 必须是远端（http/uploads/relative），否则不要走 networkUrl
        final t = MediaPath.classify(url);
        if (t == MediaPathType.localAbs || t == MediaPathType.fileUri) {
          throw ArgumentError('Video network url resolved to local path: $url');
        }

        newController = VideoPlayerController.networkUrl(Uri.parse(url));
      }

      // 如果之前有 controller，先释放（避免多实例造成黑屏/资源占用）
      _controller?.dispose();
      _controller = newController;

      await _controller!.initialize();
      _playbackService.requestPlay(_controller!);
      await _controller!.play();

      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _isPlaying = true;
      });

      _controller!.addListener(() {
        if (!mounted || _controller == null) return;
        final v = _controller!.value;
        if (v.isInitialized &&
            v.position >= v.duration &&
            _isPlaying) {
          setState(() {
            _isPlaying = false;
            _controller!.seekTo(Duration.zero);
            _controller!.pause();
          });
        }
      });
    } catch (e) {
      debugPrint('❌ [VideoMsg] play error: $e');
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  void _openFullScreen() {
    _controller?.pause();
    if (mounted) setState(() => _isPlaying = false);

    String finalSource = '';
    final localFile = _findLocalFile();

    if (localFile != null) {
      finalSource = localFile.path;
    } else {
      String netSource = widget.message.content;
      final rp = widget.message.resolvedPath;
      if (rp != null && MediaPath.isRemote(rp)) {
        netSource = rp;
      }
      finalSource = _resolveNetworkUrl(netSource);
    }

    final String thumbRaw = widget.message.resolvedThumbPath ??
        widget.message.meta?['thumb'] ??
        widget.message.meta?['remote_thumb'] ??
        '';

    //  2. 核心修正：手动计算列表页刚才渲染的 URL
    // 必须和 build 方法里计算 maxWidth 的逻辑一模一样！
    final meta = widget.message.meta ?? {};
    final int w = _parseInt(meta['w']) ?? 16;
    final int h = _parseInt(meta['h']) ?? 9;
    final double aspectRatio = (w / h).clamp(0.6, 1.8);
    final double maxWidth = 0.6.sw; //  列表页用的宽度

    String? cachedUrl;
    if (thumbRaw.isNotEmpty) {
      // 调用 ImageUrl.build 生成完全一致的 CDN 链接
      cachedUrl = UrlResolver.resolveImage(
        context,
        thumbRaw,
        logicalWidth: maxWidth, // 关键：宽度对齐
        quality: 50,            // 关键：质量对齐 (AppCachedImage 默认 50)
        fit: BoxFit.cover,      // 关键：裁剪对齐
        format: kIsWeb ? 'auto' : 'webp', // 关键：格式对齐
      );
    }

    if (finalSource.isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => VideoPlayerPage(
          videoSource: finalSource,
          heroTag: widget.message.id,
          thumbSource: thumbRaw,
          cachedThumbUrl: cachedUrl,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
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

    // 封面路径（thumb）
    final String? thumbPath = widget.message.resolvedThumbPath ??
        (meta['thumb'] != null && meta['thumb'].toString().isNotEmpty
            ? meta['thumb'].toString()
            : null) ??
        (meta['remote_thumb'] != null && meta['remote_thumb'].toString().isNotEmpty
            ? meta['remote_thumb'].toString()
            : null);

    // 关键：给封面 meta 补 blurHash（字段名兼容）
    final Map<String, dynamic> thumbMeta = {
      ...meta,
      'blurHash': meta['thumbBlurHash'] ??
          meta['thumb_blur_hash'] ??
          meta['blurHash'] ??
          meta['blur_hash'],
    };

    return RepaintBoundary(
      child: Hero(
        tag: widget.message.id,
        child: Material(
          //  不要纯黑 Material，当封面还没来时会“黑一下”
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: maxWidth,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                //  底层占位：你可以改成更浅（F5F5F5）
                Container(color: const Color(0xFF111111)),

                // Layer 1：发送中内存预览图（最先显示）
                if (widget.message.previewBytes != null &&
                    widget.message.previewBytes!.isNotEmpty)
                  Image.memory(
                    widget.message.previewBytes!,
                    width: maxWidth,
                    height: height,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),

                // Layer 2：封面（关键：不传 placeholder，让 AppCachedImage 自己出 blur/shimmer）
                if (thumbPath != null && thumbPath.isNotEmpty)
                  AppCachedImage(
                    thumbPath,
                    width: maxWidth,
                    height: height,
                    fit: BoxFit.cover,
                    enablePreview: false,
                    metadata: thumbMeta,
                    // 失败不显示红叉，避免盖住底层
                    error: const SizedBox.shrink(),
                    // 不要传 placeholder！否则 blur/shimmer 永远不显示
                    // placeholder: const SizedBox.shrink(),
                  ),

                // Layer 3：播放器（初始化后覆盖封面）
                if (_controller != null && _controller!.value.isInitialized)
                  SizedBox.expand( // 1. 强制撑满整个气泡容器
                    child: FittedBox(
                      fit: BoxFit.cover, // 2. 核心：像图片一样裁剪并填满，不留缝隙
                      child: SizedBox(
                        // 3. 必须指定视频的原始尺寸，FittedBox 才知道怎么缩放
                        width: _controller!.value.size.width,
                        height: _controller!.value.size.height,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  ),

                // Layer 4：交互
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isSending ? null : _playVideo,
                  onDoubleTap: isSending ? null : _openFullScreen,
                  child: Container(color: Colors.transparent),
                ),

                // Layer 5：UI overlays
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
          Container(
            color: Colors.black26,
            child: Center(
              child: SizedBox(
                width: 24.w,
                height: 24.w,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
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
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
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