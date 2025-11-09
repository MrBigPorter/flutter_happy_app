import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../core/lf_field.dart';

typedef Vm = Map<String, String Function(Object?)>;

class LfTextArea extends StatelessWidget {
  final String name;
  final String? label, hint, helper;
  final LfLabelMode labelMode;
  final Vm? validationMessages;

  // 行数控制
  final int? minLines;          // 固定/最小行
  final int? maxLines;          // 固定/最大行
  final bool autoGrow;          // 自动增高（到 maxLines；maxLines=null 则无限）
  final bool expands;           // 填满父容器（expands=true 时 min/max 需为 null）

  // 输入限制/计数器
  final int? maxLength;
  final bool showCounter;

  // 键盘与输入
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  // 单字段装饰二次加工（与 LfInput 一致）
  final InputDecoration Function(BuildContext ctx, InputDecoration base)? decorationBuilder;

  // 文本样式覆盖
  final TextStyle? style;

  const LfTextArea({
    super.key,
    required this.name,
    this.label,
    this.hint,
    this.helper,
    this.labelMode = LfLabelMode.external,
    this.validationMessages,
    this.minLines = 3,
    this.maxLines = 6,
    this.autoGrow = true,
    this.expands = false,
    this.maxLength,
    this.showCounter = true,
    this.textInputAction,
    this.inputFormatters,
    this.decorationBuilder,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return LfField<String>(
      name: name,
      label: label,
      hint: hint,
      helper: helper,
      labelMode: labelMode,
      validationMessages: validationMessages,
      decorationBuilder: decorationBuilder,
      builder: (ctx, decoration, textStyle) {
        final bool useExpands = expands;
        final int? resolvedMin = useExpands ? null : (autoGrow ? 1 : (minLines ?? 3));
        final int? resolvedMax = useExpands ? null : (autoGrow ? (maxLines ?? null) : (maxLines ?? 6));

        return ReactiveTextField<String>(

          formControlName: name,
          keyboardType: TextInputType.multiline,
          textInputAction: textInputAction ?? TextInputAction.newline,
          inputFormatters: inputFormatters,
          minLines: resolvedMin,
          maxLines: resolvedMax,
          expands: useExpands,
          maxLength: maxLength,
          style: style ?? textStyle,
          validationMessages: validationMessages,
          buildCounter: (ctx, {required int currentLength, int? maxLength, required bool isFocused}) {
            if (!showCounter || maxLength == null) return const SizedBox.shrink();
            return Text('$currentLength / $maxLength', style: Theme.of(ctx).textTheme.bodySmall);
          },
          decoration: decoration,
        );
      },
    );
  }
}