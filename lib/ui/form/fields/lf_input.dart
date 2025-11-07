import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../core/lf_field.dart';
import '../core/lf_core.dart';

typedef LfDecorationBuilder = InputDecoration Function(
    BuildContext context,
    InputDecoration base,
    );

class LfInput<T> extends StatelessWidget {
  final String name;
  final String? label, hint, helper;
  final LfLabelMode labelMode;
  final Map<String, String Function(Object?)>? validationMessages;

  // 行为（保留原有）
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines, minLines;

  // 视觉/插槽
  final Widget? prefix, suffix, prefixIcon, suffixIcon;
  final TextStyle? hintStyle;
  final EdgeInsetsGeometry? contentPadding;
  final bool? filled;            // ← 默认改为 null
  final Color? fillColor;

  // 新增：单字段装饰二次加工
  final LfDecorationBuilder? decorationBuilder;

  // （可选）更完整的透传
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool readOnly;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final void Function(T value)? onChanged;
  final void Function(T value)? onSubmitted;
  final VoidCallback? onTap;
  final ShowErrorsFunction<T>? showErrors;
  final ControlValueAccessor<T, String>? valueAccessor;
  final FormControl<T>? control;

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
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.suffixIcon,
    this.hintStyle,
    this.contentPadding,
    this.filled,                 // ← 不给默认值
    this.fillColor,
    this.decorationBuilder,      // ← 新增

    // 可选透传（以后用得到）
    this.inputFormatters,
    this.maxLength,
    this.maxLengthEnforcement,
    this.textInputAction,
    this.autofocus = false,
    this.readOnly = false,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.autofillHints,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.showErrors,
    this.valueAccessor,
    this.control,
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

      // 视觉/插槽
      prefix: prefix,
      suffix: suffix,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      hintStyle: hintStyle,
      contentPadding: contentPadding,
      filled: filled,            // ← 让共享/主题接管
      fillColor: fillColor,
      decorationBuilder: decorationBuilder,   // ← 透传给 LfField

      // 真正字段
      builder: (ctx, decoration, textStyle) => ReactiveTextField<T>(
        formControlName: control == null ? name : null,
        formControl: control,
        valueAccessor: valueAccessor,
        showErrors: showErrors,
        validationMessages: validationMessages,

        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        minLines: minLines,
        style: textStyle,
        decoration: decoration,

        // 更多透传
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        maxLengthEnforcement: maxLengthEnforcement,
        textInputAction: textInputAction,
        autofocus: autofocus,
        readOnly: readOnly,
        textAlign: textAlign,
        textAlignVertical: textAlignVertical,
        autofillHints: autofillHints,
        focusNode: focusNode,
      ),
    );
  }
}