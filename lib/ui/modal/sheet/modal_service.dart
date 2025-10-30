import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/modal/base/modal_auto_close_observer.dart';
import 'package:flutter_app/ui/modal/base/nav_hub.dart';
import 'package:flutter_app/ui/modal/sheet/modal_sheet_config.dart';
import '../base/animation_policy_resolver.dart';
import 'animated_sheet_wrapper.dart';
import '../base/animation_policy_config.dart';
import 'sheet_surface.dart';

/// ModalSheetService
/// ------------------------------------------------------------------
/// 🔹 Global bottom sheet management service (Core of RadixSheet)
///
/// Features:
/// ✅ Unified management of showModalBottomSheet display, closing, and animation strategies
/// ✅ Automatically inherits theme and border radius configuration
/// ✅ Supports closing by clicking background / dragging / maximum height control
/// ✅ Avoids BuildContext async warning
/// ✅ Integrates with global animation strategy AnimationPolicyConfig
///
/// Usage:
/// ```dart
/// await ModalSheetService.instance.showSheet(
///   builder: (context, close) => MySheetContent(onClose: close),
///   config: ModalSheetConfig(enableDragToClose: true),
/// );
/// ```
/// ------------------------------------------------------------------
class ModalSheetService {
  ModalSheetService._();

  static final ModalSheetService instance = ModalSheetService._();

  /// Global animation/behavior policy config (can be overridden by business config)
  AnimationPolicyConfig? globalPolicy;

  /// For showModalBottomSheet global mounting
  GlobalKey<NavigatorState> get navigatorKey => NavHub.key;

  /// Route observer, used to automatically close current sheet when pushing new page 
  final routeObserver = RouteObserver<ModalRoute>();

  /// Currently showing sheet's Future (prevents duplicate showing)
  Future<dynamic>? _sheetFuture;

  /// Current sheet's internal context, used for close()
  BuildContext? _sheetContext;

  /// Whether there is a sheet currently showing
  bool get isShowing => _sheetFuture != null;

  // ------------------------------------------------------------------
  // 🧩 Show Sheet
  // ------------------------------------------------------------------
  Future<T?> showSheet<T>({
    /// Sheet content builder function
    required Widget Function(BuildContext, void Function([T? res])) builder,

    /// Whether to close on background click (affected by policy and config)
    bool clickBgToClose = true,

    /// Sheet configuration (border radius, height, drag, animation strategy etc.)
    ModalSheetConfig config = const ModalSheetConfig(),
  }) async {
    // ✅ If sheet is showing, close it first
    if (isShowing) await close();

    // ✅ Parse strategy early (avoid context async issues)
    final policy = AnimationPolicyResolver.resolve(
      businessStyle: config.animationStyleConfig,
      globalPolicy: globalPolicy,
    );

    // ✅ Start microtask to ensure context is used at safe time
    _sheetFuture = Future.microtask(() {
      final nav = navigatorKey.currentState;
      if (nav == null) throw Exception(
          'ModalSheetService: Navigator not ready.');

      // ✅ Ensure current context is mounted
      if (!nav.mounted) return null;

      final ctx = nav.context;
      final theme = Theme.of(ctx);

      // ----------------------------------------------------------------
      // 🎛️ Config priority:
      // config > policy > defaults
      // ----------------------------------------------------------------

      // Whether background click closes sheet
      final allowBgClose = (config.allowBackgroundCloseOverride ??
          policy.allowBackgroundClose) &&
          clickBgToClose;

      // Whether drag to close is enabled
      final enableDrag =
          config.enableDragToClose ?? policy.enableDragToClose;

      // Barrier and panel colors (config takes priority)
      final barrierColor = config.theme.barrierColor ??
          theme.colorScheme.scrim.withValues(alpha: 0.45);

      // ----------------------------------------------------------------
      // 🚀 Show BottomSheet
      // ----------------------------------------------------------------
      return showModalBottomSheet<T>(
        context: ctx,
        isScrollControlled: true,
        // ✅ Can fill entire screen (supports tall content)
        backgroundColor: Colors.transparent,
        // ✅ Remove default white background
        useSafeArea: false,
        barrierColor: barrierColor,
        isDismissible: allowBgClose,
        // ✅ Whether background click closes
        enableDrag: enableDrag,
        // ✅ Whether drag to close is enabled
        builder: (modalContext) {
          _sheetContext = modalContext;

          // Internal close function
          void finish([dynamic res]) {
            if (Navigator.of(modalContext).canPop()) {
              Navigator.of(modalContext).pop<T>(res);
            }
          }

          ModalManager.instance.bind(() => finish());

          // ----------------------------------------------------------------
          // 🧮 Height calculation and layout
          // ----------------------------------------------------------------
          // ✅ Dynamically calculate max height (supports fullscreen)
          final double maxHeightFactor = config.maxHeightFactor.clamp(0.0, 1.0);
          // If set to 1.0 (or > 0.98), consider as fullscreen
          final bool isFullScreen = maxHeightFactor >= 0.99;

          final screenH = MediaQuery
              .of(modalContext)
              .size
              .height;
          final maxHeight = isFullScreen ? screenH :
          screenH * config.maxHeightFactor;

          final surface =
              config.theme.surfaceColor ??
                  Theme
                      .of(modalContext)
                      .colorScheme
                      .surface;

          // ----------------------------------------------------------------
          // 🎨 Final content container (with border radius, max height, adaptive content)
          // ----------------------------------------------------------------
          return MediaQuery.removePadding(
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
                  child: SheetSurface<T>(
                    isFullScreen: isFullScreen,
                    config: config,
                    onClose: finish,
                    child: builder(modalContext, finish),
                  )
              ),
            ),
          );
        },
      );
    });

    // Wait for sheet close result (if any)
    final result = await _sheetFuture;

    // Clean up references
    _sheetFuture = null;
    _sheetContext = null;
    return result;
  }

  // ------------------------------------------------------------------
  // ❌ Actively close sheet
  // ------------------------------------------------------------------
  Future<void> close<T>([T? value]) async {
    if (_sheetContext != null && Navigator.of(_sheetContext!).canPop()) {
      Navigator.of(_sheetContext!).pop<T>(value);
    }
    _sheetFuture = null;
    _sheetContext = null;
  }
}
