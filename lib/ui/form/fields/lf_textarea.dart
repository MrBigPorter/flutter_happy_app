import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../core/lf_field.dart';
import '../core/lf_core.dart';

typedef Vm = Map<String, String Function(Object?)>;

class LfTextArea extends StatelessWidget {
  final String name;
  final String? label, hint, helper;
  final LfLabelMode labelMode;
  final Vm? validationMessages;

  /// 行数控制
  final int? minLines;            // 固定/最小行
  final int? maxLines;            // 固定/最大行
  final bool autoGrow;            // 自动增高（直到 maxLines；为 null 表示不限制）
  final bool expands;             // 填满父容器（注意：expands=true 时 min/max 需为 null）

  /// 输入限制/计数器
  final int? maxLength;
  final bool showCounter;

  /// 键盘与输入
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  /// 单字段装饰二次加工（与 LfInput 一致）
  final InputDecoration Function(BuildContext ctx, InputDecoration base)? decorationBuilder;

  /// 可覆写样式（否则走主题）
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
      // 透传单字段装饰加工
      decorationBuilder: decorationBuilder,
      builder: (ctx, decoration, textStyle) {
        // 计算行数策略：
        final bool useExpands = expands;
        final int? resolvedMin =
        useExpands ? null : (autoGrow ? 1 : (minLines ?? 3));
        final int? resolvedMax =
        useExpands ? null : (autoGrow ? (maxLines ?? null) : (maxLines ?? 6));

        return ReactiveTextField<String>(
          formControlName: name,
          keyboardType: TextInputType.multiline,
          textInputAction: textInputAction ?? TextInputAction.newline,
          inputFormatters: inputFormatters,
          minLines: resolvedMin,
          maxLines: resolvedMax,   // autoGrow=true 且 maxLines=null 时无限增高
          expands: useExpands,
          maxLength: maxLength,
          // 统一文本样式
          style: style ?? textStyle,
          validationMessages: validationMessages,
          // 计数器展示控制
          buildCounter: (ctx, {required int currentLength, int? maxLength, required bool isFocused}) {
            if (!showCounter || maxLength == null) return const SizedBox.shrink();
            return Text('$currentLength / $maxLength',
                style: Theme.of(ctx).textTheme.bodySmall);
          },
          decoration: decoration,
        );
      },
    );
  }
}