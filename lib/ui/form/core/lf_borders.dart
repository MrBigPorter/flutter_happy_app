import 'package:flutter/material.dart';
import 'package:flutter_app/ui/form/core/shadow_outline_input_border.dart';
import '../ui_min.dart';
class LfShadowSet {
  final List<BoxShadow> normal;
  final List<BoxShadow> focused;
  final List<BoxShadow> error;
  final List<BoxShadow> focusedError;
  final List<BoxShadow> disabled;
  const LfShadowSet({
    this.normal = const [],
    this.focused = const [],
    this.error = const [],
    this.focusedError = const [],
    this.disabled = const [],
  });
  static const subtle = LfShadowSet(
    normal: [],
    focused: [],
    error: [],
    focusedError: [],
    disabled: [],
  );
}

InputBorder _withShadow(InputBorder b, List<BoxShadow> s) {
  if (s.isEmpty) return b;
  return b is OutlineInputBorder
      ? ShadowOutlineInputBorder(
    borderSide: b.borderSide,
    borderRadius: b.borderRadius,
    gapPadding: b.gapPadding,
    enableShadow: true,
    shadowColor: s.first.color,
    shadowBlur: s.first.blurRadius,
    shadowSpread: s.first.spreadRadius,
  )
      : b;
}

class LfResolvedBorders {
  final InputBorder enabled, focused, error, focusedError, disabled, normal;
  const LfResolvedBorders({
    required this.enabled,
    required this.focused,
    required this.error,
    required this.focusedError,
    required this.disabled,
    required this.normal,
  });
}

LfResolvedBorders resolvedBorders(
    BuildContext context, {
      InputBorder? border,
      InputBorder? focusedBorder,
      InputBorder? errorBorder,
      InputBorder? focusedErrorBorder,
      InputBorder? disabledBorder,
      LfShadowSet? shadows,
    }) {
  final t = formThemeOf(context);

  final base = border ?? t.border ?? const OutlineInputBorder();
  final focused = focusedBorder ?? t.focusedBorder ?? base;
  final error = errorBorder ?? t.errorBorder ?? base;
  final disabled = disabledBorder ?? t.disabledBorder ?? base;

  final sh = shadows ?? const LfShadowSet();
  final errShadow = sh.error;

  return LfResolvedBorders(
    enabled: _withShadow(base, sh.normal),
    focused: _withShadow(focused, sh.focused),
    error: _withShadow(error, errShadow),
    focusedError:
    _withShadow(focusedErrorBorder ?? error, sh.focusedError.isNotEmpty ? sh.focusedError : errShadow),
    disabled: _withShadow(disabled, sh.disabled),
    normal: base,
  );
}