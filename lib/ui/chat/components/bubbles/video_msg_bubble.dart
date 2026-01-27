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
  bool _isMuted = false; // 默认有声，可以做成静音开关

  // 获取服务实例
  final _playbackService = VideoPlaybackService();

  @override
  void dispose() {
    _controller?.dispose(); // 记得销毁，防止内存泄漏
    super.dispose();
  }

  /// 核心逻辑：初始化并播放
  Future<void> _playVideo() async {
    // 1. 如果已经初始化，直接切状态
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

    final source = _playbackService.getPlayableSource(widget.message);

    if (source.isEmpty) {
      setState(() => _isInitializing = false);
      return; // 或者显示个错误 Toast
    }


    try {
      // 3. 使用 Service 创建控制器
      _controller = _playbackService.createController(source);

      await _controller!.initialize();
      // 4. 使用 Service 请求独占
      _playbackService.requestPlay(_controller!);
      await _controller!.play();

      setState(() {
        _isInitializing = false;
        _isPlaying = true;
      });

      // 监听播放结束，恢复按钮状态
      _controller!.addListener(() {
        if (_controller!.value.position >= _controller!.value.duration) {
          setState(() {
            _isPlaying = false;
            // 播放完回到开头，方便重播
            _controller!.seekTo(Duration.zero);
            _controller!.pause();
          });
        }
      });

    } catch (e) {
      debugPrint("Inline video play failed: $e");
      setState(() => _isInitializing = false);
    }
  }

  /// 跳转全屏 (双击或点击全屏按钮)
  void _openFullScreen() {
    // 暂停当前小窗
    _controller?.pause();
    setState(() => _isPlaying = false);

    // 直接用 Service 解析好的路径去全屏页
    final source = _playbackService.getPlayableSource(widget.message);
    // 获取封面图路径，用于传递给全屏页做 Hero 占位
    final meta = widget.message.meta ?? {};
    final String thumbSource = meta['thumb'] ?? "";
    
    if (source.isNotEmpty) {
      Navigator.of(context).push(
        PageRouteBuilder(
          // 使用 FadeTransition 让背景渐变，配合 Hero 效果更好
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_,_,_)=> VideoPlayerPage(
            videoSource: source,
            heroTag: widget.message.id,
            thumbSource: thumbSource,
          ),
          transitionsBuilder: (_,animation,__,child)=>
              FadeTransition(opacity: animation, child: child),
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. 获取元数据
    final meta = widget.message.meta ?? {};
    final int w = meta['w'] ?? 16;
    final int h = meta['h'] ?? 9;

    final double aspectRatio = (w / h).clamp(0.6, 1.8);
    final double maxWidth = 0.6.sw;
    final double height = maxWidth / aspectRatio;

    final int durationSec = meta['duration'] ?? 0;
    final String durationStr = _formatDuration(durationSec);
    final String thumbSource = meta['thumb'] ?? "";

    return Hero(
      tag: widget.message.id,
      transitionOnUserGestures: true,
      // 飞行过程中只显示封面，避免播放器闪烁
      flightShuttleBuilder: (flightContext, animation, direction, fromContext, toContext) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: _buildThumbnail(thumbSource, maxWidth, height),
        );
      },
      child: Material(
        // 使用 material 避免 Hero 动画时缺少材质感
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
                  // ============================================
                  // Layer 1: 封面图 (永远在底部垫着)
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
                  // Layer 3: 交互遮罩 (点击播放/暂停)
                  // ============================================
                  GestureDetector(
                    // 单击：原地播放/暂停
                    onTap: _playVideo,
                    // 双击：进入全屏
                    onDoubleTap: _openFullScreen,
                    child: Container(
                      color: Colors.transparent, // 必须有颜色(哪怕透明)才能响应点击
                    ),
                  ),

                  // ============================================
                  // Layer 4: UI 控件层 (播放按钮、Loading、角标)
                  // ============================================

                  // A. 中间的大播放按钮 (未播放 && 未加载时显示)
                  if (!_isPlaying && !_isInitializing)
                    Center(
                      child: IgnorePointer( // 让点击事件穿透到下面的 GestureDetector
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

                  // B. Loading 转圈 (正在初始化时)
                  if (_isInitializing || widget.message.status == MessageStatus.sending)
                    Center(
                      child: SizedBox(
                        width: 30.w,
                        height: 30.w,
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      ),
                    ),

                  // C. 只有在暂停或者没初始化时，才显示时长 (播放时隐藏，让画面更干净)
                  if (!_isPlaying)
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

                  // D. 全屏按钮 (右上角，方便用户发现)
                  if (_controller != null && _controller!.value.isInitialized)
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

                  // E. 静音按钮 (左下角，可选)
                  if (_isPlaying)
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
                              size: 16.sp
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ),
    );
  }

  // 下面的辅助方法保持不变 (缩略图、时长格式化)
  Widget _buildThumbnail(String source, double w, double h) {
    if (source.isEmpty) return const SizedBox.shrink();
    if (source.startsWith('http')) {
      return AppCachedImage(source, width: w, height: h, fit: BoxFit.cover);
    }
    return FutureBuilder<String?>(
      future: AssetManager.getFullPath(source, MessageType.image),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          if (kIsWeb) {
            return Image.network(snapshot.data!, width: w, height: h, fit: BoxFit.cover);
          }
          return Image.file(File(snapshot.data!), width: w, height: h, fit: BoxFit.cover);
        }
        return const SizedBox.shrink();
      },
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}