// zoomable_edge_scroll_view.dart
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// 顶部固定 header：不滚动，只跟着卡片缩放 / 位移
typedef ZoomHeaderBuilder = Widget Function(
    BuildContext context,
    double scrollOffset,
    );

/// 底部固定 bottom：不滚动，只跟着卡片缩放 / 位移
typedef ZoomBottomBuilder = Widget Function(
    BuildContext context,
    double scrollOffset,
    );

/// 中间可滚 body：用传进来的 ScrollController 管理滚动
typedef ZoomBodyBuilder = Widget Function(
    BuildContext context,
    ScrollController scrollController,
    double scrollOffset,
    );

class ZoomableEdgeScrollView extends StatefulWidget {
  final ZoomHeaderBuilder? headerBuilder;
  final ZoomBottomBuilder? bottomBuilder;
  final ZoomBodyBuilder bodyBuilder;

  /// 下拉到一定距离后的回调（比如关闭当前卡片）
  final VoidCallback onDismiss;

  /// 是否允许顶部下拉关闭
  final bool enableTopEdgeDismiss;

  /// 是否启用下拉缩放效果
  final bool enableScale;

  /// 下拉多少像素触发关闭
  final double dismissDragThreshold;

  /// 下拉最大距离（用于计算缩放 / 圆角变化）
  final double maxDragDistance;

  /// 下拉时最小缩放值
  final double minScale;

  /// 缩放基准点
  final Alignment scaleAlignment;

  /// 基础圆角
  final double baseRadius;

  /// 最大圆角
  final double maxRadius;

  /// 惯性滚动的弹簧参数
  final double springMass;
  final double springStiffness;
  final double springDamping;

  /// 惯性滚动容差
  final double toleranceVelocity;
  final double toleranceDistance;

  const ZoomableEdgeScrollView({
    super.key,
    required this.bodyBuilder,
    required this.onDismiss,
    this.headerBuilder,
    this.bottomBuilder,
    this.enableTopEdgeDismiss = true,
    this.enableScale = true,
    this.dismissDragThreshold = 80.0,
    this.maxDragDistance = 220.0,
    this.minScale = 0.95,
    this.scaleAlignment = Alignment.topCenter,
    this.baseRadius = 0.0,
    this.maxRadius = 0.0,
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

  /// 回弹动画（用于下拉失败后，“弹回去”）
  late final AnimationController _reboundController;
  double _reboundStartTranslateY = 0.0;
  double _reboundStartScale = 1.0;
  double _reboundStartRadius = 0.0;

  /// 当前滚动偏移（给 header/bottom 做透明度等）
  double _scrollOffset = 0.0;

  /// 下拉关闭相关：整体位移 + 缩放 + 圆角
  double _cardTranslateY = 0.0;
  double _cardScale = 1.0;
  double _cardRadius = 0.0;

  /// 当前这次手势是否已经“接管”为下拉关闭模式
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
      final t =
      Curves.easeOutBack.transform(_reboundController.value);
      setState(() {
        _cardTranslateY = lerpDouble(
          _reboundStartTranslateY,
          0.0,
          t,
        )!;
        _cardScale = lerpDouble(
          _reboundStartScale,
          1.0,
          t,
        )!;
        _cardRadius = lerpDouble(
          _reboundStartRadius,
          widget.baseRadius,
          t,
        )!;
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

  /// 统一处理「下拉关闭模式」的形变逻辑
  /// ❗️注意：这一整次手势只负责操作“整张卡片”，
  /// 不再把多余的上滑位移交给 ScrollView。
  void _applyEdgeDrag(double dy) {
    setState(() {
      _cardTranslateY =
          (_cardTranslateY + dy).clamp(0.0, widget.maxDragDistance);

      final rawT =
      (_cardTranslateY / widget.maxDragDistance).clamp(0.0, 1.0);
      final easedT = Curves.easeOut.transform(rawT);

      // 缩放
      if (widget.enableScale) {
        _cardScale = 1.0 - easedT * (1.0 - widget.minScale);
      } else {
        _cardScale = 1.0;
      }

      // 圆角
      if (widget.maxRadius > widget.baseRadius) {
        _cardRadius = widget.baseRadius +
            (widget.maxRadius - widget.baseRadius) * easedT;
      } else {
        _cardRadius = widget.baseRadius;
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final dy = details.delta.dy;

    print('dy: $dy, isEdgeDragging: $_isEdgeDragging, scrollOffset: $_scrollOffset');

    // 1️⃣ 已经在 edge 模式：无论向上 / 向下，都只动整张卡片
    if (_isEdgeDragging) {
      _applyEdgeDrag(dy);
      return;
    }

    // 2️⃣ 还没进入 edge 模式

    // 上滑：永远当成正常内容滚动
    if (dy < 0) {
      _scrollBy(dy);
      return;
    }

    // 下面都是 dy > 0（向下）
    if (!widget.enableTopEdgeDismiss) {
      // 不支持顶部下拉关闭 → 全部当成普通滚动
      _scrollBy(dy);
      return;
    }

    final atTop = _isAtTop;

    if (atTop) {
      // ✅ 内容已经滚到顶部：再向下才启动「下拉关闭」模式
      _isEdgeDragging = true;
      _applyEdgeDrag(dy);
    } else {
      // 还没到顶部 → 先把内容往回滚到顶部
      _scrollBy(dy);
    }
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
    // 1️⃣ 下拉关闭模式结束
    if (_isEdgeDragging) {
      final velocity = details.velocity.pixelsPerSecond.dy;
      final bool fastEnough = velocity > 900; // 快速下滑
      final bool farEnough =
          _cardTranslateY >= widget.dismissDragThreshold;

      if ((fastEnough || farEnough)) {
        widget.onDismiss();
      } else {
        // 如果已经几乎回到顶部了，就直接复位
        if (_cardTranslateY == 0.0) {
          _cardScale = 1.0;
          _cardRadius = widget.baseRadius;
        } else {
          _startRebound();
        }
      }

      _isEdgeDragging = false;
      return;
    }

    // 2️⃣ 普通滚动惯性
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final velocityY = -details.velocity.pixelsPerSecond.dy;

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
    // header / body / bottom 在一个有高度约束的 Column 里
    final content = Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        if (widget.headerBuilder != null)
          widget.headerBuilder!(context, _scrollOffset),

        // 中间可滚区域
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const NeverScrollableScrollPhysics(), // 手势完全自己接管
            child: widget.bodyBuilder(
              context,
              _scrollController,
              _scrollOffset,
            ),
          ),
        ),

        if (widget.bottomBuilder != null)
          widget.bottomBuilder!(context, _scrollOffset),
      ],
    );

    Widget wrapped = content;

    if (widget.baseRadius > 0 || widget.maxRadius > 0) {
      wrapped = ClipRRect(
        borderRadius: BorderRadius.circular(_cardRadius),
        child: wrapped,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: Offset(0, _cardTranslateY),
        child: Transform.scale(
          scale: _cardScale,
          alignment: widget.scaleAlignment,
          child: wrapped,
        ),
      ),
    );
  }
}