import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../ui_min.dart';
import 'lf_borders.dart';
import 'lf_core.dart';
import 'lf_defaults.dart';

typedef Vm = Map<String, String Function(Object?)>;
typedef LfDecorationBuilder = InputDecoration Function(
    BuildContext context,
    InputDecoration base,
    );

class LfField<T> extends StatelessWidget {
  final String name;
  final String? label, hint, helper;
  final LfLabelMode labelMode;
  final Vm? validationMessages;

  // 视觉
  final bool shadow;
  final LfShadowSet? shadows;
  final InputBorder? border, focusedBorder, errorBorder, disabledBorder;
  final Widget? prefix, suffix, prefixIcon, suffixIcon;
  final String? prefixText, suffixText;
  final TextStyle? inputStyle, hintStyle;
  final EdgeInsetsGeometry? contentPadding;
  final bool? filled;
  final Color? fillColor;

  // label
  final Widget? labelWidget;

  // 具体控件
  final Widget Function(
      BuildContext ctx,
      InputDecoration decoration,
      TextStyle? inputStyle,
      ) builder;

  // 单字段装饰二次加工
  final LfDecorationBuilder? decorationBuilder;

  const LfField({
    super.key,
    required this.name,
    required this.builder,
    this.label,
    this.hint,
    this.helper,
    this.labelMode = LfLabelMode.external,
    this.validationMessages,
    this.shadow = true,
    this.shadows,
    this.border,
    this.focusedBorder,
    this.errorBorder,
    this.disabledBorder,
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.inputStyle,
    this.hintStyle,
    this.contentPadding,
    this.filled,
    this.fillColor,
    this.labelWidget,
    this.decorationBuilder,
  });

  // ✅ 正确拿到当前表单里的 control(name)
  AbstractControl<dynamic>? _controlOf(BuildContext context) {
    final root = ReactiveForm.of(context);
    if (root is FormGroup) {
      return root.control(name);
    }
    // 如需支持数组/路径，可在此扩展
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final shared = LfDefaults.of(context);
    final t = formThemeOf(context);
    final theme = Theme.of(context);
    final control = _controlOf(context);

    // 1) 边框（含可选阴影）
    final borders = resolvedBorders(
      context,
      border: border,
      focusedBorder: focusedBorder,
      errorBorder: errorBorder,
      disabledBorder: disabledBorder,
      shadows: shadow ? (shadows ?? LfShadowSet.subtle) : const LfShadowSet(),
    );

    // 2) 基础装饰（字段入参 > 共享 > 主题）
    InputDecoration deco = buildLfDecoration(
      context,
      labelMode: labelMode,
      labelText: label,
      labelWidget: labelWidget,
      hint: hint,
      helper: helper,
      prefix: prefix,
      suffix: suffix,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      hintStyle: hintStyle ?? shared.hintStyle,
      contentPadding: contentPadding ?? shared.contentPadding,
      filled: filled ?? shared.filled,
      fillColor: fillColor ?? shared.fillColor,
    );

    // 2.0 prefix/suffix → prefixIcon/suffixIcon（垂直居中 + 去掉48默认宽）
    final pad = deco.contentPadding;
    final edge = pad is EdgeInsets
        ? pad
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 12);

    if (prefix != null && prefixIcon == null) {
      deco = deco.copyWith(
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: edge.left),
          child: Center(child: prefix!),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        prefix: null,
      );
    }
    if (suffix != null && suffixIcon == null) {
      deco = deco.copyWith(
        suffixIcon: Padding(
          padding: EdgeInsets.only(right: edge.right),
          child: Center(child: suffix!),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffix: null,
      );
    }

    // 2.1 共享二次加工（全局统一规则）
    if (shared.decorationBuilder != null) {
      deco = shared.decorationBuilder!(context, deco);
    }

    // 2.2 最终边框落地
    deco = deco.copyWith(
      prefixText: prefixText,
      suffixText: suffixText,
      border: borders.enabled,
      enabledBorder: borders.enabled,
      focusedBorder: borders.focused,
      errorBorder: borders.error,
      disabledBorder: borders.disabled,
    );

    // 2.3 单字段再加工
    if (decorationBuilder != null) {
      deco = decorationBuilder!(context, deco);
    }

    // 2.4 异步校验 pending → 自动加菊花（前提：没有自定义 suffixIcon）
    final isPending = control?.status == ControlStatus.pending;
    if (isPending && deco.suffixIcon == null) {
      deco = deco.copyWith(
        suffixIcon: const Padding(
          padding: EdgeInsets.only(right: 8),
          child: SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      );
    }

    // 3) 字体：字段 > 共享 > 主题扩展 > 系统主题
    final resolvedStyle =
        inputStyle ?? shared.inputStyle ?? t.inputStyle ?? theme.textTheme.titleMedium;

    // 4) 具体字段
    final field = builder(context, deco, resolvedStyle);

    // 5) 外部 label 包装（支持必填星号；不再依赖 shared.asteriskStyle）
    return wrapExternalLabel(
      context,
      mode: labelMode,
      label: label,
      field: field,
      control: control,                         // 让 wrapExternalLabel 能判断 required/requiredTrue
      gap: shared.labelGap ?? t.spacing,
      labelStyle: shared.labelStyle ?? t.labelStyle,
      asteriskStyle: (t.errorStyle ?? theme.textTheme.bodySmall)
          ?.copyWith(color: theme.colorScheme.error),
    );
  }
}