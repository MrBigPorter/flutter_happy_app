import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecordingOverlay extends StatelessWidget {
  final int duration;
  final bool isCancelArea;

  const RecordingOverlay({super.key, required this.duration, this.isCancelArea = false});

  @override
  Widget build(BuildContext context) {
    // Core Fix: Wrap with IgnorePointer to allow touch events to pass through to underlying components
    return IgnorePointer(
      ignoring: true,
      child: Material( // Wrap with Material to ensure correct text styling
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: 150.w,
            height: 150.w,
            decoration: BoxDecoration(
              color: Colors.black87.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCancelArea ? Icons.undo : Icons.mic,
                  size: 50.sp,
                  color: isCancelArea ? Colors.red : Colors.white,
                ),
                SizedBox(height: 12.h),
                Text(
                  isCancelArea ? "Release to cancel" : "${duration}s",
                  style: TextStyle(
                    color: isCancelArea ? Colors.red : Colors.white,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}