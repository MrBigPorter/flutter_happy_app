import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/ui/modal/sheet/modal_sheet_config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../core/lf_field.dart';
import '../core/types.dart';
import 'lf_select.dart';

class LfWheelSelect<T> extends StatelessWidget {
  final String name;
  final String? label;
  final String? helper;
  final String? placeholder; // 占位提示语 (例如 "Please Select")
  final LfLabelMode labelMode;
  final bool readOnly;
  final bool? required;
  final List<LfSelectOption<T>> options;
  final Map<String, String Function(Object)>? validationMessages;
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
    this.required,
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
      required: required,
      validationMessages: null,
      readOnly: readOnly,
      builder: (ctx, baseDecoration, textStyle) {

        return ReactiveFormField<T, T>(
          formControlName: name,
          validationMessages: validationMessages,
          builder: (ReactiveFormFieldState<T, T> field) {

            // 1. 获取当前值和对应的显示文本
            final value = field.value;
            String displayText = '';

            // 安全查找对应的 Text
            for (final opt in options) {
              if (opt.value == value) {
                displayText = opt.text;
                break;
              }
            }

            final hasValue = value != null && displayText.isNotEmpty;

            // 2. 合并装饰器状态
            final effectiveDecoration = baseDecoration.copyWith(
              errorText: field.errorText,
              hintText: null,
              suffixIcon: baseDecoration.suffixIcon ??
                  Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: Icon(
                      Icons.arrow_drop_down,
                      size: 24.r,
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
                  : () => _showWheelPicker(context, field),
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: effectiveDecoration,
                // 当没有值时，isEmpty 为 true，这有助于 label 的浮动动画处理
                isEmpty: !hasValue,
                child: Text(
                  hasValue ? displayText : (placeholder ?? ''),
                  style: hasValue
                      ? textStyle // 有值：用正常文本样式
                      : (baseDecoration.hintStyle ?? // 没值：用提示文本样式(灰色)
                      Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).hintColor,
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

  void _showWheelPicker(BuildContext context, ReactiveFormFieldState<T, T> field) {
    // 获取当前 Control 的值
    final controlValue = field.value;

    int initialIndex = options.indexWhere((e) => e.value == controlValue);
    if (initialIndex < 0) initialIndex = 0;

    int tempIndex = initialIndex;

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
                        if (options.isNotEmpty) {
                          // 确认选择：更新值并触发校验
                          field.didChange(options[tempIndex].value);
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
      },
    );
  }
}