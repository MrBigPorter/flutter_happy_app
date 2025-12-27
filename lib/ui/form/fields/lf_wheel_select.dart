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
  final String? placeholder;
  final LfLabelMode labelMode;
  final bool readOnly;
  final bool? required;

  //  1. 新增 isLoading 参数
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

    //  默认为 false
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

            // 获取当前值和对应的显示文本
            final value = field.value;
            String displayText = '';

            for (final opt in options) {
              if (opt.value == value) {
                displayText = opt.text;
                break;
              }
            }

            final hasValue = value != null && displayText.isNotEmpty;

            //  2. 处理右侧图标：加载中显示转圈，否则显示箭头
            Widget suffixWidget;
            if (isLoading) {
              suffixWidget = Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: SizedBox(
                  width: 20.r,
                  height: 20.r,
                  child: const CupertinoActivityIndicator(), // 菊花转圈
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

            // 合并装饰器
            final effectiveDecoration = baseDecoration.copyWith(
              errorText: field.errorText,
              hintText: null,
              suffixIcon: suffixWidget, // 使用新的 suffix
            );

            //  3. 处理显示文本：加载中显示 Loading...
            String textToShow;
            if (isLoading) {
              textToShow = 'Loading...';
            } else if (hasValue) {
              textToShow = displayText;
            } else {
              textToShow = placeholder ?? '';
            }

            // 文本样式：加载中或无值时，使用灰色 Hint 样式
            final effectiveTextStyle = (hasValue && !isLoading)
                ? textStyle
                : (baseDecoration.hintStyle ?? Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).hintColor,
            ));

            // 交互区域
            return InkWell(
              //  4. 加载中禁止点击 (返回 null)
              onTap: readOnly || field.control.disabled || isLoading
                  ? null
                  : () => _showWheelPicker(context, field),
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: effectiveDecoration,
                // 当加载中时，视为不为空(为了把label顶上去)，或者根据你的设计调整
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

  void _showWheelPicker(BuildContext context, ReactiveFormFieldState<T, T> field) {
    //  强制收起键盘，防止页面跳动
    FocusScope.of(context).unfocus();

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
                          // 确认选择
                          field.control.value = options[tempIndex].value;
                          field.control.markAsTouched();
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