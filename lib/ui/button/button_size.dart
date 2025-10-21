import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ButtonSizeValue {
  final double height;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double radius;

  const ButtonSizeValue({
    required this.height,
    required this.fontSize,
    required this.padding,
    required this.radius,
  });

}

ButtonSizeValue resolveButtonSize(String size) {
  switch (size) {
    case 'small':
      return ButtonSizeValue(
        height: 48.w,
        fontSize: 14.w,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        radius: 4.w,
      );
    case 'large':
      return ButtonSizeValue(
        height: 56.w,
        fontSize: 18.w,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        radius: 8.w,
      );
    case 'medium':
    default:
      return ButtonSizeValue(
        height: 52.w,
        fontSize: 16.w,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        radius: 6.w,
      );
  }
}

