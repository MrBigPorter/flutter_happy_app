import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../core/lf_core.dart';
import '../core/lf_field.dart';
import '../ui_min.dart'; // formThemeOf()

typedef Vm = Map<String, String Function(Object?)>;
typedef LfSelectOption<T> = ({String text, T value, bool disabled});

class LfSelect<T> extends StatelessWidget {
  final String name;
  final String? label;

  /// 输入框上的说明（下方 helper 走 LuckyFormTheme）
  final String? helper;

  /// 按钮里的占位提示（Dropdown 的 hint，显示在未选择时）
  final String? buttonHint;

  final LfLabelMode labelMode;

  /// 两种传参方式：要么给 items（原生），要么给 options（简写）
  final List<DropdownMenuItem<T>>? items;
  final List<LfSelectOption<T>>? options;

  final Vm? validationMessages;

  /// 外观细节
  final bool isExpanded;
  final double? menuMaxHeight;
  final BorderRadius? menuRadius;
  final Color? dropdownColor;
  final Widget? icon;
  final double? iconSize;

  const LfSelect({
    super.key,
    required this.name,
    this.label,
    this.helper,
    this.buttonHint,
    this.labelMode = LfLabelMode.external,
    this.items,
    this.options,
    this.validationMessages,
    this.isExpanded = true,
    this.menuMaxHeight,
    this.menuRadius,
    this.dropdownColor,
    this.icon,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final t = formThemeOf(context);
    final theme = Theme.of(context);

    return LfField<T>(
      name: name,
      label: label,
      hint: null,
      helper: helper,
      labelMode: labelMode,
      validationMessages: validationMessages,
      builder: (ctx, decoration, textStyle) {
        final builtItems = options != null
            ? options!.map((o) {
          return DropdownMenuItem<T>(
            value: o.value,
            enabled: !o.disabled,
            child: Text(
              o.text,
              style: textStyle ?? t.inputStyle ?? theme.textTheme.titleMedium,
            ),
          );
        }).toList()
            : (items ??  <DropdownMenuItem<T>>[]);

        // 按钮里的占位 Widget
        final hintWidget = buttonHint == null
            ? null
            : Text(
          buttonHint!,
          style: t.hintStyle ?? theme.textTheme.bodyMedium?.copyWith(
            color: theme.hintColor,
          ),
        );

        // 选中项文字样式用 style，外观走 decoration（来自 Lucky 主题）
        return ReactiveDropdownField<T>(
          formControlName: name,
          items: builtItems,
          isExpanded: isExpanded,
          style: textStyle ?? t.inputStyle ?? theme.textTheme.titleMedium,
          hint: hintWidget,
          validationMessages: validationMessages,
          decoration: decoration,
          menuMaxHeight: menuMaxHeight,
          borderRadius: menuRadius,
          dropdownColor: dropdownColor,
          icon: icon,
          iconSize: iconSize??12,
        );
      },
    );
  }
}