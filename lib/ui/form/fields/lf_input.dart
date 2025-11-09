import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../core/lf_field.dart';

class LfInput<T> extends StatelessWidget {
  final String name;
  final String? label, hint, helper;
  final LfLabelMode labelMode;
  final Map<String, String Function(Object?)>? validationMessages;

  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines, minLines;
  final List<TextInputFormatter>? inputFormatters;

  final Widget? prefix, suffix, prefixIcon, suffixIcon;
  final TextStyle? textStyle, hintStyle, labelStyle;
  final EdgeInsetsGeometry? contentPadding;
  final bool? filled;
  final Color? fillColor;
  final InputBorder? border, focusedBorder, errorBorder, disabledBorder;
  final List<BoxShadow>? boxShadow;
  final BorderRadius? containerRadius;
  final InputDecoration Function(BuildContext, InputDecoration)?
  decorationBuilder;

  const LfInput({
    super.key,
    required this.name,
    this.label,
    this.hint,
    this.helper,
    this.labelMode = LfLabelMode.external,
    this.validationMessages,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,

    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.suffixIcon,
    this.textStyle,
    this.hintStyle,
    this.labelStyle,
    this.contentPadding,
    this.filled,
    this.fillColor,
    this.border,
    this.focusedBorder,
    this.errorBorder,
    this.disabledBorder,
    this.boxShadow,
    this.containerRadius,
    this.decorationBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LfField<T>(
      name: name,
      label: label,
      hint: hint,
      helper: helper,
      labelMode: labelMode,
      validationMessages: validationMessages,

      prefix: prefix,
      suffix: suffix,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      textStyle: textStyle,
      hintStyle: hintStyle,
      labelStyle: labelStyle,
      contentPadding: contentPadding,
      filled: filled,
      fillColor: fillColor,
      border: border,
      focusedBorder: focusedBorder,
      errorBorder: errorBorder,
      disabledBorder: disabledBorder,
      boxShadow: boxShadow,
      containerRadius: containerRadius,
      decorationBuilder: decorationBuilder,

      builder: (ctx, decoration, textStyle) => ReactiveTextField<T>(
        formControlName: name,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        minLines: minLines,
        inputFormatters: inputFormatters,
        style: textStyle,
        validationMessages: validationMessages,
        decoration: decoration,
      ),
    );
  }
}
