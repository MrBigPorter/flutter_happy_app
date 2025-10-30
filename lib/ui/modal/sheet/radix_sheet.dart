import 'package:flutter/material.dart';
import 'modal_service.dart';
import 'modal_sheet_config.dart';

/// RadixSheet
/// ------------------------------------------------------------------
/// Unified entry point for bottom sheet display.
/// - Uses ModalService internally to implement showModalBottomSheet
/// - Automatically supports closing on background click, drag to close, rounded corners, theme syncing
/// - No built-in scroll logic (determined by content)
///
/// ✅ Short content auto-adapts height
/// ✅ Long content needs external SingleChildScrollView wrapper
/// ------------------------------------------------------------------
class RadixSheet {
  static Future<T?> show<T>({
    required Widget Function(BuildContext context, void Function([T? res]) close) builder,
    bool clickBgToClose = true,
    bool showClose = true,
    ModalSheetConfig? config,
  }) {
    // Uses unified ModalService for managing display and closing logic
    return ModalSheetService.instance.showSheet<T>(
      builder: builder,
      clickBgToClose: clickBgToClose,
      config: config ?? const ModalSheetConfig(),
    );
  }
}