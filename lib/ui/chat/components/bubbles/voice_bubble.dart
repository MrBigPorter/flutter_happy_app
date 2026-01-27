import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/providers/chat_room_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/voice/audio_player_manager.dart';
import 'package:path/path.dart' as p;

class VoiceBubble extends StatefulWidget {
  final ChatUiModel message;
  final bool isMe;

  const VoiceBubble({super.key, required this.message, required this.isMe});

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> {
  final _playerManager = AudioPlayerManager();

  // 存储波形高度，保证 UI 稳定
  late List<double> _waveformHeights;
  final int _barCount = 12;

  @override
  void initState() {
    super.initState();
    _generateStaticWaveform();
  }

  void _generateStaticWaveform() {
    // 使用 message.id 作为种子，确保同一条消息的波形形状永远一样
    final random = Random(widget.message.id.hashCode);
    _waveformHeights = List.generate(_barCount, (_) {
      // 随机高度范围：30% - 100%
      return 0.3 + (random.nextDouble() * 0.7);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 基础参数
    final double minWidth = 140.w;
    final double maxWidth = 0.65.sw;
    final int dbDuration = widget.message.duration ?? 0;

    // 气泡宽度计算
    final double bubbleWidth = (minWidth + (dbDuration * 5.w)).clamp(minWidth, maxWidth);


    return FutureBuilder<Directory>(
      future: getApplicationDocumentsDirectory(),
      builder: (context, snapshotDir){
        // 1. 播放源解析逻辑
        String? finalSource;
        // A. 优先查内存缓存 (绝对路径，秒开)
        finalSource = ChatRoomController.getPathFromCache(widget.message.id);

        // B. 缓存未中，则通过相对路径 + 当前沙盒目录拼接
        if (finalSource == null && snapshotDir.hasData && widget.message.localPath != null) {
          finalSource = p.join(snapshotDir.data!.path, 'chat_audio', widget.message.localPath!);
        }

        // C. 检查物理文件是否存在，不存在则降级到网络 URL
        bool isLocalValid = finalSource != null && !finalSource.startsWith('http') && File(finalSource).existsSync();
        if (!isLocalValid) {
          finalSource = widget.message.content;
        }

        //  颜色配置 (Messenger 风格)
        // 如果想要微信绿，把 activeColor 改为 Colors.black87，把 Active 背景改为 Color(0xFF95EC69)
        final Color bubbleBgColor = widget.isMe ? const Color(0xFF0084FF) : const Color(0xFFE4E6EB);
        final Color activeBarColor = widget.isMe ? Colors.white : Colors.black87;
        final Color inactiveBarColor = widget.isMe ? Colors.white.withOpacity(0.4) : Colors.grey[400]!;
        final Color iconColor = widget.isMe ? Colors.white : Colors.black;


        return StreamBuilder<PlayerState>(
          stream: _playerManager.playerStateStream, // 1. 监听播放状态
          builder: (context, snapshotState) {
            final playerState = snapshotState.data;
            final processingState = playerState?.processingState;
            final bool isPlaying = playerState?.playing ?? false;
            final bool isSelected = _playerManager.currentPlayingId == widget.message.id;

            final bool isLoading = isSelected && (processingState == ProcessingState.loading || processingState == ProcessingState.buffering);

            return InkWell(
              onTap: () async {
                //  使用解析后的 finalSource 进行播放
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

                    // === 中间：波形进度条 (双重流监听) ===
                    Expanded(
                      child: StreamBuilder<Duration?>(
                        stream: _playerManager.durationStream, // 2. 外层：监听总时长
                        builder: (context, snapshotDuration) {
                          // 获取真实总时长：优先用播放器的，没有则兜底用数据库的
                          final realDuration = snapshotDuration.data ?? Duration(seconds: dbDuration);
                          final int totalMills = realDuration.inMilliseconds;

                          return StreamBuilder<Duration>(
                            stream: _playerManager.positionStream, // 3. 内层：监听实时进度
                            builder: (context, snapshotPos) {
                              double progress = 0.0;

                              // 只有当前选中的消息才计算进度
                              if (isSelected && totalMills > 0) {
                                final current = snapshotPos.data?.inMilliseconds ?? 0;
                                progress = (current / totalMills).clamp(0.0, 1.0);

                                // 播放完成归零
                                if (processingState == ProcessingState.completed) progress = 0.0;
                              }

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: List.generate(_barCount, (index) {
                                  // 计算这根线的位置比例 (0.0 ~ 1.0)
                                  final double barPosition = index / _barCount;
                                  // 如果当前进度超过了这根线的位置，就变色
                                  final bool isPlayed = barPosition < progress;

                                  return Container(
                                    width: 2.5.w,
                                    height: 24.h * _waveformHeights[index], // 随机高度
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