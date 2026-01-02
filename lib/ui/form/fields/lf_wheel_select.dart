import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../core/lf_field.dart';
import '../core/types.dart';

class LfWheelSelect<T> extends StatelessWidget {
  final String name;
  final String? label;
  final String? helper;
  final String? placeholder;
  final LfLabelMode labelMode;
  final bool readOnly;
  final bool? required;
  final bool isLoading;
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
    this.isLoading = false,
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
            final value = field.value;
            String displayText = '';

            for (final opt in options) {
              if (opt.value == value) {
                displayText = opt.text;
                break;
              }
            }

            final hasValue = value != null && displayText.isNotEmpty;

            Widget suffixWidget;
            if (isLoading) {
              suffixWidget = Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: SizedBox(
                  width: 20.r,
                  height: 20.r,
                  child: const CupertinoActivityIndicator(),
                ),
              );
            } else {
              suffixWidget = baseDecoration.suffixIcon ??
                  Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: Icon(
                      Icons.arrow_drop_down,
                      size: 24.r,
                      color: field.control.disabled
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).iconTheme.color,
                    ),
                  );
            }

            final effectiveDecoration = baseDecoration.copyWith(
              errorText: field.errorText,
              hintText: null,
              suffixIcon: suffixWidget,
            );

            String textToShow;
            if (isLoading) {
              textToShow = 'Loading...';
            } else if (hasValue) {
              textToShow = displayText;
            } else {
              textToShow = placeholder ?? '';
            }

            final effectiveTextStyle = (hasValue && !isLoading)
                ? textStyle
                : (baseDecoration.hintStyle ?? Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).hintColor,
            ));

            return InkWell(
              onTap: readOnly || field.control.disabled || isLoading
                  ? null
                  : () => _showWheelPicker(context, field),
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: effectiveDecoration,
                isEmpty: !hasValue && !isLoading,
                child: Text(
                  textToShow,
                  style: effectiveTextStyle,
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

  //  重点修改了这个方法
  void _showWheelPicker(BuildContext context, ReactiveFormFieldState<T, T> field) {
    // 1. 强制收起键盘
    FocusScope.of(context).unfocus();

    final controlValue = field.value;
    int initialIndex = options.indexWhere((e) => e.value == controlValue);
    if (initialIndex < 0) initialIndex = 0;
    int tempIndex = initialIndex;

    // 2. 替换 RadixSheet.show 为原生的 showModalBottomSheet
    // 这样可以避免触发 ModalSheetService 的互斥逻辑（导致上一个页面关闭）
    showModalBottomSheet(
      context: context,
      useRootNavigator: true, // 关键：确保 Picker 显示在最顶层，覆盖在 AddressManager 之上
      isScrollControlled: true, // 允许我们自定义高度和样式
      backgroundColor: Colors.transparent, // 背景透明，以便设置圆角
      builder: (ctx) {
        // 定义关闭方法，方便复用
        void close() => Navigator.of(ctx).pop();

        return Container(
          decoration: BoxDecoration(
            color: context.bgPrimary, // 使用你的主题色
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部工具栏 (Cancel / Done)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 8.h),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: context.borderSecondary)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Cancel 按钮
                      Button(
                        variant: ButtonVariant.text,
                        onPressed: () => close(),
                        child: const Text('Cancel'),
                      ),
                      // Done 按钮
                      Button(
                        variant: ButtonVariant.text,
                        foregroundColor: context.textBrandPrimary900,
                        onPressed: () {
                          if (options.isNotEmpty) {
                            // 确认选择
                            field.control.value = options[tempIndex].value;
                            field.control.markAsTouched();
                          }
                          close();
                        },
                        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                // 选择器滚轮
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
                            // 处理禁用状态颜色
                            color: option.disabled
                                ? context.textDisabled
                                : context.textBrandPrimary900,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}