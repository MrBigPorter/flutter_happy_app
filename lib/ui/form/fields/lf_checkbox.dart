import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../core/lf_core.dart';
import '../ui_min.dart';

class LfCheckbox extends StatelessWidget {
  final String name;
  final String label;
  final String? helper;
  final Map<String, String Function(Object?)>? validationMessages;

  const LfCheckbox({
    super.key,
    required this.name,
    required this.label,
    this.helper,
    this.validationMessages,
  });

  @override
  Widget build(BuildContext context) {
    final t = formThemeOf(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ReactiveCheckbox(
              formControlName: name,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: t.textStyle ?? theme.textTheme.titleMedium)),
          ],
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(helper!, style: t.helperStyle ?? theme.textTheme.bodySmall),
        ],
        // 错误提示：值或状态变化时刷新
        ReactiveValueListenableBuilder<bool>(
          formControlName: name,
          builder: (ctx, control, __) {
            final show = control.invalid && (control.touched || control.dirty);
            if (!show) return const SizedBox.shrink();
            final msg = control.errors.values.first.toString();
            return Padding(
              padding: EdgeInsets.only(top: t.spacing),
              child: Text(msg, style: t.errorStyle ?? theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
            );
          },
        ),
      ],
    );
  }
}