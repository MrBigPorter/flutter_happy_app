
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/ui/modal/base/animation_policy_config.dart';
import 'package:flutter_app/ui/modal/base/modal_theme.dart';


/// Base configuration class for modal dialogs and sheets.
/// Provides common customization options for appearance and behavior of modals.
/// This abstract class serves as a foundation for specific modal configurations.

typedef FooterBuilder<T> = Widget Function(BuildContext context, void Function([Object? result]) close);
typedef HeaderBuilder = Widget Function(BuildContext context, void Function([Object? result]) close);
enum CloseButtonAlignment {
  topRight,
  topLeft,
  topCenter,
}

abstract class BaseModalConfig {
  /// Theme configuration for the modal, controls colors and visual styling
  final ModalTheme theme;

  /// Border radius for the modal's corners in logical pixels
  /// Default value is 16
  final double borderRadius;

  /// Configuration for modal animation style and behavior
  /// Default is minimal animation style
  final AnimationStyleConfig animationStyleConfig;

  /// Optional override for allowing modal dismissal by tapping background
  /// If null, uses default behavior defined by specific modal implementation
  final bool? allowBackgroundCloseOverride;

  final FooterBuilder? footerBuilder;

  final CloseButtonAlignment closeButtonAlignment;

  final double headerHeight;

  final HeaderBuilder? headerBuilder;

  final bool showCloseButton;


  const BaseModalConfig({
    this.theme = const ModalTheme(),
    this.borderRadius = 16,
    this.animationStyleConfig = AnimationStyleConfig.minimal,
    this.allowBackgroundCloseOverride,
    this.footerBuilder,
    this.closeButtonAlignment = CloseButtonAlignment.topRight,
    this.headerHeight = 50,
    this.headerBuilder,
    this.showCloseButton = true,
  });
}