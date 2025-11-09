import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../ui_min.dart'; // formThemeOf()

typedef Vm = Map<String, String Function(Object?)>;

class LfSwitch extends StatelessWidget {
  final String name;
  final String label;
  final String? helper;
  final Vm? validationMessages;

  // 可选外观
  final EdgeInsetsGeometry? contentPadding;
  final Color? activeColor;        // 开启时拇指/轨道主色（依平台）
  final Color? inactiveTrackColor; // 关闭时轨道色
  final bool adaptive;             // iOS 用 CupertinoSwitch
  final bool labelToggles;         // 点击整行切换

  const LfSwitch({
    super.key,
    required this.name,
    required this.label,
    this.helper,
    this.validationMessages,
    this.contentPadding,
    this.activeColor,
    this.inactiveTrackColor,
    this.adaptive = true,
    this.labelToggles = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = formThemeOf(context);
    final theme = Theme.of(context);

    return ReactiveFormField<bool, bool>(
      formControlName: name,
      validationMessages: validationMessages,
      showErrors: (c) => c.invalid && (c.dirty || c.touched),
      builder: (field) {
        final control = field.control;
        final disabled = control.disabled;
        final value = field.value ?? false;

        final textStyle =
            t.textStyle ?? theme.textTheme.titleMedium;
        final helperStyle =
            t.helperStyle ?? theme.textTheme.bodySmall;
        final errorStyle =
            t.errorStyle ?? theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error);

        final row = Row(
          children: [
            Expanded(
              child: Opacity(
                opacity: disabled ? 0.6 : 1,
                child: Text(label, style: textStyle),
              ),
            ),
            // 用 adaptive 以匹配平台风格
            Switch.adaptive(
              value: value,
              onChanged: disabled ? null : field.didChange,
              activeColor: activeColor ?? theme.colorScheme.primary,
              inactiveTrackColor: inactiveTrackColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: (!labelToggles || disabled)
                  ? null
                  : () => field.didChange(!value),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: contentPadding ?? const EdgeInsets.symmetric(vertical: 8),
                child: row,
              ),
            ),
            if (field.errorText != null)
              Padding(
                padding: EdgeInsets.only(top: t.spacing),
                child: Text(field.errorText!, style: errorStyle),
              ),
            if (helper != null)
              Padding(
                padding: EdgeInsets.only(top: t.spacing),
                child: Text(helper!, style: helperStyle),
              ),
          ],
        );
      },
    );
  }
}