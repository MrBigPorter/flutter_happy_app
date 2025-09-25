// lib/theme/rem.dart
import 'package:flutter/widgets.dart';

double rem(BuildContext context, double px, {double baseWidth = 375, double freezeAt = 768}) {
  final w = MediaQuery.of(context).size.width;
  if (w >= freezeAt) return px;            // 平板/桌面不再放大
  return px * (w / baseWidth);             // 手机按 375 等比缩放
}