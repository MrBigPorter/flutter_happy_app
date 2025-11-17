import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../core/lf_field.dart';
import '../core/types.dart';

typedef LfSelectOption<T> = ({String text, T value, bool disabled});

class LfSelect<T> extends StatelessWidget {
  final String name;
  final String? label;
  final String? helper;         // 输入下方辅助文案
  final String? buttonHint;     // 输入框里的占位提示（未选择时）
  final LfLabelMode labelMode;

  /// 二选一：给 items（原生）或给 options（简写）
  final List<DropdownMenuItem<T>>? items;
  final List<LfSelectOption<T>>? options;

  final Vm? validationMessages;

  /// 外观细节（原生 Dropdown 的属性，按需用）
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
              style: textStyle ?? theme.textTheme.titleMedium,
            ),
          );
        }).toList()
            : (items ?? <DropdownMenuItem<T>>[]);

        final hintWidget = buttonHint == null
            ? null
            : Text(
          buttonHint!,
          style: theme.inputDecorationTheme.hintStyle ??
              theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        );

        return ReactiveDropdownField<T>(
          formControlName: name,
          items: builtItems,
          isExpanded: isExpanded,
          style: textStyle ?? theme.textTheme.titleMedium,
          hint: hintWidget,
          validationMessages: validationMessages,
          decoration: decoration,
          menuMaxHeight: menuMaxHeight,
          borderRadius: menuRadius,
          dropdownColor: dropdownColor,
          icon: icon,
          iconSize: iconSize ?? 18,
        );
      },
    );
  }
}