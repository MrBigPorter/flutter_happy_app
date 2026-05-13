import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Full-width recording bottom bar positioned at the very bottom of the screen.
///
/// Uses [ValueNotifier] for the elapsed duration so the display stays in sync
/// via [ValueListenableBuilder] — avoiding [OverlayEntry.markNeedsBuild] issues
/// on web and preventing state tree conflicts.
class RecordingOverlay extends StatelessWidget {
  final ValueNotifier<int> durationNotifier;
  final bool isCancelArea;

  const RecordingOverlay({
    super.key,
    required this.durationNotifier,
    this.isCancelArea = false,
  });

  static String formatDuration(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final isCancel = isCancelArea;
    final bgColor = isCancel ? Colors.red.shade700 : Colors.black87;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: true,
        child: Material(
          color: Colors.transparent,
          child: Container(
            color: bgColor.withValues(alpha: 0.85),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              height: 56.h,
              child: ValueListenableBuilder<int>(
                valueListenable: durationNotifier,
                builder: (context, seconds, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic, size: 20.sp, color: Colors.white),
                      SizedBox(width: 8.w),
                      Text(
                        formatDuration(seconds),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (isCancel) ...[
                        SizedBox(width: 12.w),
                        Text(
                          "Slide to Cancel",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
