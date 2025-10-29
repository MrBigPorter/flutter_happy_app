import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/ui/modal/animation_policy_config.dart';
import 'package:flutter_app/ui/modal/animation_policy_resolver.dart';
import 'package:flutter_app/ui/modal/modal_auto_close_observer.dart';
import 'package:flutter_app/ui/modal/modal_service.dart';
import 'package:flutter_app/ui/modal/nav_hub.dart';
import 'package:flutter_app/ui/modal/sheet_props.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

typedef ModalAction<T> = void Function(void Function([T? result]) close);

class RadixModal {
  static Future<T?> show<T>({
    required Widget Function(BuildContext, void Function([T? res])) builder,

    ModalSheetConfig config = const ModalSheetConfig(),
    bool clickBgToClose = true,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    ModalAction<T>? onConfirm,
    ModalAction<T>? onCancel,
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
      barrierColor: barrierColor,
      transitionDuration: policy.inDuration,
      transitionBuilder: (ctx, anim, secAnim, child) {
        final curve = CurvedAnimation(
          parent: anim,
          curve: policy.inCurve,
          reverseCurve: policy.outCurve,
        );
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: policy.blurSigma,
                sigmaY: policy.blurSigma,
              ),
              child: Container(color: Colors.black.withValues(alpha: 0)),
            ),
            FadeTransition(
              opacity: curve,
              child: ScaleTransition(
                scale: Tween(begin: 0.9, end: 1.0).animate(
                  CurvedAnimation(
                    parent: curve,
                    curve: policy.style == AnimationStyleConfig.celebration
                        ? Curves.elasticOut
                        : Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            ),
          ],
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
              child: _ModalSurface<T>(
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

class _ModalSurface<T> extends StatelessWidget {
  final ModalSheetConfig config;
  final void Function([T? reslut]) onClose;
  final Widget child;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String confirmText;
  final String cancelText;

  const _ModalSurface({
    required this.config,
    required this.onClose,
    required this.child,
    required this.onConfirm,
    required this.onCancel,
    required this.confirmText,
    required this.cancelText,
  });

  @override
  Widget build(BuildContext context) {
    final hasFooter = config.footerBuilder != null;
    final hasConfirm = confirmText.isNotEmpty;
    final hasCancel = cancelText.isNotEmpty;
    // XOR，只有一个为 true only one button
    final isSingleButton = (hasConfirm ^ hasCancel);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (config.customHeader != null)
          config.customHeader!
        else
          Padding(
            padding: EdgeInsets.only(top: 16.w, bottom: 8.w),
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close, size: 22.w),
              ),
            ),
          ),
        Flexible(
          child: Padding(padding: config.contentPadding, child: child),
        ),
        Padding(
          padding: EdgeInsets.all(12.w),
          child: hasFooter
              ? config.footerBuilder!.call(([result]) => onClose(result as T?))
              : Row(
                  children: [
                    if(hasCancel)
                    Expanded(child: Button(variant:ButtonVariant.outline,onPressed: onCancel, child: Text(cancelText))),
                    if(!isSingleButton)
                      SizedBox(width: 12.w),
                    if(hasConfirm)
                    Expanded(
                      child: Button(
                        onPressed: onConfirm,
                        child: Text(confirmText),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
