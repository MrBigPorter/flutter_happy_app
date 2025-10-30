import 'package:flutter/cupertino.dart';
import 'package:flutter_app/ui/modal/base/base_modal_config.dart';

/// FooterBuilder is a function type for building the dialog footer content
/// - Takes BuildContext and a close function as parameters
/// - Returns a Widget to be used as the footer content
/// typedef FooterBuilder = Widget Function(BuildContext context, void Function([dynamic result]) close);

/// ModalDialogConfig
/// ------------------------------------------------------------------
/// Configuration class specifically for dialog type modals, extending BaseModalConfig
///
/// Key features:
/// - Inherits base modal configurations from BaseModalConfig
/// - Provides dialog-specific settings like maxWidth, padding, custom header and footer
///
/// Parameters:
/// - maxWidth: Maximum width of the dialog (default: 400)
/// - contentPadding: Internal padding for dialog content (default: EdgeInsets.fromLTRB(24, 20, 24, 24))
/// - customHeader: Optional custom header widget
/// - footerBuilder: Optional builder function for dialog footer
/// - headerHeight: Optional custom header height
/// - headerActions: Optional widgets to display in header
/// - headerBackgroundColor: Optional header background color
/// - theme: Optional modal theme customization
/// - animationStyleConfig: Optional animation settings
/// - borderRadius: Optional border radius value
/// - allowBackgroundCloseOverride: Optional flag to enable/disable closing by clicking background
///
/// Example usage:
/// ```dart
/// final config = ModalDialogConfig(
///   maxWidth: 500,
///   contentPadding: EdgeInsets.all(16),
///   customHeader: MyCustomHeader(),
///   footerBuilder: (context, close) => MyDialogFooter(onClose: close),
///   headerHeight: 60,
///   headerActions: MyHeaderActions(),
///   theme: MyModalTheme(),
///   animationStyleConfig: MyAnimationStyleConfig(),
///   borderRadius: 12,
///   allowBackgroundCloseOverride: true,
/// );
/// ```
///

class ModalDialogConfig extends BaseModalConfig {
  final double maxWidth;
  final EdgeInsets contentPadding;
  final Color? headerBackgroundColor;

  const ModalDialogConfig({
    this.maxWidth = 400,
    this.contentPadding = const EdgeInsets.fromLTRB(24, 20, 24, 24),
    this.headerBackgroundColor,
    super.theme,
    super.animationStyleConfig,
    super.borderRadius,
    super.footerBuilder,
    super.headerHeight,
    super.headerBuilder,
    super.showCloseButton,
    bool? allowBackgroundCloseOverride,
  });
}