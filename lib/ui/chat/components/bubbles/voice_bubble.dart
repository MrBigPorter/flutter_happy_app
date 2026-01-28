import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/providers/chat_room_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../utils/asset/asset_manager.dart'; // 引入 AssetManager
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
    final double bubbleWidth = (minWidth + (dbDuration * 5.w)).clamp(minWidth, maxWidth);

    //  核心重构点：使用 FutureBuilder 配合 AssetManager 解析 Asset ID
    return FutureBuilder<String?>(
      future: AssetManager.getFullPath(widget.message.localPath ?? "", widget.message.type),
      builder: (context, snapshotPath) {

        // 1. 播放源解析逻辑
        String? finalSource;

        // A. 优先查内存缓存 (绝对路径，用于秒开)
        finalSource = ChatRoomController.getPathFromCache(widget.message.id);

        // B. 解析 Asset ID 拿到的物理绝对路径
        if (finalSource == null && snapshotPath.hasData) {
          finalSource = snapshotPath.data;
        }

        // C. 物理文件检查：如果本地无效，自动降级到网络 URL (content)
        bool isLocalValid = finalSource != null &&
            !finalSource.startsWith('http') &&
            File(finalSource).existsSync();

        if (!isLocalValid) {
          finalSource = widget.message.content; // 使用 CDN 地址
        }

        // --- 样式配置 ---
        final Color bubbleBgColor = widget.isMe ? const Color(0xFF0084FF) : const Color(0xFFE4E6EB);
        final Color activeBarColor = widget.isMe ? Colors.white : Colors.black87;
        final Color inactiveBarColor = widget.isMe ? Colors.white.withOpacity(0.4) : Colors.grey[400]!;
        final Color iconColor = widget.isMe ? Colors.white : Colors.black;

        return StreamBuilder<PlayerState>(
          stream: _playerManager.playerStateStream,
          builder: (context, snapshotState) {
            final playerState = snapshotState.data;
            final processingState = playerState?.processingState;
            final bool isPlaying = playerState?.playing ?? false;
            final bool isSelected = _playerManager.currentPlayingId == widget.message.id;
            final bool isLoading = isSelected && (processingState == ProcessingState.loading || processingState == ProcessingState.buffering);

            return InkWell(
              onTap: () async {
                if (finalSource != null && finalSource.isNotEmpty) {
                  await _playerManager.play(widget.message.id, finalSource);
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
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return "$seconds''";
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }
}