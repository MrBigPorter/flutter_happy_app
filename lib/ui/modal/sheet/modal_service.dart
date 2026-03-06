import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/modal/base/modal_auto_close_observer.dart';
import 'package:flutter_app/ui/modal/base/nav_hub.dart';
import 'package:flutter_app/ui/modal/progress/modal_progress_observer.dart';
import 'package:flutter_app/ui/modal/sheet/modal_sheet_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../base/animation_policy_resolver.dart';
import '../progress/overlay_progress_provider.dart';
import 'animated_sheet_wrapper.dart';
import '../base/animation_policy_config.dart';
import 'sheet_surface.dart';

class ModalSheetService {
  ModalSheetService._();

  static final ModalSheetService instance = ModalSheetService._();

  AnimationPolicyConfig? globalPolicy;

  GlobalKey<NavigatorState> get navigatorKey => NavHub.key;

  final routeObserver = RouteObserver<ModalRoute>();

  Future<dynamic>? _sheetFuture;
  BuildContext? _sheetContext;

  bool get isShowing => _sheetFuture != null;

  Future<T?> showSheet<T>({
    required Widget Function(BuildContext, void Function([T? res])) builder,
    bool clickBgToClose = true,
    ModalSheetConfig config = const ModalSheetConfig(),
    Widget? Function(BuildContext)? headerBuilder,
    bool enableShrink = true,
  }) async {
    if (isShowing) {
      await close();
    }

    final policy = AnimationPolicyResolver.resolve(
      businessStyle: config.animationStyleConfig,
      globalPolicy: globalPolicy,
    );

    final nav = navigatorKey.currentState;
    if (nav == null) {
      throw Exception('ModalSheetService: Navigator not ready.');
    }

    if (!nav.mounted) return null;

    final ctx = nav.context;
    final theme = Theme.of(ctx);

    final allowBgClose = (config.allowBackgroundCloseOverride ?? policy.allowBackgroundClose) && clickBgToClose;
    final enableDrag = config.enableDragToClose ?? policy.enableDragToClose;

    final _ = config.theme.barrierColor ?? theme.colorScheme.scrim.withValues(alpha: 0.45);

    try {
      _sheetFuture = showModalBottomSheet<T>(
        context: ctx,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: false,
        isDismissible: allowBgClose,
        enableDrag: enableDrag,
        builder: (modalContext) {
          _sheetContext = modalContext;

          bool isPopping = false;

          void finish([dynamic res]) {
            if (isPopping) return;

            // 同样增加栈顶校验，保护底部弹窗
            final route = ModalRoute.of(modalContext);
            if (route == null || !route.isCurrent) return;

            isPopping = true;

            if (modalContext.mounted) {
              // 直接 pop
              Navigator.pop(modalContext, res);
            }
          }

          ModalManager.instance.bind(() => finish());

          final double maxHeightFactor = config.maxHeightFactor.clamp(0.0, 1.0);
          final bool isFullScreen = maxHeightFactor >= 0.99;
          final screenH = MediaQuery.of(modalContext).size.height;
          final maxHeight = isFullScreen ? screenH : screenH * config.maxHeightFactor;

          final surface = config.theme.surfaceColor ?? Theme.of(modalContext).colorScheme.surface;

          final Widget sheetPanel = MediaQuery.removePadding(
            context: modalContext,
            removeBottom: true,
            child: Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(config.borderRadius),
                ),
              ),
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: AnimatedSheetWrapper(
                policy: policy,
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(modalContext).padding.bottom
                  ),
                  child: SheetSurface<T>(
                    isFullScreen: isFullScreen,
                    config: config,
                    onClose: finish,
                    child: builder(modalContext, finish),
                  ),
                ),
              ),
            ),
          );

          final Widget content = Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (headerBuilder != null)
                  headerBuilder(modalContext) ?? const SizedBox.shrink(),
                sheetPanel,
              ],
            ),
          );

          if (enableShrink) {
            return ModalProgressObserver(child: content);
          } else {
            return content;
          }
        },
      );

      final result = await _sheetFuture;
      return result;
    } catch (error) {
      return null;
    } finally {
      _sheetFuture = null;
      _sheetContext = null;

      try {
        final currentContext = navigatorKey.currentContext;
        if (currentContext != null && currentContext.mounted) {
          ProviderScope.containerOf(currentContext, listen: false)
              .read(overlayProgressProvider.notifier).state = 0.0;
        }
      } catch (_) {}
    }
  }

  Future<void> close<T>([T? value]) async {
    if (!isShowing) return;

    if (_sheetContext != null && _sheetContext!.mounted) {
      // 同样换回 pop，拒绝静默失败
      Navigator.pop(_sheetContext!, value);
    }

    if (_sheetFuture != null) {
      await _sheetFuture;
    }
  }
}