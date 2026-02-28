import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import '../../services/voice/audio_player_manager.dart';

// Unified path utility for platform-specific path checking
import 'package:flutter_app/utils/media/media_path.dart';
// URL resolver to convert relative keys into playable remote URLs
import 'package:flutter_app/utils/media/url_resolver.dart';

class VoiceBubble extends StatefulWidget {
  final ChatUiModel message;
  final bool isMe;

  const VoiceBubble({super.key, required this.message, required this.isMe});

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> {
  final _playerManager = AudioPlayerManager();

  // Stores random heights for the static waveform visualization
  late List<double> _waveformHeights;
  final int _barCount = 12;

  @override
  void initState() {
    super.initState();
    _generateStaticWaveform();
  }

  void _generateStaticWaveform() {
    // Seed random with message ID hash to ensure consistent waveform for the same message
    final random = Random(widget.message.id.hashCode);
    _waveformHeights = List.generate(_barCount, (_) {
      return 0.3 + (random.nextDouble() * 0.7);
    });
  }

  // Resolves and normalizes the audio source (Local priority -> Remote fallback)
  String _pickAudioSource() {
    final candidates = <String?>[
      widget.message.resolvedPath,
      widget.message.localPath,
      widget.message.content,
    ];

    for (final c in candidates) {
      final raw = (c ?? '').trim();
      if (raw.isEmpty) continue;

      final t = MediaPath.classify(raw);

      // Local or file URI: Use directly
      if (t == MediaPathType.localAbs || t == MediaPathType.fileUri) {
        return raw;
      }

      // Web Blob: Use directly (common in Web platforms)
      if (t == MediaPathType.blob) {
        return raw;
      }

      // Remote: HTTP or relative path handled via UrlResolver
      if (t == MediaPathType.http) return raw;

      if (t == MediaPathType.uploads || t == MediaPathType.relative) {
        // Resolve file key into a full resource domain URL
        return UrlResolver.resolveFile(raw);
      }
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final double minWidth = 140.w;
    final double maxWidth = 0.65.sw;
    final int dbDuration = widget.message.duration ?? 0;

    // Dynamically calculate bubble width based on duration
    final double bubbleWidth = (minWidth + (dbDuration * 5.w)).clamp(minWidth, maxWidth);

    final String audioSource = _pickAudioSource();

    // --- Styling Configuration ---
    final Color bubbleBgColor = widget.isMe ? const Color(0xFF0084FF) : const Color(0xFFE4E6EB);
    final Color activeBarColor = widget.isMe ? Colors.white : Colors.black87;
    final Color inactiveBarColor = widget.isMe ? Colors.white.withOpacity(0.4) : Colors.grey[400]!;
    final Color iconColor = widget.isMe ? Colors.white : Colors.black;

    // RepaintBoundary isolates high-frequency waveform updates during playback
    return RepaintBoundary(
      child: StreamBuilder<PlayerState>(
        stream: _playerManager.playerStateStream,
        builder: (context, snapshotState) {
          final playerState = snapshotState.data;
          final processingState = playerState?.processingState;
          final bool isPlaying = playerState?.playing ?? false;
          final bool isSelected = _playerManager.currentPlayingId == widget.message.id;

          // Loading state: Selected ID is currently buffering or loading
          final bool isLoading = isSelected &&
              (processingState == ProcessingState.loading || processingState == ProcessingState.buffering);

          return InkWell(
            onTap: () async {
              if (audioSource.isNotEmpty) {
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
                  // === Left: Playback Button ===
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

                  // === Middle: Waveform Progress Indicator ===
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

                  // === Right: Duration Label ===
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