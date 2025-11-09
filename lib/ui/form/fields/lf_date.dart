import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../core/lf_field.dart';
import '../core/types.dart';

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
      label: label,
      hint: hint,
      helper: helper,
      labelMode: labelMode,
      validationMessages: validationMessages,
      builder: (ctx, decoration, textStyle) {
        return ReactiveDatePicker<DateTime>(
          formControlName: name,
          firstDate: firstDate,
          lastDate: lastDate,
          builder: (context, picker, child) {
            final v = picker.value;
            final str = v == null
                ? ''
                : MaterialLocalizations.of(context).formatMediumDate(v);

            final input = InputDecorator(
              isFocused: false,
              isEmpty: str.isEmpty,
              decoration: decoration.copyWith(
                suffixIcon: Padding(
                  padding: EdgeInsets.only(right: 10.w),
                  child:  Icon(Icons.calendar_today, size: 18.w),
                ),
                suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              ),
              child: Text(str, style: textStyle),
            );

            return InkWell(onTap: picker.showPicker, child: input);
          },
        );
      },
    );
  }
}