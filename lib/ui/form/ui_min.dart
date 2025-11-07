import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';

import 'core/lf_borders.dart';

@immutable
class LuckyFormTheme extends ThemeExtension<LuckyFormTheme> {
  final double spacing;
  final TextStyle? labelStyle;
  final TextStyle? helperStyle;
  final TextStyle? errorStyle;
  final TextStyle? hintStyle;
  final TextStyle? prefixStyle;
  final TextStyle? suffixStyle;
  final TextStyle? counterStyle;
  final TextStyle? inputStyle;

  final bool? isDense;
  final EdgeInsetsGeometry? contentPadding;
  final InputBorder? border;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? disabledBorder;
  final Color? fillColor;
  final bool filled;

  const LuckyFormTheme({
    this.spacing = 6,
    this.labelStyle,
    this.helperStyle,
    this.errorStyle,
    this.hintStyle,
    this.prefixStyle,
    this.suffixStyle,
    this.counterStyle,
    this.inputStyle,

    this.isDense,
    this.contentPadding,
    this.border,
    this.focusedBorder,
    this.errorBorder,
    this.disabledBorder,
    this.fillColor,
    this.filled = true,
  });

  @override
  LuckyFormTheme copyWith({
    double? spacing,
    TextStyle? labelStyle,
    TextStyle? errorStyle,
    TextStyle? helperStyle,
    TextStyle? hintStyle,
    TextStyle? prefixStyle,
    TextStyle? suffixStyle,
    TextStyle? counterStyle,
    TextStyle? inputStyle,

    bool? isDense,
    EdgeInsetsGeometry? contentPadding,
    InputBorder? border,
    InputBorder? focusedBorder,
    InputBorder? errorBorder,
    InputBorder? disabledBorder,
    Color? fillColor,
    bool? filled,
  }) {
    return LuckyFormTheme(
      spacing: spacing ?? this.spacing,
      labelStyle: labelStyle ?? this.labelStyle,
      errorStyle: errorStyle ?? this.errorStyle,
      helperStyle: helperStyle ?? this.helperStyle,
      hintStyle: hintStyle ?? this.hintStyle,
      prefixStyle: prefixStyle ?? this.prefixStyle,
      suffixStyle: suffixStyle ?? this.suffixStyle,
      counterStyle: counterStyle ?? this.counterStyle,
      inputStyle: inputStyle ?? this.inputStyle,

      isDense: isDense ?? this.isDense,
      contentPadding: contentPadding ?? this.contentPadding,
      border: border ?? this.border,
      focusedBorder: focusedBorder ?? this.focusedBorder,
      errorBorder: errorBorder ?? this.errorBorder,
      disabledBorder: disabledBorder ?? this.disabledBorder,

      fillColor: fillColor ?? this.fillColor,
      filled: filled ?? this.filled,
    );
  }

  @override
  LuckyFormTheme lerp(ThemeExtension<LuckyFormTheme>? other, double t) {
    if (other is! LuckyFormTheme) {
      return this;
    }
    return LuckyFormTheme(
      spacing: lerpDouble(spacing, other.spacing, t) ?? spacing,
      labelStyle: TextStyle.lerp(labelStyle, other.labelStyle, t),
      helperStyle: TextStyle.lerp(helperStyle, other.helperStyle, t),
      errorStyle: TextStyle.lerp(errorStyle, other.errorStyle, t),
      hintStyle: TextStyle.lerp(hintStyle, other.hintStyle, t),
      prefixStyle: TextStyle.lerp(prefixStyle, other.prefixStyle, t),
      suffixStyle: TextStyle.lerp(suffixStyle, other.suffixStyle, t),
      counterStyle: TextStyle.lerp(counterStyle, other.counterStyle, t),
      inputStyle: TextStyle.lerp(inputStyle, other.inputStyle, t),

      isDense: other.isDense ?? isDense,
      contentPadding: other.contentPadding ?? contentPadding,
      border: other.border ?? border,
      focusedBorder: other.focusedBorder ?? focusedBorder,
      errorBorder: other.errorBorder ?? errorBorder,
      disabledBorder: other.disabledBorder ?? disabledBorder,

      fillColor: Color.lerp(fillColor, other.fillColor, t),
      filled: other.filled,
    );
  }
}

/// 内置默认主题 default theme
LuckyFormTheme runtimeDefault(BuildContext context) {
  return LuckyFormTheme(
    labelStyle: TextStyle(
      fontSize: context.textSm,
      fontWeight: FontWeight.w500,
      color: context.textSecondary700,
    ),
    errorStyle: TextStyle(
      fontSize: context.textSm,
      height: context.leadingSm,
      color: context.textErrorPrimary600,
    ),
    helperStyle: TextStyle(
      fontSize: context.textSm,
      height: context.leadingSm,
      color: context.textSecondary700,
    ),
    filled: true,
    fillColor: context.bgPrimary,
    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.w),
    border: ShadowOutlineInputBorder(
      borderRadius: BorderRadius.circular(8.w),
      borderSide: BorderSide(color: context.borderPrimary, width: 1.w),
      shadowColor: context.shadowXs,
      shadowBlur: 1.w,
      shadowSpread: 0,
    ),
    focusedBorder: ShadowOutlineInputBorder(
      borderRadius: BorderRadius.circular(8.w),
      borderSide: BorderSide(color: context.borderBrand, width: 1.w),
      shadowColor: context.shadowXs,
      shadowBlur: 1.w,
      shadowSpread: 0,
    ),
    errorBorder: ShadowOutlineInputBorder(
      borderRadius: BorderRadius.circular(8.w),
      borderSide: BorderSide(color: context.borderError, width: 1.w),
      shadowColor: context.shadowXs,
      shadowBlur: 1.w,
      shadowSpread: 0,
    ),
    disabledBorder: ShadowOutlineInputBorder(
      borderRadius: BorderRadius.circular(8.w),
      borderSide: BorderSide(color: context.borderDisabled, width: 1.w),
      shadowColor: context.shadowXs,
      shadowBlur: 1.w,
      shadowSpread: 0,
    ),
  );
}

/// ③ 局部 Patch（只写想改的，没写就是 null，不覆盖）
@immutable
class LuckyFormThemePatch {
  final double? spacing;
  final TextStyle? labelStyle;
  final TextStyle? helperStyle;
  final TextStyle? errorStyle;

  final bool? isDense;
  final EdgeInsetsGeometry? contentPadding;
  final InputBorder? border;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final Color? fillColor;
  final bool? filled;

  const LuckyFormThemePatch({
    this.spacing,
    this.labelStyle,
    this.helperStyle,
    this.errorStyle,
    this.isDense,
    this.contentPadding,
    this.border,
    this.focusedBorder,
    this.errorBorder,
    this.fillColor,
    this.filled,
  });

  bool get isEmpty {
    return spacing == null &&
        labelStyle == null &&
        helperStyle == null &&
        errorStyle == null &&
        isDense == null &&
        contentPadding == null &&
        border == null &&
        focusedBorder == null &&
        errorBorder == null &&
        fillColor == null &&
        filled == null;
  }
}

extension LuckyFormThemeApply on LuckyFormTheme {
  LuckyFormTheme applyPatch(LuckyFormThemePatch? patch) {
    if (patch == null || patch.isEmpty) {
      return this;
    }
    return LuckyFormTheme(
      spacing: patch.spacing ?? spacing,
      labelStyle: patch.labelStyle ?? labelStyle,
      helperStyle: patch.helperStyle ?? helperStyle,
      errorStyle: patch.errorStyle ?? errorStyle,
      isDense: patch.isDense ?? isDense,
      contentPadding: patch.contentPadding ?? contentPadding,
      border: patch.border ?? border,
      focusedBorder: patch.focusedBorder ?? focusedBorder,
      errorBorder: patch.errorBorder ?? errorBorder,
      filled: patch.filled ?? filled,
      fillColor: patch.fillColor ?? fillColor,
    );
  }
}

/// ⑤ 局部作用域：挂 Patch
class LuckyFormThemeScope extends InheritedWidget {
  final LuckyFormThemePatch patch;

  const LuckyFormThemeScope({
    super.key,
    required this.patch,
    required super.child,
  });

  static LuckyFormThemePatch? mayOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<LuckyFormThemeScope>();
    return scope?.patch;
  }

  @override
  bool updateShouldNotify(LuckyFormThemeScope oldWidget) =>
      oldWidget.patch != patch;
}

/// ⑥ 一行拿到“合并后的最终主题”（默认 → 全局 → 局部Patch）
LuckyFormTheme formThemeOf(BuildContext context) {
  final base =
      Theme.of(context).extension<LuckyFormTheme>() ?? runtimeDefault(context);
  final patch = LuckyFormThemeScope.mayOf(context);
  return base.applyPatch(patch);
}

InputDecoration lfDecoration(
  BuildContext context, {
  String? label,
  String? hint,
  String? helper,
  TextStyle? labelStyle,
  TextStyle? floatingLabelStyle,
  TextStyle? helperStyleOverride,
  TextStyle? errorStyleOverride,
  TextStyle? hintStyle,
  FloatingLabelBehavior? floatingLabelBehavior,
  Widget? prefix,
  Widget? suffix,
  Widget? prefixIcon,
  Widget? suffixIcon,
  BoxConstraints? prefixIconConstraints,
  BoxConstraints? suffixIconConstraints,
  bool? isDense,
  EdgeInsetsGeometry? contentPadding,
  InputBorder? border,
  InputBorder? focusedBorder,
  InputBorder? errorBorder,
  Color? fillColor,
  bool? filled,
}) {
  final t = formThemeOf(context);
  final theme = Theme.of(context);
  final baseBorder = border ?? t.border ?? const OutlineInputBorder();

  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,

    isDense: isDense ?? t.isDense ?? true,
    contentPadding:
        contentPadding ??
        t.contentPadding ??
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

    border: baseBorder,
    enabledBorder: baseBorder,
    focusedBorder: focusedBorder ?? t.focusedBorder ?? baseBorder,
    errorBorder:
        errorBorder ??
        t.errorBorder ??
        (baseBorder is OutlineInputBorder
            ? baseBorder.copyWith(
                borderSide: const BorderSide(color: Colors.red),
              )
            : baseBorder),

    labelStyle: labelStyle ?? t.labelStyle ?? theme.textTheme.bodyMedium,
    floatingLabelStyle:
        floatingLabelStyle ?? t.labelStyle ?? theme.textTheme.bodyMedium,
    floatingLabelBehavior: floatingLabelBehavior,

    helperStyle:
        helperStyleOverride ?? t.helperStyle ?? theme.textTheme.bodySmall,
    errorStyle:
        errorStyleOverride ??
        t.errorStyle ??
        theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),

    prefix: prefix,
    suffix: suffix,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    prefixIconConstraints:
        prefixIconConstraints ??
        const BoxConstraints(minWidth: 28, minHeight: 28),
    suffixIconConstraints:
        suffixIconConstraints ??
        const BoxConstraints(minWidth: 28, minHeight: 28),
    fillColor: fillColor ?? t.fillColor,
    filled: filled ?? t.filled,
  );
}

/// ---------- 校验文案映射 ----------
typedef ValidationMessageFn = String Function(Object? error);

Map<String, ValidationMessageFn> lfMessages({
  String? required,
  String? email,
  String? number,
  String? minLength,
  String? maxLength,
  String? pattern,
  Map<String, ValidationMessageFn>? extra,
}) {
  return {
    ValidationMessage.required: (_) => required ?? 'Required',
    ValidationMessage.email: (_) => email ?? 'Invalid email',
    ValidationMessage.number: (_) => number ?? 'Invalid number',
    ValidationMessage.minLength: (_) => minLength ?? 'Too short',
    ValidationMessage.maxLength: (_) => maxLength ?? 'Too long',
    ValidationMessage.pattern: (_) => pattern ?? 'Invalid format',
    ...?extra,
  };
}

extension LuckyServerError on AbstractControl<dynamic> {
  void setServerError(String message, {String key = 'server'}) {
    final map = Map<String, Object?>.from(errors);
    map[key] = message;
    setErrors(map);
    markAsTouched();
  }

  void clearServerError({String key = 'server'}) {
    if (!errors.containsKey(key)) return;
    final map = Map<String, Object?>.from(errors)..remove(key);
    setErrors(map);
  }
}
