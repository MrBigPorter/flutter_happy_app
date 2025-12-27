import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../../modal/sheet/modal_sheet_config.dart';
import '../core/lf_field.dart';
import '../core/types.dart';

class LfDatePicker extends StatelessWidget {
  final String name;
  final String? label;
  final String? helper;
  final String? placeholder;
  final LfLabelMode labelMode;
  final bool readOnly;
  final bool? required;
  final Map<String, String Function(Object)>? validationMessages;
  final double pickerHeight;

  // 日期限制
  final DateTime? minDate;
  final DateTime? maxDate;

  const LfDatePicker({
    super.key,
    required this.name,
    this.label,
    this.helper,
    this.placeholder,
    this.labelMode = LfLabelMode.external,
    this.readOnly = false,
    this.required,
    this.validationMessages,
    this.pickerHeight = 250,
    this.minDate,
    this.maxDate,
  });

  @override
  Widget build(BuildContext context) {
    // 泛型 String：因为 Model 里存的是 "yyyy-MM-dd" 字符串
    return LfField<String>(
      name: name,
      label: label,
      helper: helper,
      labelMode: labelMode,
      required: required,
      validationMessages: null,
      readOnly: readOnly,
      builder: (ctx, baseDecoration, textStyle) {

        return ReactiveFormField<String, String>(
          formControlName: name,
          validationMessages: validationMessages,
          builder: (ReactiveFormFieldState<String, String> field) {

            // 1. 获取当前值 (String)
            final value = field.value;
            final hasValue = value != null && value.isNotEmpty;

            // 2. 合并装饰器 (注入 errorText)
            final effectiveDecoration = baseDecoration.copyWith(
              errorText: field.errorText,
              // 强制为 null，由下方 Text 渲染，避免重叠
              hintText: null,
              suffixIcon: baseDecoration.suffixIcon ??
                  Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: Icon(
                      Icons.calendar_today,
                      size: 20.r,
                      color: field.control.disabled
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).iconTheme.color,
                    ),
                  ),
            );

            // 3. 交互区域
            return InkWell(
              onTap: readOnly || field.control.disabled
                  ? null
                  : () => _showDatePicker(context, field), // 传 field
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: effectiveDecoration,
                isEmpty: !hasValue,
                child: Text(
                  hasValue ? value : (placeholder ?? ''),
                  style: hasValue
                      ? textStyle
                      : (baseDecoration.hintStyle ??
                      Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).hintColor
                      )),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 参数改为 ReactiveFormFieldState
  void _showDatePicker(BuildContext context, ReactiveFormFieldState<String, String> field) {

    // 1. 解析初始值：String -> DateTime
    DateTime initialDate = DateTime.now();
    final currentValue = field.value;

    if (currentValue != null && currentValue.isNotEmpty) {
      try {
        initialDate = DateFormat('yyyy-MM-dd').parse(currentValue);
      } catch (e) {
        print('Date parse error: $e');
      }
    } else if (maxDate != null) {
      initialDate = maxDate!;
    }

    // 2. 边界保护 (防止崩溃)
    if (minDate != null && initialDate.isBefore(minDate!)) initialDate = minDate!;
    if (maxDate != null && initialDate.isAfter(maxDate!)) initialDate = maxDate!;

    DateTime tempDate = initialDate;

    // 3. 弹出底部滚轮
    RadixSheet.show(
      config: ModalSheetConfig(enableHeader: false),
      builder: (ctx, close) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 8.h),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: context.borderSecondary)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Button(
                      variant: ButtonVariant.text,
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    Button(
                      variant: ButtonVariant.text,
                      foregroundColor: context.textBrandPrimary900,
                      onPressed: () {
                        // 4. 确认选择：DateTime -> String -> Update Field
                        final formatted = DateFormat('yyyy-MM-dd').format(tempDate);

                        field.control.value = formatted;
                        field.control.markAsTouched();

                        Navigator.pop(ctx);
                      },
                      child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // 滚动选择器
              SizedBox(
                height: pickerHeight,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate,
                  minimumDate: minDate,
                  maximumDate: maxDate,
                  onDateTimeChanged: (DateTime newDate) {
                    tempDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}