
import 'package:flutter/cupertino.dart';

/// 弹层面板相关的主题配置（字号、颜色、阴影等）
/// Theme configuration for modal panel (font size, color, shadow, etc.)
class ModalTheme {
  /// 背景遮罩色
  /// Background mask color
  final Color? barrierColor;

  /// 面板背景色
  /// Panel background color
  final Color? surfaceColor;

  /// 面板阴影
  /// Panel shadow
  final BoxShadow? boxShadow;

  /// 创建一个弹层面板主题配置
  /// Create a modal panel theme configuration
  const ModalTheme({this.barrierColor, this.surfaceColor, this.boxShadow});
}