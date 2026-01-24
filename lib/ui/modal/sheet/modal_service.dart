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
    // 1. 关键修复：如果有弹窗正在显示，等待它完全关闭
    // 这里的 close() 现在会 await 直到上一个弹窗彻底销毁
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

          void finish([dynamic res]) {
            if (Navigator.of(modalContext).canPop()) {
              Navigator.of(modalContext).pop<T>(res);
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

          final Widget content = Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: allowBgClose ? () => finish() : null,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  if (headerBuilder != null)
                    headerBuilder(modalContext) ?? const SizedBox.shrink(),
                  sheetPanel,
                ],
              )
            ],
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
      // 2. 只有在这里才真正的清空引用
      // 这保证了上一个弹窗的生命周期完全结束
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

  // 3. 关键修复：close 方法
  Future<void> close<T>([T? value]) async {
    if (!isShowing) return;

    // 触发关闭动画
    if (_sheetContext != null && _sheetContext!.mounted && Navigator.of(_sheetContext!).canPop()) {
      Navigator.of(_sheetContext!).pop<T>(value);
    }

    // 4. 重要：等待 Future 完成
    // 不要在这里手动置空 _sheetFuture = null
    // 等待 showModalBottomSheet 内部流程走完（动画结束 -> finally 块执行）
    if (_sheetFuture != null) {
      await _sheetFuture;
    }
  }
}