import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CallActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final bool isActive; // 用于切换状态（例如：麦克风是否静音）

  const CallActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.black,
    this.size = 60,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    // 如果是激活状态（比如已静音），我们反转颜色，让用户有视觉反馈
    final finalBgColor = isActive ? Colors.white : backgroundColor;
    final finalIconColor = isActive ? Colors.black : iconColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: size.w,
            height: size.w,
            decoration: BoxDecoration(
              color: finalBgColor.withOpacity(isActive ? 1.0 : 0.2), // 未激活时半透明
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: finalIconColor,
              size: (size * 0.5).w,
            ),
          ),
        ),
        if (label != null) ...[
          SizedBox(height: 8.h),
          Text(
            label!,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}