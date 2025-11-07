import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../core/lf_core.dart';
import '../core/lf_field.dart';

typedef LfDecorationBuilder = InputDecoration Function(
    BuildContext context,
    InputDecoration base,
    );

class LfPassword extends StatefulWidget {
  final String name;
  final String? label, hint, helper;
  final LfLabelMode labelMode;
  final Map<String, String Function(Object?)>? validationMessages;

  /// 单字段装饰二次加工（会在“落边框之后”执行，能覆盖一切）
  final LfDecorationBuilder? decorationBuilder;

  /// 长按图标时临时明文（默认 true）
  final bool peekOnLongPress;

  /// 自定义图标（可换为自家 SVG）
  final Widget Function(bool obscured)? iconBuilder;

  /// 可监听显隐变化
  final void Function(bool obscured)? onVisibilityChanged;

  const LfPassword({
    super.key,
    required this.name,
    this.label,
    this.hint,
    this.helper,
    this.labelMode = LfLabelMode.external,
    this.validationMessages,
    this.decorationBuilder,
    this.peekOnLongPress = true,
    this.iconBuilder,
    this.onVisibilityChanged,
  });

  @override
  State<LfPassword> createState() => _LfPasswordState();
}

class _LfPasswordState extends State<LfPassword> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return LfField<String>(
      name: widget.name,
      label: widget.label,
      hint: widget.hint,
      labelMode: widget.labelMode,
      validationMessages: widget.validationMessages,

      // 放到“最后一步”执行，确保能覆盖默认/共享/边框等设置
      decorationBuilder: (ctx, base) {
        // 先让外部自定义 builder 处理（如果传了）
        var deco = widget.decorationBuilder?.call(ctx, base) ?? base;

        // 小眼睛按钮（支持点击切换 & 长按预览）
        final eyeBtn = GestureDetector(
          onLongPressStart: widget.peekOnLongPress
              ? (_) => setState(() => _obscure = false)
              : null,
          onLongPressEnd: widget.peekOnLongPress
              ? (_) => setState(() => _obscure = true)
              : null,
          child: IconButton(
            visualDensity: VisualDensity.compact,
            splashRadius: 18,
            iconSize: 18,
            onPressed: () {
              setState(() => _obscure = !_obscure);
              widget.onVisibilityChanged?.call(_obscure);
            },
            icon: widget.iconBuilder?.call(_obscure) ??
                Icon(_obscure ? Icons.visibility : Icons.visibility_off, size: 18),
          ),
        );

        // 如果已经有 suffixIcon，则合并；否则放一个固定宽度并居中
        final mergedSuffix = deco.suffixIcon != null
            ? Row(mainAxisSize: MainAxisSize.min, children: [
          deco.suffixIcon!,
          eyeBtn,
        ])
            : SizedBox(width: 36, child: Center(child: eyeBtn));

        return deco.copyWith(
          suffixIcon: mergedSuffix,
          // 取消 Material 默认的 48x48 约束，保证真正居中与紧凑
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        );
      },

      builder: (ctx, decoration, textStyle) => ReactiveTextField<String>(
        formControlName: widget.name,
        obscureText: _obscure,
        keyboardType: TextInputType.visiblePassword,
        autofillHints: const [AutofillHints.password],
        enableSuggestions: false,
        autocorrect: false,
        textAlignVertical: TextAlignVertical.center,

        style: textStyle,
        validationMessages: widget.validationMessages,
        decoration: decoration,
      ),
    );
  }
}