import 'package:flutter/cupertino.dart';
import 'package:flutter_app/ui/modal/modal_sheet_theme.dart';

class ModalSheetConfig {
  final ModalSheetTheme theme;
  final double borderRadius;
  final double maxWidth;
  final double maxHeightFactor; // height = screenHeight * factor
  final EdgeInsets contentPadding;
  final bool enableDragToClose;
  final double dragToCloseThreshold; // drag offset
  final bool showCloseButton;
  final Alignment closeButtonAlignment;

  const ModalSheetConfig({
    this.borderRadius = 16,
    this.maxWidth = double.infinity,
    this.maxHeightFactor = 0.9,
    this.contentPadding = const EdgeInsets.fromLTRB(16, 20, 16, 20),
    this.enableDragToClose = true,
    this.dragToCloseThreshold = 40,
    this.showCloseButton = true,
    this.closeButtonAlignment = Alignment.topRight,
    this.theme = const ModalSheetTheme(),
  });
}