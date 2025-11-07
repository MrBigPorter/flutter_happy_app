import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../core/lf_field.dart';
import '../core/lf_core.dart';

class LfDate extends StatelessWidget {
  final String name;
  final String? label, hint, helper;
  final LfLabelMode labelMode;
  final Map<String, String Function(Object?)>? validationMessages;
  final DateTime firstDate, lastDate;

  const LfDate({
    super.key,
    required this.name,
    required this.firstDate,
    required this.lastDate,
    this.label, this.hint, this.helper,
    this.labelMode = LfLabelMode.external,
    this.validationMessages,
  });

  @override
  Widget build(BuildContext context) {
    return LfField<DateTime?>(
      name: name,
      label: label, hint: hint, helper: helper, labelMode: labelMode,
      validationMessages: validationMessages,
      builder: (ctx, decoration, textStyle) {
        return ReactiveDatePicker<DateTime>(
          formControlName: name,
          firstDate: firstDate,
          lastDate: lastDate,
          builder: (context, picker, child) {
            final value = picker.value;
            final str = value == null
                ? ''
                : MaterialLocalizations.of(context).formatMediumDate(value);

            // 用 InputDecorator 复用统一的边框/阴影/图标
            final input = InputDecorator(
              isFocused: false,
              isEmpty: str.isEmpty,
              decoration: decoration.copyWith(
                suffixIcon: const Icon(Icons.calendar_today, size: 18),
              ),
              child: Text(
                str,
                style: textStyle,
              ),
            );

            return InkWell(onTap: picker.showPicker, child: input);
          },
        );
      },
    );
  }
}