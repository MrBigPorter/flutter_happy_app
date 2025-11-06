import 'package:flutter/cupertino.dart';

class LuckyItemScope extends InheritedWidget {
  final String name;
  final String? errorText;
  final bool hasError;
  final bool touchedOrDirty;

  const LuckyItemScope({
    super.key,
    required this.name,
    this.errorText,
    this.hasError = false,
    this.touchedOrDirty = false,
    required super.child,
  });

  static LuckyItemScope of(BuildContext c) {
    final s = c.dependOnInheritedWidgetOfExactType<LuckyItemScope>();
    assert(s != null, 'No LuckyItemScope found in context');
    return s!;
  }

  @override
  bool updateShouldNotify(LuckyItemScope oldWidget) =>
      oldWidget.errorText != errorText ||
      oldWidget.hasError != hasError ||
      oldWidget.touchedOrDirty != touchedOrDirty;
}
