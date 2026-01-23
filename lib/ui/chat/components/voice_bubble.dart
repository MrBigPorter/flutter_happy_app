import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/providers/chat_room_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/voice/audio_player_manager.dart';

class VoiceBubble extends StatefulWidget{
    final ChatUiModel message;
    final bool isMe;
    const VoiceBubble({super.key, required this.message, required this.isMe});

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> {
  final _playerManager = AudioPlayerManager();

  //在这里集成 just_audio 的播放逻辑
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    // 1. 动态宽度计算：时长越长气泡越宽
    // 公式：基础宽度(70) + 时长占宽(每秒加若干像素)，最高不超过屏幕宽度的 60%
    final double minWidth = 70.w;
    final double maxWidth = 0.6.sw;
    final int duration = widget.message.duration ?? 0;
    final double bubbleWidth = (minWidth + (duration * 6.w)).clamp(minWidth, maxWidth);

    //// 2. 确定播放源：Session 缓存 > 本地路径 > 远程 URL
    final String? sessionPath = ChatRoomController.getPathFromCache(widget.message.id);
    final String? audioSource = sessionPath ?? widget.message.localPath ?? widget.message.content;

    final bool isCurrentPlaying = _playerManager.isPlaying(widget.message.id);

    return InkWell(
      onTap: ()=> setState(() {
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
            Expanded(child: _buildWaveform(isCurrentPlaying)),
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
  }

  Widget _buildWaveform(bool active){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(10, (index)=>Container(
        width: 2.w,
        height: (10 + (index % 3) * 4.h),// 模拟不同高度
        decoration: BoxDecoration(
          color: active ? Colors.black87 : Colors.black26,
          borderRadius: BorderRadius.circular(1.r),
        ),
      )),
    );
  }
}