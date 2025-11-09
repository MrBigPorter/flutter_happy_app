import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../core/types.dart';
import '../ui_min.dart';
import '../core/lf_core.dart';

typedef LfRadioOption<T> = ({String text, T value, String? description, bool disabled});
typedef LfRadioItemBuilder<T> = Widget Function(
    BuildContext context,
    FormControl<T> control,
    LfRadioOption<T> option,
    bool selected,
    );

class LfRadioGroup<T> extends StatelessWidget {
  final String name;
  final String? label;
  final String? helper;
  final LfLabelMode labelMode;
  final Vm? validationMessages;

  final List<LfRadioOption<T>> options;

  /// 垂直/水平；水平可 wrap 换行
  final Axis direction;
  final bool wrap;
  final double gap;
  final double runGap;

  final LfRadioItemBuilder<T>? itemBuilder;

  final Color? activeColor;
  final EdgeInsetsGeometry? itemPadding;

  const LfRadioGroup({
    super.key,
    required this.name,
    required this.options,
    this.label,
    this.helper,
    this.labelMode = LfLabelMode.external,
    this.validationMessages,
    this.direction = Axis.vertical,
    this.wrap = false,
    this.gap = 8,
    this.runGap = 8,
    this.itemBuilder,
    this.activeColor,
    this.itemPadding,
  });

  @override
  Widget build(BuildContext context) {
    final t = formThemeOf(context);
    final theme = Theme.of(context);

    Widget field = ReactiveFormField<T, T>(
      formControlName: name,
      validationMessages: validationMessages,
      showErrors: (c) => c.invalid && (c.dirty || c.touched),
      builder: (reactiveField) {
        final control = reactiveField.control as FormControl<T>;
        final selected = control.value;
        final disabledAll = control.disabled;

        Widget defaultItem(LfRadioOption<T> o) {
          final disabled = o.disabled || disabledAll;

          return InkWell(
            onTap: disabled ? null : () => reactiveField.didChange(o.value),
            child: Padding(
              padding: itemPadding ?? const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.max,           // 占满行，避免被父 Column 居中
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Radio<T>(
                    value: o.value,
                    groupValue: selected,                  // 先用稳定 API，等你们升级再切 RadioGroup
                    onChanged: disabled
                        ? null
                        : (v) {
                      if (v != null) reactiveField.didChange(v as T);
                    },
                    activeColor: activeColor ?? Theme.of(context).colorScheme.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Opacity(
                          opacity: disabled ? 0.6 : 1,
                          child: Text(
                            o.text,
                            style: formThemeOf(context).textStyle
                                ?? Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (o.description != null)
                          Opacity(
                            opacity: disabled ? 0.6 : 0.9,
                            child: Text(
                              o.description!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final children = options.map((o) {
          final sel = selected == o.value;
          return itemBuilder?.call(context, control, o, sel) ?? defaultItem(o);
        }).toList();

        final optionsView = direction == Axis.vertical
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1) SizedBox(height: gap),
            ],
          ],
        )
            : (wrap
            ? Wrap(spacing: gap, runSpacing: runGap, children: children)
            : Row(children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) SizedBox(width: gap),
          ],
        ]));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            optionsView,
            if (reactiveField.errorText != null)
              Padding(
                padding: EdgeInsets.only(top: formThemeOf(context).spacing),
                child: Text(
                  reactiveField.errorText!,
                  style: formThemeOf(context).errorStyle
                      ?? Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
            if (helper != null)
              Padding(
                padding: EdgeInsets.only(top: formThemeOf(context).spacing),
                child: Text(
                  helper!,
                  style: formThemeOf(context).helperStyle
                      ?? Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        );
      },
    );

    // 占满父宽，避免父 Column 默认居中导致“整块看起来居中”
    return SizedBox(
      width: double.infinity,
      child: wrapExternalLabel(
        context,
        mode: labelMode,
        label: label,
        field: field,
      ),
    );
  }
}