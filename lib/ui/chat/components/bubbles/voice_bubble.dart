import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import '../../services/voice/audio_player_manager.dart';

class VoiceBubble extends StatefulWidget {
  final ChatUiModel message;
  final bool isMe;

  const VoiceBubble({super.key, required this.message, required this.isMe});

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> {
  final _playerManager = AudioPlayerManager();

  // 存储波形高度
  late List<double> _waveformHeights;
  final int _barCount = 12;

  @override
  void initState() {
    super.initState();
    _generateStaticWaveform();
  }

  void _generateStaticWaveform() {
    // 保持确定性随机，保证同一个消息的波形永远长得一样
    final random = Random(widget.message.id.hashCode);
    _waveformHeights = List.generate(_barCount, (_) {
      return 0.3 + (random.nextDouble() * 0.7);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double minWidth = 140.w;
    final double maxWidth = 0.65.sw;
    final int dbDuration = widget.message.duration ?? 0;
    // 动态计算气泡宽度
    final double bubbleWidth = (minWidth + (dbDuration * 5.w)).clamp(minWidth, maxWidth);

    //  核心重构：同步获取播放源 (0 IO, 0 Future)
    // 优先级：Service预热好的本地路径 > 原始本地路径 > 网络URL
    final String audioSource = widget.message.resolvedPath ??
        widget.message.localPath ??
        widget.message.content;

    // --- 样式配置 ---
    final Color bubbleBgColor = widget.isMe ? const Color(0xFF0084FF) : const Color(0xFFE4E6EB);
    final Color activeBarColor = widget.isMe ? Colors.white : Colors.black87;
    final Color inactiveBarColor = widget.isMe ? Colors.white.withOpacity(0.4) : Colors.grey[400]!;
    final Color iconColor = widget.isMe ? Colors.white : Colors.black;

    //  性能优化：RepaintBoundary
    // 播放时波形图会高频刷新，必须隔离，防止带动整个 ChatList 重绘
    return RepaintBoundary(
      child: StreamBuilder<PlayerState>(
        stream: _playerManager.playerStateStream,
        builder: (context, snapshotState) {
          final playerState = snapshotState.data;
          final processingState = playerState?.processingState;
          final bool isPlaying = playerState?.playing ?? false;
          final bool isSelected = _playerManager.currentPlayingId == widget.message.id;

          // Loading 状态：选中了当前 ID，且处于缓冲或加载中
          final bool isLoading = isSelected && (processingState == ProcessingState.loading || processingState == ProcessingState.buffering);

          return InkWell(
            onTap: () async {
              if (audioSource.isNotEmpty) {
                // 播放操作是交互行为，允许异步 (IO)
                await _playerManager.play(widget.message.id, audioSource);
              }
            },
            child: Container(
              width: bubbleWidth,
              height: 44.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: bubbleBgColor,
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Row(
                children: [
                  // === 左侧：播放按钮 ===
                  Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      color: widget.isMe ? Colors.white.withOpacity(0.2) : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: isLoading
                        ? Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: CircularProgressIndicator(strokeWidth: 2, color: activeBarColor),
                    )
                        : Icon(
                      (isPlaying && isSelected && processingState != ProcessingState.completed)
                          ? Icons.pause
                          : Icons.play_arrow_rounded,
                      size: 20.sp,
                      color: iconColor,
                    ),
                  ),

                  SizedBox(width: 10.w),

                  // === 中间：波形进度条 ===
                  Expanded(
                    child: StreamBuilder<Duration?>(
                      stream: _playerManager.durationStream,
                      builder: (context, snapshotDuration) {
                        final realDuration = snapshotDuration.data ?? Duration(seconds: dbDuration);
                        final int totalMills = realDuration.inMilliseconds;

                        return StreamBuilder<Duration>(
                          stream: _playerManager.positionStream,
                          builder: (context, snapshotPos) {
                            double progress = 0.0;
                            if (isSelected && totalMills > 0) {
                              final current = snapshotPos.data?.inMilliseconds ?? 0;
                              progress = (current / totalMills).clamp(0.0, 1.0);
                              if (processingState == ProcessingState.completed) progress = 0.0;
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: List.generate(_barCount, (index) {
                                final double barPosition = index / _barCount;
                                final bool isPlayed = barPosition < progress;

                                return Container(
                                  width: 2.5.w,
                                  height: 24.h * _waveformHeights[index],
                                  decoration: BoxDecoration(
                                    color: isPlayed ? activeBarColor : inactiveBarColor,
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                );
                              }),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  SizedBox(width: 8.w),

                  // === 右侧：时长文字 ===
                  Text(
                    _formatDuration(dbDuration),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: widget.isMe ? Colors.white.withOpacity(0.9) : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return "$seconds''";
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }
}