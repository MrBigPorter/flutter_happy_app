import 'package:flutter/material.dart';

typedef LfDecorationBuilder = InputDecoration Function(
    BuildContext context,
    InputDecoration base,
    );

@immutable
class LfSharedProps {
  final EdgeInsetsGeometry? contentPadding;
  final bool? filled;
  final Color? fillColor;

  final TextStyle? inputStyle;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final double labelGap;

  final LfDecorationBuilder? decorationBuilder;

  /// 通用校验文案映射
  final Map<String, String Function(Object?)>? validationMessages;

  const LfSharedProps({
    this.contentPadding,
    this.filled,
    this.fillColor,
    this.inputStyle,
    this.hintStyle,
    this.labelStyle,
    this.labelGap = 6,
    this.decorationBuilder,
    this.validationMessages,
  });

  LfSharedProps copyWith({
    EdgeInsetsGeometry? contentPadding,
    bool? filled,
    Color? fillColor,
    TextStyle? inputStyle,
    TextStyle? hintStyle,
    TextStyle? labelStyle,
    double? labelGap,
    LfDecorationBuilder? decorationBuilder,
    Map<String, String Function(Object?)>? validationMessages,
  }) {
    return LfSharedProps(
      contentPadding: contentPadding ?? this.contentPadding,
      filled: filled ?? this.filled,
      fillColor: fillColor ?? this.fillColor,
      inputStyle: inputStyle ?? this.inputStyle,
      hintStyle: hintStyle ?? this.hintStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      labelGap: labelGap ?? this.labelGap,
      decorationBuilder: decorationBuilder ?? this.decorationBuilder,
      validationMessages: validationMessages ?? this.validationMessages,
    );
  }

  /// 合并：local 优先，其次 parent，再其次 Theme
  LfSharedProps merge(LfSharedProps? other) {
    if (other == null) return this;
    return LfSharedProps(
      contentPadding: other.contentPadding ?? contentPadding,
      filled: other.filled ?? filled,
      fillColor: other.fillColor ?? fillColor,
      inputStyle: other.inputStyle ?? inputStyle,
      hintStyle: other.hintStyle ?? hintStyle,
      labelStyle: other.labelStyle ?? labelStyle,
      labelGap: other.labelGap != 6 ? other.labelGap : labelGap,
      decorationBuilder: other.decorationBuilder ?? decorationBuilder,
      validationMessages: {
        ...?validationMessages,
        ...?other.validationMessages,
      },
    );
  }
}

class LfDefaults extends InheritedWidget {
  final LfSharedProps props;

  const LfDefaults({
    super.key,
    required this.props,
    required super.child,
  });

  static LfSharedProps of(BuildContext context) {
    final d = context.dependOnInheritedWidgetOfExactType<LfDefaults>();
    return d?.props ?? const LfSharedProps();
  }

  /// 允许局部叠加：LfDefaults.merge(child, props: …)
  factory LfDefaults.merge({
    Key? key,
    required BuildContext context,
    required Widget child,
    required LfSharedProps props,
  }) {
    final parent = LfDefaults.of(context);
    return LfDefaults(
      key: key,
      props: parent.merge(props),
      child: child,
    );
  }

  @override
  bool updateShouldNotify(LfDefaults oldWidget) => oldWidget.props != props;
}