import 'dart:async';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/modal/base/modal_auto_close_observer.dart';
import 'package:flutter_app/ui/modal/base/nav_hub.dart';
import 'package:flutter_app/ui/modal/progress/modal_progress_observer.dart';
import 'package:flutter_app/ui/modal/sheet/modal_sheet_config.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
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

    //  [新增参数] 是否启用背景缩放动画
    // 默认为 true (保持原有逻辑)。
    // 调用 Picker 时请传 false，这样页面绝对不会动！
    bool enableShrink = true,
  }) async {
    if (isShowing) await close();

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

    // 保持透明，由 Stack 里的 BackdropFilter 控制
    final barrierColor = Colors.transparent;
    final visualBarrierColor = config.theme.barrierColor ?? theme.colorScheme.scrim.withValues(alpha: 0.45);

    try {
      _sheetFuture = showModalBottomSheet<T>(
        context: ctx,
        useRootNavigator: true, // 保持这个，防止 Scaffold 挤压
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: false,
        barrierColor: barrierColor,
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
              Positioned.fill(
                child: GestureDetector(
                  onTap: allowBgClose ? () => finish() : null,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: policy.blurSigma,
                      sigmaY: policy.blurSigma,
                    ),
                    child: Container(color: visualBarrierColor),
                  ),
                ),
              ),
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

          // 如果 enableShrink 为 false，就不包裹 Observer。
          // 这样 Provider 里的值永远是 0，OverlayShrink 就永远不会触发，页面就永远不会动！
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

      // 只有启用了缩放才需要重置，不过多重置一次也没坏处
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
    if (_sheetContext != null && Navigator.of(_sheetContext!).canPop()) {
      Navigator.of(_sheetContext!).pop<T>(value);
    }
    _sheetFuture = null;
    _sheetContext = null;
  }
}