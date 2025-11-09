import 'package:flutter/material.dart';
import 'package:flutter_app/ui/form/core/types.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../ui_min.dart';



class LfField<T> extends StatelessWidget {
  final String name;

  final String? label, hint, helper;
  final LfLabelMode labelMode;
  final Map<String, String Function(Object?)>? validationMessages;
  final Widget? labelWidget;

  final Widget? prefix, suffix, prefixIcon, suffixIcon;
  final TextStyle? textStyle, hintStyle, labelStyle,errorStyle;
  final EdgeInsetsGeometry? contentPadding;
  final bool? filled,required;
  final Color? fillColor;
  final InputBorder? border, focusedBorder, errorBorder, disabledBorder;
  final int? errorMaxLines;

  final List<BoxShadow>? boxShadow;
  final BorderRadius? containerRadius;

  final Widget Function(
    BuildContext ctx,
    InputDecoration decoration,
    TextStyle? textStyle,
  )
  builder;

  final InputDecoration Function(BuildContext ctx, InputDecoration base)?
  decorationBuilder;

  const LfField({
    super.key,
    required this.name,
    required this.builder,
    this.label,
    this.hint,
    this.helper,
    this.labelMode = LfLabelMode.external,
    this.validationMessages,
    this.labelWidget,
    this.errorMaxLines,
    this.required,


    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.suffixIcon,
    this.textStyle,
    this.hintStyle,
    this.labelStyle,
    this.errorStyle,
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

  // —— 拿到当前 ReactiveForm 里的 control
  AbstractControl<dynamic>? _controlOf(BuildContext context) {
    final root = ReactiveForm.of(context);
    return (root is FormGroup) ? root.control(name) : null;
  }

  // —— 把 prefix/suffix 规范成垂直居中的 *Icon 版本，并去掉 48 的默认宽
  InputDecoration _normalizeAffixes(InputDecoration d) {

    var deco = d;

    if (deco.prefix != null || deco.prefixIcon != null) {
      deco = deco.copyWith(
        prefixIcon: deco.prefixIcon,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        prefix: deco.prefix,
      );
    }
    if (deco.suffix != null || deco.suffixIcon == null) {
      deco = deco.copyWith(
        suffixIcon: deco.suffix,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffix: deco.suffix,
      );
    }
    return deco;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final d = runtimeDefault(context); // ← 直接拿运行时默认
    final control = _controlOf(context);

    // 合成装饰：字段入参 > 运行时默认
    InputDecoration deco = InputDecoration(
      labelText: labelMode == LfLabelMode.builtInText ? label : null,
      label: labelMode == LfLabelMode.builtInWidget ? labelWidget : null,
      hintText: hint,
      helperText: helper,

      // ← 先看字段是否传入，否则落到 runtimeDefault
      contentPadding: contentPadding ?? d.contentPadding,
      filled: filled ?? d.filled,
      fillColor: fillColor ?? d.fillColor,

      hintStyle: hintStyle ?? d.hintStyle ?? theme.textTheme.bodySmall,
      errorStyle: errorStyle ?? d.errorStyle ?? theme.textTheme.bodySmall?.copyWith(color: cs.error),

      prefix: prefix,
      suffix: suffix,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,

      // 边框统一吃 runtimeDefault（可被字段级覆盖）
      border: border ?? d.border,
      enabledBorder: border ?? d.border,
      focusedBorder: focusedBorder ?? d.focusedBorder,
      focusedErrorBorder: errorBorder ?? d.errorBorder,
      errorBorder: errorBorder ?? d.errorBorder,
      disabledBorder: disabledBorder ?? d.disabledBorder,
      errorMaxLines: errorMaxLines ?? d.errorMaxLines,

      floatingLabelBehavior: labelMode == LfLabelMode.external
          ? null
          : FloatingLabelBehavior.auto,
    );

    deco = _normalizeAffixes(deco); // 垂直居中 prefix/suffix, 去掉 48 宽

    // 单字段装饰二次加工（可选）
    if (decorationBuilder != null) {
      deco = decorationBuilder!(context, deco);
    }

    // pending 自动菊花（未自定义 suffixIcon 时）
    final isPending = control?.status == ControlStatus.pending;
    if (isPending && deco.suffixIcon == null) {
      deco = deco.copyWith(
        suffixIcon: const Padding(
          padding: EdgeInsets.only(right: 8),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      );
    }

    // 字体：字段 > runtimeDefault > 主题
    final resolvedStyle =
        textStyle ?? d.textStyle ?? theme.textTheme.titleMedium;

    // 构建子字段
    Widget field = builder(context, deco, resolvedStyle);

    // 外部 label（带 *）
    if (labelMode == LfLabelMode.external && label != null) {

      field = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label!,
                style: labelStyle ?? d.labelStyle ?? theme.textTheme.bodySmall,
              ),
              if (required??false)
                Text(
                  ' *',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
                ),
            ],
          ),
          SizedBox(height: d.spacing),
          field,
        ],
      );
    }

    return field;
  }
}
