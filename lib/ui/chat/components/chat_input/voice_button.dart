import 'dart:async';
import 'package:flutter_app/ui/chat/widgets/voice_record_button_web_utils.dart'
if (dart.library.js) 'package:flutter_app/ui/chat/widgets/voice_record_button_web_utils_web.dart'
as web_utils;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// 移除对 controller 的直接依赖，改为回调
import '../../services/voice/voice_recorder_service.dart';
import 'recording_overlay.dart';

class VoiceRecordButton extends ConsumerStatefulWidget {
  final String conversationId;
  final ValueChanged<bool>? onRecordingChange;

  //  新增：发送回调，将文件路径和时长交还给父组件
  final Function(String path, int duration)? onVoiceSent;

  const VoiceRecordButton({
    super.key,
    required this.conversationId,
    this.onRecordingChange,
    this.onVoiceSent, // 接收回调
  });

  @override
  ConsumerState<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends ConsumerState<VoiceRecordButton> {
  bool _isRecording = false;
  bool _isCancelArea = false;
  bool _isPressing = false;

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
    _hideOverlay();
    super.dispose();
  }

  // ===========================================================================
  //  Action Logic
  // ===========================================================================

  Future<void> _startRecording() async {
    final hasPermission = await VoiceRecorderService().hasPermission();
    if (!hasPermission) return;

    if (!kIsWeb && !_isPressing) {
      debugPrint(" User released too fast, abort recording start.");
      return;
    }

    widget.onRecordingChange?.call(true);
    setState(() {
      _isRecording = true;
      _isCancelArea = false;
      _recordDuration = 0;
      _recordStartTime = DateTime.now();
    });

    _showOverlay();

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() => _recordDuration++);
        _updateOverlay();
      }
    });

    try {
      await VoiceRecorderService().start();
      if (!kIsWeb) HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint("❌ Start Record Failed: $e");
      _stopRecording(forceDiscard: true);
    }
  }

  Future<void> _stopRecording({bool forceDiscard = false}) async {
    _recordTimer?.cancel();
    _recordTimer = null;
    _hideOverlay();

    if (!_isRecording) return;

    widget.onRecordingChange?.call(false);
    if (mounted) {
      setState(() => _isRecording = false);
    }

    var (path, duration) = await VoiceRecorderService().stop(_recordStartTime ?? DateTime.now());

    if (path != null && path.startsWith('file://')) {
      path = path.replaceFirst('file://', '');
    }

    // 校验：强行取消 / 在取消区域 / 路径为空 / 时长太短
    if (forceDiscard || _isCancelArea || path == null || (duration ?? 0) < 1) {
      debugPrint(" Recording discarded. (Cancel=$_isCancelArea, Duration=$duration)");
      return;
    }

    //  核心修改：通过回调将结果传给父组件 (ModernChatInputBar)
    if (mounted && widget.onVoiceSent != null) {
      widget.onVoiceSent!(path, duration ?? 0);
    }
  }

  // ===========================================================================
  //  Overlay Logic (保持不变)
  // ===========================================================================

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = OverlayEntry(
      builder: (context) => RecordingOverlay(
        duration: _recordDuration,
        isCancelArea: _isCancelArea,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // ===========================================================================
  //  UI Build (保持不变)
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: kIsWeb
          ? null
          : (_) {
        _isPressing = true;
        _startRecording();
      },
      onLongPressMoveUpdate: kIsWeb
          ? null
          : (details) {
        // 上滑 50 像素触发取消
        final offset = details.localPosition.dy;
        final isCancel = offset < -50;
        if (_isCancelArea != isCancel) {
          setState(() => _isCancelArea = isCancel);
          _updateOverlay();
        }
      },
      onLongPressEnd: kIsWeb
          ? null
          : (_) {
        _isPressing = false;
        _stopRecording();
      },
      onLongPressCancel: kIsWeb
          ? null
          : () {
        _isPressing = false;
        _stopRecording(forceDiscard: true);
      },
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
              ? "Release to Cancel"
              : (kIsWeb ? "Click to Send" : "Release to Send"))
              : (kIsWeb ? "Click to Record" : "Hold to Talk"),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _isCancelArea
                ? Colors.red
                : (_isRecording ? Colors.black54 : Colors.black87),
          ),
        ),
      ),
    );
  }
}