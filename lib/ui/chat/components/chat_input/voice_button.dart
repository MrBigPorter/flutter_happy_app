import 'dart:async';
import 'package:flutter_app/ui/chat/widgets/voice_record_button_web_utils.dart'
if (dart.library.js) 'package:flutter_app/ui/chat/widgets/voice_record_button_web_utils_web.dart'
as web_utils;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/chat_room_provider.dart';
import '../../services/voice/voice_recorder_service.dart';

import 'recording_overlay.dart';

class VoiceRecordButton extends ConsumerStatefulWidget {
  final String conversationId;
  //  新增：录音状态改变的回调
  final ValueChanged<bool>? onRecordingChange;
  const VoiceRecordButton({super.key, required this.conversationId, this.onRecordingChange});

  @override
  ConsumerState<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends ConsumerState<VoiceRecordButton> {
  bool _isRecording = false;
  bool _isCancelArea = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
  OverlayEntry? _overlayEntry;
  DateTime? _recordStartTime;

  @override
  void initState() {
    super.initState();
    // 在调用时
    if (kIsWeb) {
      web_utils.preventDefaultContextMenu();
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _hideOverlay();
    super.dispose();
  }

  // 将启动逻辑抽取出来，方便复用
  Future<void> _startRecording() async {
    if (!await VoiceRecorderService().hasPermission()) return;
    widget.onRecordingChange?.call(true);

    setState(() {
      _isRecording = true;
      _isCancelArea = false;
      _recordDuration = 0;
      _recordStartTime = DateTime.now();
    });

    _showOverlay();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _recordDuration++);
      _updateOverlay();
    });

    await VoiceRecorderService().start();
    if (!kIsWeb) HapticFeedback.mediumImpact();
  }

  // 显示录音浮层
  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => RecordingOverlay(
        duration: _recordDuration,
        isCancelArea: _isCancelArea,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  // 更新浮层状态
  void _updateOverlay() => _overlayEntry?.markNeedsBuild();

  // 隐藏浮层并清理
  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // 核心：停止录音并处理结果
  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    _hideOverlay();

    if (!_isRecording) return;

    //  通知父组件：停止录音
    widget.onRecordingChange?.call(false);

    // 停止录音硬件并获取路径与时长
    final (path, duration) = await VoiceRecorderService().stop(_recordStartTime!);

    setState(() => _isRecording = false);

    // 逻辑判定：取消、为空或时长太短则作废
    if (_isCancelArea || path == null || (duration??0) < 1) {
      debugPrint(" Recording discarded: CancelArea=$_isCancelArea, Duration=$duration");
      return;
    }

    //  执行投递：调用 Controller 进入发送链路
    ref.read(chatControllerProvider(widget.conversationId)).sendVoiceMessage(path, duration??0);
  }

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      // --- 移动端逻辑：长按 ---
      onLongPressStart: kIsWeb ? null : (_) => _startRecording(),
      onLongPressEnd: kIsWeb ? null : (_) => _stopRecording(),
      onLongPressCancel: kIsWeb ? null : () => _stopRecording(),
      // --- Web/电脑端逻辑：点击切换 ---
      onTap: kIsWeb ? () {
        if (_isRecording) {
          _stopRecording();
        } else {
          _startRecording();
        }
      } : null,
      child: Container(
        height: 40.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isRecording ? Colors.grey[300] : Colors.grey[100],
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.black12),
        ),
        child: Text(
          _isRecording
              ? (kIsWeb ? "Click to Send" : "Release to Send")
              : (kIsWeb ? "Click to Record" : "Hold to Talk"),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _isRecording ? Colors.black54 : Colors.black87,
          ),
        ),
      ),
    );
  }
}