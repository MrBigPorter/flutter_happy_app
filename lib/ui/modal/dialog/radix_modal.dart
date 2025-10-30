
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/modal/base/animation_effects.dart';
import 'package:flutter_app/ui/modal/dialog/modal_dialog_config.dart';
import 'package:flutter_app/ui/modal/dialog/modal_dialog_surface.dart';
import 'package:flutter_app/ui/modal/base/modal_auto_close_observer.dart';
import 'package:flutter_app/ui/modal/base/nav_hub.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../base/animation_policy_resolver.dart';

typedef ModalAction<T> = void Function(void Function([T? result]) close);


/// RadixModal
/// ------------------------------------------------------------------
/// A utility class for displaying modal dialogs with customizable animations,
/// themes and behaviors.
/// 
/// Features:
/// - Customizable animations and transitions
/// - Support for background blur effects
/// - Built-in confirm/cancel actions
/// - Backdrop click handling
/// - Theme integration
/// - MyAnimationStyleConfig：
/// - ModalDialogConfig：
///   - maxWidth: Maximum width of the dialog
///   - contentPadding: Padding for the dialog content
///   - customHeader: Custom header widget
///   - footerBuilder: Function to build custom footer
///   - headerHeight: Height of the header
///   - headerActions: Additional actions in the header
///   - headerBackgroundColor: Background color of the header
///   - ModalTheme: Theme settings for the dialog
///   - AnimationStyleConfig: Animation style settings
///   - borderRadius: Border radius of the dialog
///   - allowBackgroundCloseOverride: Override for background close behavior
/// Usage:
/// ```dart
/// await RadixModal.show(
///  builder: (context, close) => MyDialogContent(onClose: close),
///  config: ModalDialogConfig(
///  animationStyleConfig: MyAnimationStyleConfig(),
///  theme: MyModalTheme(),
///  ),
///  onConfirm: (close) {
///  // Handle confirm action
///  close();
///  },
///  onCancel: (close) {
///  // Handle cancel action
///  close();
///  },
///  );
///  ```
///
/// ------------------------------------------------------------------
class RadixModal {

  /// Shows a modal dialog with customizable content and behavior
  ///
  /// Parameters:
  /// - [builder] Required callback to build the dialog content
  /// - [config] Dialog configuration including animation and theme settings
  /// - [clickBgToClose] Whether clicking backdrop closes the dialog
  /// - [confirmText] Text for the confirm button
  /// - [cancelText] Text for the cancel button
  /// - [onConfirm] Callback when confirm is pressed
  /// - [onCancel] Callback when cancel is pressed
  /// - [title] Optional dialog title
  ///
  /// Returns a [Future] that completes with an optional result value when
  /// the dialog is closed.
  static Future<T?> show<T>({
    required Widget Function(BuildContext, void Function([T? res])) builder,
    ModalDialogConfig config = const ModalDialogConfig(),
    bool clickBgToClose = true,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    ModalAction<T>? onConfirm,
    ModalAction<T>? onCancel,
    String? title,
  }) {
    final nav = NavHub.key.currentState;
    if(nav == null || !nav.mounted) {
      throw Exception('ModalService navigator is not initialized.');
    }

    final ctx = nav.context;
    final theme = Theme.of(ctx);
    final policy = AnimationPolicyResolver.resolve(
      businessStyle: config.animationStyleConfig,
      globalPolicy: null,
    );


    final allowBgClose =
        (config.allowBackgroundCloseOverride ?? policy.allowBackgroundClose) &&
        clickBgToClose;

    final barrierColor =
        config.theme.barrierColor ??
        theme.colorScheme.scrim.withValues(alpha: 0.5);
    final surfaceColor = config.theme.surfaceColor ?? theme.colorScheme.surface;

    return showGeneralDialog(
      context: ctx,
      barrierDismissible: allowBgClose,
      barrierLabel: allowBgClose ? MaterialLocalizations.of(ctx).modalBarrierDismissLabel : null,
      transitionDuration: policy.inDuration,
      barrierColor: Colors.transparent,
      transitionBuilder: (ctx, anim, secAnim, child) {
        return buildModalTransition(
            anim,
            child,
            policy.style,
            allowBgClose: allowBgClose,
            barrierColor: barrierColor,
            blurSigma: policy.blurSigma,
            context: ctx,
        );
      },
      pageBuilder: (ctx, anima1, anima2) {
        void finish([T? res]) {
          if (Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop(res);
          }
        }

        ModalManager.instance.bind(()=> finish());

        return SafeArea(
          child: Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              constraints: BoxConstraints(maxWidth: config.maxWidth),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(config.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12.w,
                    offset: Offset(0, 4.w),
                  ),
                ],
              ),
              child: ModalDialogSurface<T>(
                title: title,
                config: config,
                onClose: finish,
                onConfirm: ()=> onConfirm != null ? onConfirm(finish) : finish(),
                onCancel: ()=> onCancel != null ? onCancel(finish) : finish(),
                confirmText: confirmText,
                cancelText: cancelText,
                child: builder(ctx, finish),
              ),
            ),
          ),
        );
      },
    );
  }
}


