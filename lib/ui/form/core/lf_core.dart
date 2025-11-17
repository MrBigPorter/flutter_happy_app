import 'package:flutter/material.dart';
import 'package:flutter_app/ui/form/core/shadow_outline_input_border.dart';
import 'package:flutter_app/ui/form/core/types.dart';
import 'package:flutter_app/ui/form/ui_min.dart';
import 'package:reactive_forms/reactive_forms.dart';

import 'lf_borders.dart';



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
  final theme = Theme.of(context);

  final base = border ?? t.border ?? const OutlineInputBorder();
  final focused = focusedBorder ?? t.focusedBorder ?? base;
  final error = errorBorder ?? t.errorBorder ?? base;
  final disabled = disabledBorder ?? t.disabledBorder ?? base;

  final sh = shadows ?? const LfShadowSet();
  final errShadow = sh.error.isNotEmpty
      ? sh.error
      : [
          BoxShadow(
            color: theme.colorScheme.error.withValues(alpha: .22),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];

  return LfResolvedBorders(
    enabled: _withShadow(base, sh.normal),
    focused: _withShadow(focused, sh.focused),
    error: _withShadow(error, errShadow),
    focusedError: _withShadow(
      focusedErrorBorder ?? error,
      sh.focusedError.isNotEmpty ? sh.focusedError : errShadow,
    ),
    disabled: _withShadow(disabled, sh.disabled),
    normal: base,
  );
}

bool _isRequired(AbstractControl<dynamic>? c) {
  if (c == null) return false;
  // 两类常见必填
  return c.hasError(ValidationMessage.required) ||
      c.hasError(ValidationMessage.requiredTrue);
}

InputDecoration buildLfDecoration(
  BuildContext context, {
  required LfLabelMode labelMode,
  String? labelText,
  Widget? labelWidget,
  String? hint,
  String? helper,
  Widget? prefix,
  Widget? suffix,
  Widget? prefixIcon,
  Widget? suffixIcon,
  TextStyle? hintStyle,
  EdgeInsetsGeometry? contentPadding,
  bool? filled,
  Color? fillColor,
}) {
  final t = formThemeOf(context);
  final theme = Theme.of(context);
  return lfDecoration(
    context,
    label: labelMode == LfLabelMode.builtInText
        ? labelText
        : labelMode == LfLabelMode.builtInWidget
        ? null
        : null,
    hint: hint,
    helper: helper,
    hintStyle: hintStyle ?? t.hintStyle ?? theme.inputDecorationTheme.hintStyle,
    contentPadding: contentPadding ?? t.contentPadding,
    filled: filled ?? t.filled,
    fillColor: fillColor ?? t.fillColor ?? theme.colorScheme.surface,
    prefix: prefix,
    suffix: suffix,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
  ).copyWith(
    label: labelMode == LfLabelMode.builtInWidget ? labelWidget : null,
    floatingLabelBehavior: labelMode == LfLabelMode.external
        ? null
        : FloatingLabelBehavior.auto,
  );
}

Widget wrapExternalLabel(
    BuildContext ctx, {
      required LfLabelMode mode,
      String? label,
      required Widget field,
      AbstractControl<dynamic>? control,       // ← 新增
      double gap = 6,                          // ← 新增
      TextStyle? labelStyle,                   // ← 新增
      TextStyle? asteriskStyle,                // ← 新增
    }) {
  if (mode != LfLabelMode.external || label == null) return field;

  final required = _isRequired(control);

  final row = Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: labelStyle),
      if (required) Text(' *', style: asteriskStyle),
    ],
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      row,
      SizedBox(height: gap),
      field,
    ],
  );
}
