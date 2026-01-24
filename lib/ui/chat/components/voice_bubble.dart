import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/providers/chat_room_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

import '../services/voice/audio_player_manager.dart';

class VoiceBubble extends StatefulWidget {
  final ChatUiModel message;
  final bool isMe;

  const VoiceBubble({super.key, required this.message, required this.isMe});

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble>
    with SingleTickerProviderStateMixin {
  final _playerManager = AudioPlayerManager();

  // 1. 增加动画控制器，让波形能动起来
  late AnimationController _animationController;

  //在这里集成 just_audio 的播放逻辑
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // 1 秒一个周期
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. 动态宽度计算：时长越长气泡越宽
    // 公式：基础宽度(70) + 时长占宽(每秒加若干像素)，最高不超过屏幕宽度的 60%
    final double minWidth = 70.w;
    final double maxWidth = 0.6.sw;
    final int duration = widget.message.duration ?? 0;
    final double bubbleWidth = (minWidth + (duration * 6.w)).clamp(
      minWidth,
      maxWidth,
    );

    //// 2. 确定播放源：Session 缓存 > 本地路径 > 远程 URL
    final String? sessionPath = ChatRoomController.getPathFromCache(
      widget.message.id,
    );
    final String? audioSource =
        sessionPath ?? widget.message.localPath ?? widget.message.content;

    final bool isCurrentPlaying = _playerManager.isPlaying(widget.message.id);

    return StreamBuilder<PlayerState>(
      stream: _playerManager.playerStateStream, // 监听播放器状态变化
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final bool isPlaying = playerState?.playing ?? false;
        // 判断：当前播放器里放的，是不是这条消息？
        // (需要在 AudioPlayerManager 里加一个 isMessageSelected 方法，或者直接对比 ID)
        final bool isCurrentMessage =
            _playerManager.currentPlayingId == widget.message.id;

        // 更新播放状态和动画
        final bool isActive =
            isCurrentMessage &&
            isPlaying &&
            processingState != ProcessingState.completed;
        final bool isLoading =
            isCurrentMessage &&
            (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering);
        // 控制波形动画
        if (isActive) {
          _animationController.repeat();
        } else {
          _animationController.stop();
          _animationController.reset();
        }
        return InkWell(
          onTap: () => setState(() {
            _playerManager.play(widget.message.id, audioSource!);
          }),
          child: Container(
            width: bubbleWidth,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: widget.isMe ? const Color(0xFF95EC69) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 播放按钮
                Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 20.sp,
                  color: Colors.black87,
                ),
                SizedBox(width: 8.w),
                // 静态声纹 (你可以之后替换为真正的波形绘制)
                Expanded(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) => _buildWaveform(isActive),
                  ),
                ),
                SizedBox(width: 8.w),
                // 时长文字
                Text(
                  "$duration''",
                  style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveform(bool active) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        10,
        (index) => Container(
          width: 2.w,
          height: (10 + (index % 3) * 4.h), // 模拟不同高度
          decoration: BoxDecoration(
            color: active ? Colors.black87 : Colors.black26,
            borderRadius: BorderRadius.circular(1.r),
          ),
        ),
      ),
    );
  }
}
