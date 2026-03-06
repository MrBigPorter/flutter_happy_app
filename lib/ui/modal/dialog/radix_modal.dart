import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/modal/base/animation_effects.dart';
import 'package:flutter_app/ui/modal/dialog/modal_dialog_config.dart';
import 'package:flutter_app/ui/modal/dialog/modal_dialog_surface.dart';
import 'package:flutter_app/ui/modal/base/modal_auto_close_observer.dart';
import 'package:flutter_app/ui/modal/base/nav_hub.dart';
import 'package:flutter_app/ui/modal/progress/modal_progress_observer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../base/animation_policy_resolver.dart';

typedef ModalAction<T> = FutureOr<void> Function(void Function([T? result]) close);

/// Modal
/// ------------------------------------------------------------------
class RadixModal {

  /// Shows a modal dialog with customizable content and behavior
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

        bool isPopping = false;

        void finish([T? res]) {
          if (isPopping) return;

          // 终极修复：严格检测当前弹窗是否为栈顶！
          // 如果上面还有别的弹窗，或者别的弹窗正在退出，一律忽略点击，保护 isPopping 不被错误锁死！
          final route = ModalRoute.of(ctx);
          if (route == null || !route.isCurrent) return;

          isPopping = true;

          if (ctx.mounted) {
            // 既然确定了我们在栈顶，直接用强杀 pop，不再给 maybePop 拒绝的机会！
            Navigator.pop(ctx, res);
          }
        }

        ModalManager.instance.bind(()=> finish());

        final content = SafeArea(
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

        return ModalProgressObserver(child: content);
      },
    );
  }
}