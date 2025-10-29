import 'dart:async';
import 'package:flutter/material.dart';
import 'animated_sheet_wrapper.dart';
import 'animation_policy_config.dart';
import 'animation_policy_resolver.dart';
import 'sheet_props.dart';
import 'sheet_surface.dart';

/// ModalService
/// ------------------------------------------------------------------
/// 🔹 全局底部弹窗管理服务（RadixSheet 的底层核心）
///
/// 功能：
/// ✅ 统一管理 showModalBottomSheet 的展示、关闭、动画策略
/// ✅ 自动继承主题与圆角配置
/// ✅ 支持点击背景关闭 / 拖动关闭 / 最大高度控制
/// ✅ 避免 BuildContext 跨异步警告
/// ✅ 与全局动画策略 AnimationPolicyConfig 联动
///
/// 用法：
/// ```dart
/// await ModalService.instance.showSheet(
///   builder: (context, close) => MySheetContent(onClose: close),
///   config: ModalSheetConfig(enableDragToClose: true),
/// );
/// ```
/// ------------------------------------------------------------------
class ModalService with RouteAware {
  ModalService._();
  static final ModalService instance = ModalService._();

  /// 全局动画/行为策略配置（可被业务 config 覆盖）
  AnimationPolicyConfig? globalPolicy;

  /// 用于 showModalBottomSheet 全局挂载
  final navigatorKey = GlobalKey<NavigatorState>();

  /// 路由观察，用于当 push 新页面时自动关闭当前弹窗
  final routeObserver = RouteObserver<ModalRoute>();

  /// 当前正在显示的弹窗 Future（防重复弹出）
  Future<dynamic>? _sheetFuture;

  /// 当前弹窗的内部 context，用于 close()
  BuildContext? _sheetContext;

  /// 是否存在正在显示的弹窗
  bool get isShowing => _sheetFuture != null;

  // ------------------------------------------------------------------
  // 🧩 显示弹窗
  // ------------------------------------------------------------------
  Future<T?> showSheet<T>({
    /// 弹窗内容构建函数
    required Widget Function(BuildContext, void Function([T? res])) builder,

    /// 点击背景是否关闭（会受策略与 config 共同影响）
    bool clickBgToClose = true,

    /// 弹窗配置项（圆角、高度、拖动、动画策略等）
    ModalSheetConfig config = const ModalSheetConfig(),
  }) async {
    // ✅ 若已有弹窗在显示，先关闭再弹
    if (isShowing) await close();

    // ✅ 提前解析策略（避免 context 跨异步）
    final policy = AnimationPolicyResolver.resolve(
      businessStyle: config.animationStyleConfig,
      globalPolicy: globalPolicy,
    );

    // ✅ 启动 microtask，确保 context 在安全时机使用
    _sheetFuture = Future.microtask(() {
      final nav = navigatorKey.currentState;
      if (nav == null) throw Exception('ModalService: Navigator not ready.');

      // ✅ 确保当前 context 挂载
      if (!nav.mounted) return null;

      final ctx = nav.context;
      final theme = Theme.of(ctx);

      // ----------------------------------------------------------------
      // 🎛️ 配置行为优先级：
      // config > policy > 默认值
      // ----------------------------------------------------------------

      // 点击背景是否可关闭
      final allowBgClose = (config.allowBackgroundCloseOverride ??
          policy.allowBackgroundClose) &&
          clickBgToClose;

      // 是否允许拖动关闭
      final enableDrag =
          config.enableDragToClose ?? policy.enableDragToClose;

      // 遮罩与面板颜色（优先使用 config）
      final barrierColor = config.theme.barrierColor ??
          theme.colorScheme.scrim.withValues(alpha: 0.45);

      // ----------------------------------------------------------------
      // 🚀 弹出 BottomSheet
      // ----------------------------------------------------------------
      return showModalBottomSheet<T>(
        context: ctx,
        isScrollControlled: true, // ✅ 可铺满整个屏幕（支持内容超高）
        backgroundColor: Colors.transparent, // ✅ 去掉默认白底
        useSafeArea: false,
        barrierColor: barrierColor,
        isDismissible: allowBgClose, // ✅ 是否允许点击背景关闭
        enableDrag: enableDrag, // ✅ 是否允许拖动关闭
        builder: (modalContext) {
          _sheetContext = modalContext;

          // 内部关闭函数
          void finish([dynamic res]) {
            if (Navigator.of(modalContext).canPop()) {
              Navigator.of(modalContext).pop<T>(res);
            }
          }

          // ----------------------------------------------------------------
          // 🧮 高度计算与布局
          // ----------------------------------------------------------------
          // ✅ 动态计算最大高度（支持全屏配置）
          final double maxHeightFactor = config.maxHeightFactor.clamp(0.0, 1.0);
          // 如果设置为 1.0（或大于 0.98），则认为是全屏
          final bool isFullScreen = maxHeightFactor >= 0.99;

          final screenH = MediaQuery.of(modalContext).size.height;
          final maxHeight = isFullScreen ? screenH :
              screenH * config.maxHeightFactor;

          final surface =
              config.theme.surfaceColor ??
                  Theme.of(modalContext).colorScheme.surface;

          // ----------------------------------------------------------------
          // 🎨 最终内容容器（含圆角、最大高度、自适应内容）
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
                policy:policy,
                child:SheetSurface(
                  isFullScreen: isFullScreen,
                  config: config,
                  onClose: () => finish(),
                  child: builder(modalContext, finish),
                )
              ),
            ),
          );
        },
      );
    });

    // 等待弹窗关闭结果（若有返回值）
    final result = await _sheetFuture;

    // 清理引用
    _sheetFuture = null;
    _sheetContext = null;
    return result;
  }

  // ------------------------------------------------------------------
  // ❌ 主动关闭弹窗
  // ------------------------------------------------------------------
  Future<void> close<T>([T? value]) async {
    if (_sheetContext != null && Navigator.of(_sheetContext!).canPop()) {
      Navigator.of(_sheetContext!).pop<T>(value);
    }
    _sheetFuture = null;
    _sheetContext = null;
  }

  // ------------------------------------------------------------------
  // 🚫 当有新页面 push 时自动关闭当前弹窗
  // ------------------------------------------------------------------
  @override
  void didPushNext() => close();
}

