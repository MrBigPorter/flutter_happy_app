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

  //  核心重构：用 List 追踪所有弹窗，允许它们自然堆叠！
  final List<BuildContext> _activeContexts = [];

  bool get isShowing => _activeContexts.isNotEmpty;

  Future<T?> showSheet<T>({
    required Widget Function(BuildContext, void Function([T? res])) builder,
    bool clickBgToClose = true,
    ModalSheetConfig config = const ModalSheetConfig(),
    Widget? Function(BuildContext)? headerBuilder,
    bool enableShrink = true,
  }) async {
    //  移除了 `if (isShowing) await close();` 的霸道逻辑
    // 现在弹窗 1 和弹窗 2 可以完美叠加了！

    final policy = AnimationPolicyResolver.resolve(
      businessStyle: config.animationStyleConfig,
      globalPolicy: globalPolicy,
    );

    final nav = navigatorKey.currentState;
    if (nav == null || !nav.mounted) return null;

    final ctx = nav.context;
    final theme = Theme.of(ctx);

    final allowBgClose = (config.allowBackgroundCloseOverride ?? policy.allowBackgroundClose) && clickBgToClose;
    final enableDrag = config.enableDragToClose ?? policy.enableDragToClose;
    final _ = config.theme.barrierColor ?? theme.colorScheme.scrim.withValues(alpha: 0.45);

    try {
      final future = showModalBottomSheet<T>(
        context: ctx,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: false,
        isDismissible: allowBgClose,
        enableDrag: enableDrag,
        builder: (modalContext) {
          // 记录当前新开的弹窗
          _activeContexts.add(modalContext);

          bool isPopping = false;

          void finish([dynamic res]) {
            if (isPopping) return;
            if (!modalContext.mounted) return;

            final route = ModalRoute.of(modalContext);
            //  终极防御：增加了 `!route.isActive` 检测
            // 如果用户点了灰色背景，系统原生已经在关它了，我们绝不再发 pop！
            if (route == null || !route.isCurrent || !route.isActive) return;

            isPopping = true;
            Navigator.pop(modalContext, res);
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

      final result = await future;
      return result;
    } catch (error) {
      return null;
    } finally {
      //  精确清理：当前弹窗彻底关闭后，把它从记录中移除
      // 绝对不会误伤到底层还在显示的弹窗
      _activeContexts.removeWhere((c) => c == null || !c.mounted);

      try {
        // 只有所有弹窗都关完了，才恢复底层页面进度
        if (_activeContexts.isEmpty) {
          final currentContext = navigatorKey.currentContext;
          if (currentContext != null && currentContext.mounted) {
            ProviderScope.containerOf(currentContext, listen: false)
                .read(overlayProgressProvider.notifier).state = 0.0;
          }
        }
      } catch (_) {}
    }
  }

  // 代码触发的全局关闭，永远只关掉处于最顶层的一个弹窗
  Future<void> close<T>([T? value]) async {
    if (_activeContexts.isEmpty) return;

    final topContext = _activeContexts.last;
    if (topContext.mounted) {
      final route = ModalRoute.of(topContext);
      if (route != null && route.isActive) {
        Navigator.maybePop(topContext, value);
      }
    }
  }
}