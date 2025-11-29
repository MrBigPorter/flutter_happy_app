import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

typedef ZoomableBuilder = Widget Function(
    BuildContext context,
    double scrollOffset,
    );

class ZoomableEdgeScrollView extends StatefulWidget {
  final ZoomableBuilder builder;

  /// 下拉到一定距离后的回调，如关闭页面
  final VoidCallback? onDismiss;

  /// 是否允许顶部下拉关闭
  final bool enableTopEdgeDismiss;

  /// 是否启用下拉缩放效果（关掉就只下拉不缩放）
  final bool enableScale;

  /// 下拉多少像素触发关闭
  final double dismissDragThreshold;

  /// 下拉最大距离（用于计算缩放/圆角变化比例）
  final double maxDragDistance;

  /// 下拉时的最小缩放值（值越接近 1，缩放越“轻”）
  final double minScale;

  /// 缩放基准点，默认从上边缘缩放（不是从中心）
  final Alignment scaleAlignment;

  /// 基础圆角（未下拉时）
  final double baseRadius;

  /// 下拉到 maxDragDistance 时的最大圆角
  final double maxRadius;

  /// 惯性滚动的弹簧参数（越大越硬，越小越软）
  final double springMass;
  final double springStiffness;
  final double springDamping;

  /// 惯性滚动的容差（velocity 越小，滚得越远；distance 影响精度）
  final double toleranceVelocity;
  final double toleranceDistance;

  const ZoomableEdgeScrollView({
    super.key,
    required this.builder,
    this.onDismiss,
    this.enableTopEdgeDismiss = true,
    this.enableScale = true,
    this.dismissDragThreshold = 80.0,
    this.maxDragDistance = 220.0,
    this.minScale = 0.95,              // 默认轻微缩放
    this.scaleAlignment = Alignment.topCenter, // 默认从顶部缩放
    this.baseRadius = 0.0,
    this.maxRadius = 0.0,

    // 惯性参数默认值（偏 iOS 手感）
    this.springMass = 0.5,
    this.springStiffness = 80.0,
    this.springDamping = 8.0,
    this.toleranceVelocity = 0.8,
    this.toleranceDistance = 0.5,
  });

  @override
  State<ZoomableEdgeScrollView> createState() =>
      _ZoomableEdgeScrollViewState();
}

class _ZoomableEdgeScrollViewState extends State<ZoomableEdgeScrollView>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _flingController;

  // 回弹动画（让缩放/位移有“韧性”）
  late final AnimationController _reboundController;
  double _reboundStartTranslateY = 0.0;
  double _reboundStartScale = 1.0;
  double _reboundStartRadius = 0.0;

  double _scrollOffset = 0.0;

  // 下拉时整体位移 + 缩放 + 圆角
  double _cardTranslateY = 0.0;
  double _cardScale = 1.0;
  double _cardRadius = 0.0;
  bool _isEdgeDragging = false;

  @override
  void initState() {
    super.initState();

    _cardRadius = widget.baseRadius;

    _flingController = AnimationController.unbounded(vsync: this)
      ..addListener(_handleFlingTick);

    _reboundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
      final t = Curves.easeOutBack.transform(_reboundController.value);
      setState(() {
        _cardTranslateY = lerpDouble(_reboundStartTranslateY, 0.0, t)!;
        _cardScale = lerpDouble(_reboundStartScale, 1.0, t)!;
        _cardRadius =
        lerpDouble(_reboundStartRadius, widget.baseRadius, t)!;
      });
    });

    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _flingController.dispose();
    _reboundController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isAtTop {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.pixels <= position.minScrollExtent + 0.5;
  }

  void _stopFling() {
    if (_flingController.isAnimating) {
      _flingController.stop();
    }
  }

  void _stopRebound() {
    if (_reboundController.isAnimating) {
      _reboundController.stop();
    }
  }

  void _handleFlingTick() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final min = position.minScrollExtent;
    final max = position.maxScrollExtent;

    var value = _flingController.value;

    // 为安全起见，依然夹紧边界，防止极端情况下数值飘出太远
    if (value < min || value > max) {
      value = value.clamp(min, max);
      _flingController.stop();
    }

    _scrollController.jumpTo(value);
  }

  void _scrollBy(double dy) {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final newOffset = _scrollController.offset - dy;
    final clamped = math.min(
      position.maxScrollExtent,
      math.max(position.minScrollExtent, newOffset),
    );
    _scrollController.jumpTo(clamped);
  }

  void _onPanStart(DragStartDetails details) {
    _stopFling();
    _stopRebound();
    _isEdgeDragging = false;
  }

  void _updateEdgeDragState(double dy) {
    _cardTranslateY += dy;
    if (_cardTranslateY < 0) _cardTranslateY = 0;

    // 原始进度 0~1
    final rawT = (_cardTranslateY / widget.maxDragDistance).clamp(0.0, 1.0);
    // 缓动曲线，让前半段变化更轻一点
    final easedT = Curves.easeOut.transform(rawT);

    // 缩放
    if (widget.enableScale) {
      _cardScale = 1.0 - easedT * (1.0 - widget.minScale);
    } else {
      _cardScale = 1.0;
    }

    // 圆角：从 baseRadius 过渡到 maxRadius
    if (widget.maxRadius > widget.baseRadius) {
      _cardRadius =
          widget.baseRadius + (widget.maxRadius - widget.baseRadius) * easedT;
    } else {
      _cardRadius = widget.baseRadius;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final dy = details.delta.dy;

    // 顶部下拉逻辑
    if (widget.enableTopEdgeDismiss) {
      final atTop = _isAtTop;

      // 已经在 edge 模式：继续下拉只处理卡片位移 / 缩放 / 圆角
      if (_isEdgeDragging) {
        setState(() => _updateEdgeDragState(dy));
        return;
      }

      // 还没进入 edge 模式：在顶部 & 向下拖 -> 进入 edge 模式
      if (atTop && dy > 0) {
        _isEdgeDragging = true;
        setState(() => _updateEdgeDragState(dy));
        return;
      }
    }

    // 普通滚动
    _scrollBy(dy);
  }

  void _startRebound() {
    _reboundStartTranslateY = _cardTranslateY;
    _reboundStartScale = _cardScale;
    _reboundStartRadius = _cardRadius;

    _reboundController
      ..reset()
      ..forward();
  }

  void _onPanEnd(DragEndDetails details) {
    // 结束的是 edge 下拉
    if (_isEdgeDragging) {
      final shouldDismiss = _cardTranslateY >= widget.dismissDragThreshold &&
          widget.onDismiss != null;

      if (shouldDismiss) {
        widget.onDismiss!.call();
      } else {
        // 用回弹动画恢复：有点“韧性”的感觉
        _startRebound();
      }

      _isEdgeDragging = false;
      return;
    }

    // 普通滚动惯性（iOS 风格，可调参数）
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final velocityY = -details.velocity.pixelsPerSecond.dy;

    // 速度太小就当作不惯性滚动
    if (velocityY.abs() < 50) return;

    final simulation = BouncingScrollSimulation(
      position: _scrollController.offset,
      velocity: velocityY,
      leadingExtent: position.minScrollExtent,
      trailingExtent: position.maxScrollExtent,
      spring: SpringDescription(
        mass: widget.springMass,
        stiffness: widget.springStiffness,
        damping: widget.springDamping,
      ),
      tolerance: Tolerance(
        velocity: widget.toleranceVelocity,
        distance: widget.toleranceDistance,
      ),
    );

    _flingController.value = _scrollController.offset;
    _flingController.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.builder(context, _scrollOffset);

    final content = SingleChildScrollView(
      controller: _scrollController,
      physics: const NeverScrollableScrollPhysics(), // 手势完全自己接管
      child: child,
    );

    Widget wrapped = content;

    if (widget.baseRadius > 0 || widget.maxRadius > 0) {
      wrapped = ClipRRect(
        borderRadius: BorderRadius.circular(_cardRadius),
        child: wrapped,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: Offset(0, _cardTranslateY),
        child: Transform.scale(
          scale: _cardScale,
          alignment: widget.scaleAlignment, // 👈 默认顶部缩放，可配置
          child: wrapped,
        ),
      ),
    );
  }
}