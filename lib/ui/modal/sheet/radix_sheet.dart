import 'package:flutter/material.dart';
import 'modal_service.dart';
import 'modal_sheet_config.dart';

/// RadixSheet
/// ------------------------------------------------------------------
class RadixSheet {
  static Future<T?> show<T>({
    required Widget Function(BuildContext context, void Function([T? res]) close) builder,
    String? title,
    bool clickBgToClose = true,
    bool showClose = true,
    bool enableShrink = true,
    ModalSheetConfig? config,
    Widget? Function(BuildContext)? headerBuilder,
  }) {
    return ModalSheetService.instance.showSheet<T>(
      builder: builder,
      clickBgToClose: clickBgToClose,
      config: config ?? ModalSheetConfig(
          title: title,
          showCloseButton: showClose
      ),
      enableShrink: enableShrink,
      headerBuilder: headerBuilder,
    );
  }
}