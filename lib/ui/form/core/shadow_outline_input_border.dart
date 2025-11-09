import 'package:flutter/material.dart';

/// 在 OutlineInputBorder 基础上额外画一个阴影。
class ShadowOutlineInputBorder extends OutlineInputBorder {
  final bool enableShadow;
  final Color shadowColor;
  final double shadowBlur;   // 模糊半径
  final double shadowSpread; // 向外“膨胀”的距离

  const ShadowOutlineInputBorder({
    super.borderSide,
    super.borderRadius,
    super.gapPadding,
    this.enableShadow = true,
    this.shadowColor = const Color(0x33000000),
    this.shadowBlur = 8.0,
    this.shadowSpread = 0.0,
  });

  @override
  ShadowOutlineInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
    bool? enableShadow,
    Color? shadowColor,
    double? shadowBlur,
    double? shadowSpread,
  }) {
    return ShadowOutlineInputBorder(
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
      gapPadding: gapPadding ?? this.gapPadding,
      enableShadow: enableShadow ?? this.enableShadow,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowSpread: shadowSpread ?? this.shadowSpread,
    );
  }

  @override
  void paint(
      Canvas canvas,
      Rect rect, {
        double? gapStart,
        double gapExtent = 0.0,
        double gapPercentage = 0.0,
        TextDirection? textDirection,
      }) {
    final RRect outer = borderRadius.resolve(textDirection).toRRect(rect);

    if (enableShadow && shadowBlur > 0 && shadowColor.alpha != 0) {
      final Paint shadowPaint = Paint()
        ..color = shadowColor
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur)
        ..blendMode = BlendMode.dstOver;
      final RRect spread = outer.inflate(shadowSpread);
      canvas.drawRRect(spread, shadowPaint);
    }

    // 再交给父类画正常边框
    super.paint(
      canvas,
      rect,
      gapStart: gapStart,
      gapExtent: gapExtent,
      gapPercentage: gapPercentage,
      textDirection: textDirection,
    );
  }
}