import 'package:flutter_app/ui/chat/widgets/voice_record_button_web_utils.dart'
if (dart.library.js) 'package:flutter_app/ui/chat/widgets/voice_record_button_web_utils_web.dart'
as web_utils;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/voice/voice_recorder_service.dart';
import 'recording_overlay.dart';

class VoiceRecordButton extends ConsumerStatefulWidget {
  final String conversationId;
  final ValueChanged<bool>? onRecordingChange;

  // Callback to return the recorded file path and duration to the parent component
  final Function(String path, int duration)? onVoiceSent;

  const VoiceRecordButton({
    super.key,
    required this.conversationId,
    this.onRecordingChange,
    this.onVoiceSent,
  });

  @override
  ConsumerState<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends ConsumerState<VoiceRecordButton>
    with TickerProviderStateMixin {
  bool _isRecording = false;
  bool _isCancelArea = false;
  bool _isPressing = false;

  int _recordDuration = 0;
  Ticker? _durationTicker;
  OverlayEntry? _overlayEntry;
  DateTime? _recordStartTime;

  // ValueNotifier drives the overlay display — no markNeedsBuild needed.
  final ValueNotifier<int> _durationNotifier = ValueNotifier<int>(0);

  // Animation for pulsing recording indicator
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      web_utils.preventDefaultContextMenu();
    }
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _durationTicker?.dispose();
    _hideOverlay();
    _durationNotifier.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // Action Logic
  // ===========================================================================

  Future<void> _startRecording() async {
    final hasPermission = await VoiceRecorderService().hasPermission();
    if (!hasPermission) return;

    if (!kIsWeb && !_isPressing) {
      debugPrint("[VoiceButton] User released too fast, aborting recording start.");
      return;
    }

    widget.onRecordingChange?.call(true);
    setState(() {
      _isRecording = true;
      _isCancelArea = false;
      _recordDuration = 0;
      _recordStartTime = DateTime.now();
    });

    _durationNotifier.value = 0;

    // Start pulse animation
    _pulseController.repeat(reverse: true);

    _showOverlay();

    // Use Ticker instead of Timer.periodic — Ticker is tied to Flutter's render
    // pipeline, unaffected by OverlayEntry rebuilds on Web where Timer delegates
    // to browser setInterval and can lose callbacks when mounted flips to false.
    _durationTicker = createTicker((elapsed) {
      if (!mounted) return;
      final seconds = elapsed.inSeconds;
      if (seconds != _recordDuration) {
        setState(() => _recordDuration = seconds);
        _durationNotifier.value = seconds;
      }
    })..start();

    try {
      await VoiceRecorderService().start();
      if (!kIsWeb) HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint("[VoiceButton] Start recording failed: $e");
      _stopRecording(forceDiscard: true);
    }
  }

  Future<void> _stopRecording({bool forceDiscard = false}) async {
    _durationTicker?.stop();
    _durationTicker?.dispose();
    _durationTicker = null;
    _hideOverlay();
    _pulseController.stop();
    _pulseController.reset();

    if (!_isRecording) return;

    widget.onRecordingChange?.call(false);
    if (mounted) {
      setState(() => _isRecording = false);
    }

    var (path, duration) = await VoiceRecorderService().stop(_recordStartTime ?? DateTime.now());

    if (path != null && path.startsWith('file://')) {
      path = path.replaceFirst('file://', '');
    }

    // Validation: Forced discard / In cancel area / Empty path / Duration too short
    if (forceDiscard || _isCancelArea || path == null || (duration ?? 0) < 1) {
      debugPrint("[VoiceButton] Recording discarded. (Cancel=$_isCancelArea, Duration=$duration)");
      return;
    }

    // Forward the result to the parent component (e.g., ModernChatInputBar) via callback
    if (mounted && widget.onVoiceSent != null) {
      widget.onVoiceSent!(path, duration ?? 0);
    }
  }

  // ===========================================================================
  // Overlay Logic
  // ===========================================================================

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = OverlayEntry(
      builder: (context) => RecordingOverlay(
        durationNotifier: _durationNotifier,
        isCancelArea: _isCancelArea,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Rebuilds the overlay entry so it picks up updated [isCancelArea].
  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  String _formatDuration(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  // ===========================================================================
  // UI Build
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
        // Trigger cancel if dragged upwards by 50 pixels
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

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 40.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red.withValues(alpha: 0.08) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: _isRecording ? Colors.red.withValues(alpha: 0.3) : Colors.black12,
          ),
        ),
        child: _isRecording
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing red recording dot
            _PulsingDot(animation: _pulseAnimation),
            SizedBox(width: 8.w),
            // Elapsed timer
            Text(
              _formatDuration(_recordDuration),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(width: 8.w),
            // Stop icon
            Icon(
              Icons.stop_circle_outlined,
              size: 18.sp,
              color: Colors.red.shade700,
            ),
          ],
        )
            : Text(
          kIsWeb ? "Click to Record" : "Hold to Talk",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

/// Animated pulsing red dot widget used as recording indicator.
class _PulsingDot extends AnimatedWidget {
  const _PulsingDot({required Animation<double> animation})
      : super(listenable: animation);

  Animation<double> get _animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10.w,
      height: 10.w,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.6 * _animation.value),
            blurRadius: 4 * _animation.value,
            spreadRadius: 1 * _animation.value,
          ),
        ],
      ),
    );
  }
}
