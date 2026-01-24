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
  final ValueChanged<bool>? onRecordingChange;

  const VoiceRecordButton({
    super.key,
    required this.conversationId,
    this.onRecordingChange,
  });

  @override
  ConsumerState<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends ConsumerState<VoiceRecordButton> {
  bool _isRecording = false; // 逻辑录音状态
  bool _isCancelArea = false; // 是否在取消区域
  bool _isPressing = false; //  物理按压状态 (解决僵尸弹窗的关键)

  int _recordDuration = 0;
  Timer? _recordTimer;
  OverlayEntry? _overlayEntry;
  DateTime? _recordStartTime;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      web_utils.preventDefaultContextMenu();
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _hideOverlay(); // 确保销毁时移除弹窗
    super.dispose();
  }

  // ===========================================================================
  //  Action Logic
  // ===========================================================================

  Future<void> _startRecording() async {
    // 1. 获取权限 (异步)
    final hasPermission = await VoiceRecorderService().hasPermission();
    if (!hasPermission) return;

    //  核心修复：如果是移动端，且异步回来后发现手指已经松开了，就直接终止，不弹窗
    if (!kIsWeb && !_isPressing) {
      debugPrint("⛔️ User released too fast, abort recording start.");
      return;
    }

    // 2. 更新状态
    widget.onRecordingChange?.call(true);
    setState(() {
      _isRecording = true;
      _isCancelArea = false;
      _recordDuration = 0;
      _recordStartTime = DateTime.now();
    });

    // 3. 显示 UI
    _showOverlay();

    // 4. 启动计时器
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() => _recordDuration++);
        _updateOverlay();
      }
    });

    // 5. 启动硬件
    try {
      await VoiceRecorderService().start();
      if (!kIsWeb) HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint("❌ Start Record Failed: $e");
      _stopRecording(forceDiscard: true); // 启动失败则强行重置
    }
  }

  Future<void> _stopRecording({bool forceDiscard = false}) async {
    // 1. 立即清理 UI (Timer 和 Overlay)
    _recordTimer?.cancel();
    _recordTimer = null;
    _hideOverlay(); // 这一步必须同步执行，确保弹窗立刻消失

    // 2. 如果根本没在录音，直接返回
    if (!_isRecording) return;

    // 3. 通知外部
    widget.onRecordingChange?.call(false);
    if (mounted) {
      setState(() => _isRecording = false);
    }

    // 4. 停止硬件 (异步)
    final (path, duration) = await VoiceRecorderService().stop(_recordStartTime ?? DateTime.now());

    // 5. 决定是否发送
    // 如果是强行丢弃、或者在取消区域、或者文件为空、或者时长太短(<1秒)
    if (forceDiscard || _isCancelArea || path == null || (duration ?? 0) < 1) {
      debugPrint("🗑️ Recording discarded. (Cancel=$_isCancelArea, Duration=$duration)");
      return;
    }

    // 6. 发送
    if (mounted) {
      ref.read(chatControllerProvider(widget.conversationId)).sendVoiceMessage(path, duration ?? 0);
    }
  }

  // ===========================================================================
  //  Overlay Logic
  // ===========================================================================

  void _showOverlay() {
    if (_overlayEntry != null) return; // 防止重复添加
    _overlayEntry = OverlayEntry(
      builder: (context) => RecordingOverlay(
        duration: _recordDuration,
        isCancelArea: _isCancelArea,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _updateOverlay() {
    // 重建 Overlay 以更新时长和状态
    _overlayEntry?.markNeedsBuild();
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // ===========================================================================
  //  UI Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // --- 移动端逻辑 ---
      onLongPressStart: kIsWeb
          ? null
          : (_) {
        _isPressing = true; // 标记物理按下
        _startRecording();
      },
      onLongPressMoveUpdate: kIsWeb
          ? null
          : (details) {
        // 🔥 补全：检测手指上滑取消
        // 当手指向上移动超过一定距离（比如 -50）时，判定为取消区域
        final offset = details.localPosition.dy;
        final isCancel = offset < -50;
        if (_isCancelArea != isCancel) {
          setState(() => _isCancelArea = isCancel);
          _updateOverlay(); // 刷新弹窗显示（通常会变红）
        }
      },
      onLongPressEnd: kIsWeb
          ? null
          : (_) {
        _isPressing = false; // 标记物理抬起
        _stopRecording();
      },
      onLongPressCancel: kIsWeb
          ? null
          : () {
        // 意外中断（如电话打入）
        _isPressing = false;
        _stopRecording(forceDiscard: true); // 视为取消
      },

      // --- Web 逻辑 (点击切换) ---
      onTap: kIsWeb
          ? () {
        if (_isRecording) {
          _stopRecording();
        } else {
          _startRecording();
        }
      }
          : null,

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
              ? (_isCancelArea
              ? "Release to Cancel"  // 进入取消区域时的文案
              : (kIsWeb ? "Click to Send" : "Release to Send"))
              : (kIsWeb ? "Click to Record" : "Hold to Talk"),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _isCancelArea
                ? Colors.red // 取消区域变红
                : (_isRecording ? Colors.black54 : Colors.black87),
          ),
        ),
      ),
    );
  }
}