
import 'package:flutter/cupertino.dart';

enum CloseButtonAlignment {
  topRight,
  topLeft,
  topCenter,
}

class ModalSheetConfig {
  final ModalSheetTheme theme;
  final double borderRadius;
  final double maxWidth;
  final double minWidth;
  final double minHeight;
  final double maxHeightFactor; // height = screenHeight * factor
  final EdgeInsets contentPadding;
  final bool enableDragToClose;
  final double dragToCloseThreshold; // drag offset
  final bool showCloseButton;
  final CloseButtonAlignment closeAlignment;

  const ModalSheetConfig({
    this.borderRadius = 16,
    this.maxWidth = double.infinity,
    this.minWidth = double.infinity,
    this.minHeight = 100,
    this.maxHeightFactor = 0.9,
    this.contentPadding = const EdgeInsets.fromLTRB(16, 20, 16, 20),
    this.enableDragToClose = true,
    this.dragToCloseThreshold = 40,
    this.showCloseButton = true,
    this.closeAlignment = CloseButtonAlignment.topRight,
    this.theme = const ModalSheetTheme(),
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
    );
  }
}

class ModalSheetTheme {
  final Color? barrierColor; // 背景遮罩
  final Color? surfaceColor; // 面板背景色

  const ModalSheetTheme({
    this.barrierColor,
    this.surfaceColor,
  });
}