import 'package:flutter_app/ui/modal/base/base_modal_config.dart';

/// Configuration class for modal sheet behavior and appearance
class ModalSheetConfig extends BaseModalConfig {
  /// Minimum height of the modal sheet
  final double minHeight;

  /// Maximum height factor relative to screen height (0.0 to 1.0)
  final double maxHeightFactor;

  /// Whether the sheet can be dismissed by dragging down
  final bool? enableDragToClose;

  /// Distance threshold in pixels to trigger drag-to-close
  final double dragToCloseThreshold;

  final bool? showThumb;

  const ModalSheetConfig({
    this.minHeight = 100,
    this.maxHeightFactor = 0.7,
    this.enableDragToClose = true,
    this.dragToCloseThreshold = 40,
    this.showThumb = false,
    super.theme,
    super.borderRadius,
    super.animationStyleConfig,
    super.headerHeight,
    super.headerBuilder,
    super.showCloseButton,
    super.enableHeader,
    bool? allowBackgroundCloseOverride,
  });
}