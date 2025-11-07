import 'package:flutter/material.dart';

class ShadowOutlineInputBorder extends OutlineInputBorder {
  const ShadowOutlineInputBorder({
    super.borderSide = const BorderSide(),
    super.borderRadius = const BorderRadius.all(Radius.circular(12)),
    super.gapPadding = 4.0,
    this.enableShadow = false,
    this.shadowColor = const Color(0x14000000),
    this.shadowBlur = 10.0,
    this.shadowSpread = 0.0,
  });

  final bool enableShadow;
  final Color shadowColor;
  final double shadowBlur;
  final double shadowSpread;

  @override
  void paint(Canvas canvas, Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double? gapPercentage,
    TextDirection? textDirection,
  }) {
    if (enableShadow) {
      final r = borderRadius.resolve(textDirection).toRRect(rect.inflate(shadowSpread));
      canvas.drawShadow(Path()..addRRect(r), shadowColor, shadowBlur, false);
    }
    super.paint(canvas, rect,
      gapStart: gapStart,
      gapExtent: gapExtent,
      gapPercentage: gapPercentage?? 0.0,
      textDirection: textDirection,
    );
  }
}

class LfShadowSet {
  final List<BoxShadow> normal, focused, error, disabled, focusedError;
  const LfShadowSet({this.normal = const [], this.focused = const [], this.error = const [], this.disabled = const [], this.focusedError = const []});
  static const subtle = LfShadowSet(
    normal: [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1))],
    focused:[BoxShadow(color: Color(0x33000000), blurRadius:4, offset: Offset(0, 1))],
    error: [BoxShadow(color: Color(0x33000000), blurRadius:4, offset: Offset(0, 1))],
    disabled: [],
    focusedError: [BoxShadow(color: Color(0x33000000), blurRadius:4, offset: Offset(0, 3))],
  );
}