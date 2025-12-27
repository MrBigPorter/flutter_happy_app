import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/button/variant.dart';
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
  final Map<String, String Function(Object?)>? validationMessages;
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
    this.validationMessages,
    this.pickerHeight = 250,
    this.minDate,
    this.maxDate,
  });

  @override
  Widget build(BuildContext context) {
    // 注意：这里的泛型是 String，因为你的 Model 存的是 "1999-01-01"
    return LfField<String>(
      name: name,
      label: label,
      helper: helper,
      labelMode: labelMode,
      validationMessages: validationMessages,
      readOnly: readOnly,
      builder: (ctx, decoration, textStyle) {

        // 1. 安全获取 Control (String 类型)
        final rootForm = ReactiveForm.of(context);
        AbstractControl<String>? control;

        if (rootForm is FormGroup) {
          control = rootForm.control(name) as AbstractControl<String>?;
        } else if (rootForm is FormArray) {
          try {
            control = (rootForm as dynamic).control(name) as AbstractControl<String>?;
          } catch (_) {}
        }

        if (control == null) {
          return Text('Error: Control "$name" not found', style: TextStyle(color: Theme.of(context).colorScheme.error));
        }

        // 2. 监听值变化
        return ReactiveValueListenableBuilder<String>(
          formControl: control,
          builder: (context, control, child) {
            final value = control.value;
            final hasValue = value != null && value.isNotEmpty;

            return InkWell(
              onTap: readOnly || control.disabled
                  ? null
                  : () => _showDatePicker(context, control),
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: decoration.copyWith(
                  suffixIcon: decoration.suffixIcon ??
                      Padding(
                        padding: EdgeInsets.only(right: 12.w),
                        child: Icon(
                          Icons.calendar_today, // 日历图标
                          size: 20.r,
                          color: control.disabled
                              ? Theme.of(context).disabledColor
                              : Theme.of(context).iconTheme.color,
                        ),
                      ),
                  hintText: placeholder,
                ),
                isEmpty: !hasValue,
                child: Text(
                  hasValue ? value : (placeholder ?? ''),
                  style: hasValue
                      ? textStyle
                      : (decoration.hintStyle ?? Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
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

  void _showDatePicker(BuildContext context, AbstractControl<String> control) {
    // 1. 解析初始值：String -> DateTime
    DateTime initialDate = DateTime.now();
    if (control.value != null && control.value!.isNotEmpty) {
      try {
        initialDate = DateFormat('yyyy-MM-dd').parse(control.value!);
      } catch (e) {
        print('Date parse error: $e');
      }
    } else if (maxDate != null) {
      // 如果没有值且是选生日，默认停在 maxDate (例如18年前)
      initialDate = maxDate!;
    }

    // 2. 边界保护
    if (minDate != null && initialDate.isBefore(minDate!)) initialDate = minDate!;
    if (maxDate != null && initialDate.isAfter(maxDate!)) initialDate = maxDate!;

    DateTime tempDate = initialDate;

    // 3. 弹出底部滚轮
    RadixSheet.show(
      config: ModalSheetConfig(
        enableHeader: false
      ),
      builder: (ctx,close){
        return  SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 工具栏
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black12)),
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
                        // 4. 确认选择：DateTime -> String (yyyy-MM-dd)
                        final formatted = DateFormat('yyyy-MM-dd').format(tempDate);
                        control.value = formatted;
                        control.markAsTouched();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // 滚动选择器本体
              SizedBox(
                height: pickerHeight,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date, // 只显示 年-月-日
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
      }
    );
  }
}