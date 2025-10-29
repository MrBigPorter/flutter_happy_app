import 'package:flutter/material.dart';
import 'animation_policy_config.dart';

enum CloseButtonAlignment {
  topRight,
  topLeft,
  topCenter,
}

typedef FooterBuilder<T> = Widget Function(void Function([Object? result]) close);

class ModalSheetConfig {
  final ModalSheetTheme theme;
  final double borderRadius;
  final double maxWidth;           // 目前系统弹窗宽度按全屏处理，保留字段便于后续横屏/平板适配
  final double minWidth;
  final double minHeight;          // 用来推算 Draggable 的 minChildSize
  final double maxHeightFactor;    // 推算 Draggable 的 maxChildSize
  final EdgeInsets contentPadding;
  final bool? enableDragToClose;    // 映射到 showModalBottomSheet.enableDrag
  final double dragToCloseThreshold; // 系统实现不需要，保留字段
  final bool showCloseButton;
  final CloseButtonAlignment closeAlignment;

  final Widget? customHeader;
  final Widget? headerActions;
  final FooterBuilder? footerBuilder;
  final double? headerHeight;

  // 业务动画风格声明
  final AnimationStyleConfig animationStyleConfig;

  // 允许覆盖“是否点击背景可关闭”
  final bool? allowBackgroundCloseOverride;

  const ModalSheetConfig({
    this.theme = const ModalSheetTheme(),
    this.borderRadius = 16,
    this.maxWidth = double.infinity,
    this.minWidth = double.infinity,
    this.minHeight = 100,
    this.maxHeightFactor = 0.7,
    this.contentPadding = const EdgeInsets.fromLTRB(16, 20, 16, 20),
    this.enableDragToClose = true,
    this.dragToCloseThreshold = 40,
    this.showCloseButton = true,
    this.closeAlignment = CloseButtonAlignment.topRight,
    this.animationStyleConfig = AnimationStyleConfig.minimal,
    this.allowBackgroundCloseOverride,

    this.customHeader,
    this.headerActions,
    this.footerBuilder,
    this.headerHeight,
  });

  ModalSheetConfig copyWith({
    ModalSheetTheme? theme,
    double? borderRadius,
    double? maxWidth,
    double? minWidth,
    double? minHeight,
    double? maxHeightFactor,
    EdgeInsets? contentPadding,
    bool? enableDragToClose,
    double? dragToCloseThreshold,
    bool? showCloseButton,
    CloseButtonAlignment? closeAlignment,
    AnimationStyleConfig? animationStyleConfig,
    bool? allowBackgroundCloseOverride,

    Widget? customHeader,
    Widget? headerActions,
    FooterBuilder? footerBuilder,
    double? headerHeight,
  }) {
    return ModalSheetConfig(
      theme: theme ?? this.theme,
      borderRadius: borderRadius ?? this.borderRadius,
      maxWidth: maxWidth ?? this.maxWidth,
      minWidth: minWidth ?? this.minWidth,
      minHeight: minHeight ?? this.minHeight,
      maxHeightFactor: maxHeightFactor ?? this.maxHeightFactor,
      contentPadding: contentPadding ?? this.contentPadding,
      enableDragToClose: enableDragToClose ?? this.enableDragToClose,
      dragToCloseThreshold: dragToCloseThreshold ?? this.dragToCloseThreshold,
      showCloseButton: showCloseButton ?? this.showCloseButton,
      closeAlignment: closeAlignment ?? this.closeAlignment,
      animationStyleConfig: animationStyleConfig ?? this.animationStyleConfig,
      allowBackgroundCloseOverride: allowBackgroundCloseOverride ?? this.allowBackgroundCloseOverride,

      customHeader: customHeader ?? this.customHeader,
      headerActions: headerActions ?? this.headerActions,
      footerBuilder: footerBuilder ?? this.footerBuilder,
      headerHeight: headerHeight ?? this.headerHeight,
    );
  }
}

class ModalSheetTheme {
  final Color? barrierColor; // 背景遮罩
  final Color? surfaceColor; // 面板背景色

  const ModalSheetTheme({ this.barrierColor, this.surfaceColor });
}