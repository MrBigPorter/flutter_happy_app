// lf_password.dart
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../core/lf_field.dart';
import '../core/types.dart';


class LfPassword extends StatefulWidget {
  final String name;
  final String? label, hint;
  final LfLabelMode labelMode;
  final Map<String, String Function(Object?)>? validationMessages;

  // 样式覆盖直传
  final TextStyle? textStyle, hintStyle, labelStyle;
  final EdgeInsetsGeometry? contentPadding;
  final bool? filled;
  final Color? fillColor;
  final InputBorder? border, focusedBorder, errorBorder, disabledBorder;

  const LfPassword({
    super.key,
    required this.name,
    this.label, this.hint,
    this.labelMode = LfLabelMode.external,
    this.validationMessages,
    this.textStyle, this.hintStyle, this.labelStyle,
    this.contentPadding, this.filled, this.fillColor,
    this.border, this.focusedBorder, this.errorBorder, this.disabledBorder,
  });

  @override
  State<LfPassword> createState() => _LfPasswordState();
}

class _LfPasswordState extends State<LfPassword> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return LfField<String>(
      name: widget.name,
      label: widget.label,
      hint: widget.hint,
      labelMode: widget.labelMode,
      validationMessages: widget.validationMessages,

      textStyle: widget.textStyle,
      hintStyle: widget.hintStyle,
      labelStyle: widget.labelStyle,
      contentPadding: widget.contentPadding,
      filled: widget.filled,
      fillColor: widget.fillColor,
      border: widget.border,
      focusedBorder: widget.focusedBorder,
      errorBorder: widget.errorBorder,
      disabledBorder: widget.disabledBorder,

      builder: (ctx, decoration, textStyle) => ReactiveTextField<String>(
        formControlName: widget.name,
        obscureText: _obscure,
        style: textStyle,
        validationMessages: widget.validationMessages,
        decoration: decoration.copyWith(
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, size: 18),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
  }
}