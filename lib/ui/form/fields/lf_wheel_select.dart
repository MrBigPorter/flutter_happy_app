import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/ui/modal/sheet/modal_sheet_config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../../button/variant.dart';
import '../core/lf_field.dart';
import '../core/types.dart';
import 'lf_select.dart';

class LfWheelSelect<T> extends StatelessWidget {
  final String name;
  final String? label;
  final String? helper;
  final String? placeholder;
  final LfLabelMode labelMode;
  final bool readOnly;
  final List<LfSelectOption<T>> options;
  final Map<String, String Function(Object?)>? validationMessages;
  final double pickerHeight;

  const LfWheelSelect({
    super.key,
    required this.name,
    required this.options,
    this.label,
    this.helper,
    this.placeholder,
    this.labelMode = LfLabelMode.external,
    this.readOnly = false,
    this.validationMessages,
    this.pickerHeight = 250,
  });

  @override
  Widget build(BuildContext context) {
    return LfField<T>(
      name: name,
      label: label,
      helper: helper,
      labelMode: labelMode,
      validationMessages: validationMessages,
      readOnly: readOnly,
      builder: (ctx, decoration, textStyle) {
        // 1. 安全获取 Control
        final rootForm = ReactiveForm.of(context);
        AbstractControl<T>? control;

        if (rootForm is FormGroup) {
          control = rootForm.control(name) as AbstractControl<T>?;
        } else if (rootForm is FormArray) {
          try {
            control = (rootForm as dynamic).control(name) as AbstractControl<T>?;
          } catch (_) {}
        }

        if (control == null) {
          return Text('Error: Control "$name" not found', style: TextStyle(color: Theme.of(context).colorScheme.error));
        }

        // 2. 监听值变化
        return ReactiveValueListenableBuilder<T>(
          formControl: control,
          builder: (context, control, child) {

            //  修复点：使用循环查找，避免 "null as T" 的强制转换错误
            String displayText = '';

            // 遍历 options 找到匹配 value 的项
            for (final opt in options) {
              if (opt.value == control.value) {
                displayText = opt.text;
                break;
              }
            }

            // 判断是否有有效值（非空且在选项中找到了对应的文本）
            final hasValue = control.value != null && displayText.isNotEmpty;

            return InkWell(
              onTap: readOnly || control.disabled
                  ? null
                  : () => _showWheelPicker(context, control),
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: decoration.copyWith(
                  suffixIcon: decoration.suffixIcon ??
                       Padding(
                        padding: EdgeInsets.only(right: 12.w),
                        child: Icon(
                          Icons.arrow_drop_down,
                          size: 24.r,
                          color: control.disabled
                              ? Theme.of(context).disabledColor
                              : Theme.of(context).iconTheme.color,
                        ),
                       ),
                  hintText: placeholder,
                ),
                isEmpty: !hasValue,
                child: Text(
                  hasValue ? displayText : (placeholder ?? ''),
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

  void _showWheelPicker(BuildContext context, AbstractControl<T> control) {
    int initialIndex = options.indexWhere((e) => e.value == control.value);
    if (initialIndex < 0) initialIndex = 0;

    int tempIndex = initialIndex;

    RadixSheet.show(
      config: ModalSheetConfig(
        enableHeader: false
      ),
      builder: (ctx,close){
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:  EdgeInsets.symmetric(horizontal: 16.r, vertical: 8.h),
                decoration:  BoxDecoration(
                  border: Border(bottom: BorderSide(color:context.borderSecondary )),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Button(
                      variant: ButtonVariant.text,
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel',),
                    ),
                    Button(
                      variant: ButtonVariant.text,
                      foregroundColor: context.textBrandPrimary900,
                      onPressed: () {
                        if (options.isNotEmpty) {
                          control.value = options[tempIndex].value;
                          control.markAsTouched();
                        }
                        Navigator.pop(ctx);
                      },
                      child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: pickerHeight,
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(initialItem: initialIndex),
                  onSelectedItemChanged: (index) {
                    tempIndex = index;
                  },
                  children: options.map((option) {
                    return Center(
                      child: Text(
                        option.text,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: option.disabled ? context.textDisabled : context.textBrandPrimary900,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}