import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

// 请确保这些 import 路径对应你项目的实际位置
import '../../models/chat_ui_model.dart';
import '../../../../utils/asset/asset_manager.dart';
import '../../../img/app_image.dart'; // 你的 AppCachedImage 组件
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

  // 获取服务实例
  final _playbackService = VideoPlaybackService();

  //  注意：这里删除了之前添加的 _latchedLocalThumb 状态锁
  // 声明式架构下不再需要它。

  @override
  void dispose() {
    if (_controller != null && _isPlaying) {
      _controller!.pause();
    }
    super.dispose();
  }

  /// 核心逻辑：初始化并播放
  Future<void> _playVideo() async {
    // 1. 如果已经初始化，直接切换状态
    if (_controller != null && _controller!.value.isInitialized) {
      setState(() {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
          _isPlaying = false;
        } else {
          // 请求独占播放
          _playbackService.requestPlay(_controller!);
          _controller!.play();
          _isPlaying = true;
        }
      });
      return;
    }

    // 2. 如果没初始化，开始加载
    setState(() => _isInitializing = true);

    final source = await _playbackService.getPlayableSource(widget.message);
    if (source.isEmpty) {
      setState(() => _isInitializing = false);
      debugPrint("Video source is empty, cannot play.");
      return;
    }

    try {
      // 3. 使用 Service 创建控制器
      _controller = _playbackService.createController(source);

      await _controller!.initialize();
      // 4. 使用 Service 请求独占
      _playbackService.requestPlay(_controller!);
      await _controller!.play();

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _isPlaying = true;
        });
      }

      // 监听播放结束，恢复按钮状态
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
      debugPrint("Inline video play failed: $e");
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  /// 跳转全屏
  void _openFullScreen() async {
    _controller?.pause();
    if (mounted) setState(() => _isPlaying = false);

    final source = await _playbackService.getPlayableSource(widget.message);
    final meta = widget.message.meta ?? {};

    // 获取用于全屏预览的封面源 (逻辑与气泡渲染一致)
    String thumbSource = meta['thumb'] ?? "";
    final String remoteThumb = meta['remote_thumb'] ?? "";
    if (thumbSource.isEmpty && remoteThumb.isNotEmpty) {
      thumbSource = remoteThumb;
    }

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

    final int durationSec = _parseInt(meta['duration']) ?? 0;
    final String durationStr = _formatDuration(durationSec);

    //  核心重构点：声明式源选择逻辑
    // 1. 优先尝试 'thumb' (它现在应该是本地 AssetID 或旧数据的 URL)
    String thumbSource = meta['thumb'] ?? "";
    // 2. 如果 'thumb' 为空，说明没有本地封面，尝试用 'remote_thumb' 兜底
    // (这种情况常见于：用户清除了缓存，或者这是接收到的消息)
    final String remoteThumb = meta['remote_thumb'] ?? "";

    if (thumbSource.isEmpty && remoteThumb.isNotEmpty) {
      thumbSource = remoteThumb;
    }

    final bool isSending = widget.message.status == MessageStatus.sending;

    return Hero(
      tag: widget.message.id,
      // 使用 Material 包裹以支持墨水波纹效果，并设置底色防穿透
      child: Material(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12.r),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: maxWidth,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ============================================
              // Layer 1: 封面图 (接入声明式构建器)
              // ============================================
              _buildThumbnail(thumbSource, maxWidth, height),

              // ============================================
              // Layer 2: 视频层 (只有初始化成功才显示)
              // ============================================
              if (_controller != null && _controller!.value.isInitialized)
                AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),

              // ============================================
              // Layer 3: 交互遮罩 (处理点击)
              // ============================================
              GestureDetector(
                behavior: HitTestBehavior.opaque, // 确保透明区域也能响应点击
                onTap: isSending ? null : _playVideo,
                onDoubleTap: isSending ? null : _openFullScreen,
                child: Container(color: Colors.transparent),
              ),

              // ============================================
              // Layer 4: UI 状态展示 (严格互斥)
              // ============================================

              // A. 发送中状态 (遮罩 + Loading)
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

              // B. 播放按钮 (非发送、非播放、非初始化时显示)
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

              // C. 视频缓冲 Loading (初始化中且非发送)
              if (_isInitializing && !isSending)
                Center(
                  child: SizedBox(
                    width: 30.w,
                    height: 30.w,
                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  ),
                ),

              // D. 时长角标
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

              // E. 全屏/静音按钮 (仅播放状态显示)
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
    );
  }

  //  核心重构点：声明式封面构建器
  // 不再依赖 Stack 遮挡，而是根据传入的 source 类型直接决定渲染方式
  Widget _buildThumbnail(String source, double w, double h) {
    if (source.isEmpty) return const SizedBox.shrink();

    // 1. 如果是网络 URL (包括 blob:) -> 直接使用缓存网络图组件
    if (source.startsWith('http') || source.startsWith('blob:')) {
      return AppCachedImage(source, width: w, height: h, fit: BoxFit.cover);
    }

    // 2. 如果是本地 Asset ID -> 异步解析绝对路径后渲染
    // 注意：这里不再需要 Stack，因为源已经确定
    return FutureBuilder<String?>(
      future: AssetManager.getFullPath(source, MessageType.image),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final path = snapshot.data!;

          // 双重检查：万一 AssetManager 解析出的是 Web URL
          if (kIsWeb || path.startsWith('http')) {
            return AppCachedImage(path, width: w, height: h, fit: BoxFit.cover);
          }

          // 移动端物理文件检查
          final file = File(path);
          if (file.existsSync()) {
            return Image.file(
              file,
              width: w,
              height: h,
              fit: BoxFit.cover,
              gaplessPlayback: true, // 避免重绘闪烁
              errorBuilder: (_, __, ___) => const SizedBox.shrink(), // 错误兜底
            );
          }
        }

        // 3. 终极兜底：如果本地 Asset ID 解析失败（例如文件被删），尝试显示 remote_thumb
        // 这是一个额外的安全措施
        if (widget.message.meta?['remote_thumb'] != null) {
          final remote = widget.message.meta!['remote_thumb'];
          if (remote.startsWith('http')) {
            return AppCachedImage(remote, width: w, height: h, fit: BoxFit.cover);
          }
        }

        // 如果都没有，显示占位
        return const SizedBox.shrink();
      },
    );
  }

  // 辅助方法：安全解析 int
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