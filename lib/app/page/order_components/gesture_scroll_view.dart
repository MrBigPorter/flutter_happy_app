import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class GestureInertialScrollView extends StatefulWidget {
  final Widget child;
  final ValueChanged<double>? onOffsetChanged;

  /// 顶部边缘下拉时的回调（可选）
  final VoidCallback? onTopEdgeDragStart;
  final ValueChanged<DragUpdateDetails>? onTopEdgeDragUpdate;
  final ValueChanged<DragEndDetails>? onTopEdgeDragEnd;

  /// 是否启用顶部 edge 下拉（比如用来做下拉关闭）
  final bool enableTopEdgeDrag;

  const GestureInertialScrollView({
    Key? key,
    required this.child,
    this.onOffsetChanged,
    this.onTopEdgeDragStart,
    this.onTopEdgeDragUpdate,
    this.onTopEdgeDragEnd,
    this.enableTopEdgeDrag = false,
  }) : super(key: key);

  @override
  State<GestureInertialScrollView> createState() =>
      _GestureInertialScrollViewState();
}

class _GestureInertialScrollViewState extends State<GestureInertialScrollView>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _flingController;

  bool _isTopEdgeDragging = false;

  @override
  void initState() {
    super.initState();

    _flingController = AnimationController.unbounded(vsync: this)
      ..addListener(_handleFlingTick);

    _scrollController.addListener(() {
      widget.onOffsetChanged?.call(_scrollController.offset);
    });
  }

  @override
  void dispose() {
    _flingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isAtTop {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.pixels <= position.minScrollExtent + 0.5;
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

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(value);
    }
  }

  void _handlePanStart(DragStartDetails details) {
    if (_flingController.isAnimating) {
      _flingController.stop();
    }

    _isTopEdgeDragging = false;

    if (widget.enableTopEdgeDrag && _isAtTop) {
      // 先不直接进入 edgeDragging，等 update 再根据方向判断
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_scrollController.hasClients) return;

    final dy = details.delta.dy;

    // ========================
    // 顶部 edge 下拉逻辑
    // ========================
    if (widget.enableTopEdgeDrag) {
      final atTop = _isAtTop;

      // 1. 已经在 edgeDragging 状态 -> 直接把事件交给外层
      if (_isTopEdgeDragging) {
        widget.onTopEdgeDragUpdate?.call(details);
        return; // 不再滚动内容
      }

      // 2. 还没进入 edgeDragging：
      //    在顶部 + 向下拖动（dy > 0） -> 进入 edgeDragging 模式
      if (atTop && dy > 0) {
        _isTopEdgeDragging = true;
        widget.onTopEdgeDragStart?.call();
        widget.onTopEdgeDragUpdate?.call(details);
        return; // 不滚动内容
      }
    }

    // ========================
    // 普通滚动逻辑
    // ========================
    final position = _scrollController.position;
    final newOffset = _scrollController.offset - dy;
    final clamped = math.min(
      position.maxScrollExtent,
      math.max(position.minScrollExtent, newOffset),
    );

    _scrollController.jumpTo(clamped);
  }

  void _handlePanEnd(DragEndDetails details) {
    // 如果正在 edge 下拉，就把 end 交给外层，不做惯性
    if (_isTopEdgeDragging) {
      widget.onTopEdgeDragEnd?.call(details);
      _isTopEdgeDragging = false;
      return;
    }

    if (!_scrollController.hasClients) return;

    final velocityY = -details.velocity.pixelsPerSecond.dy;

    if (velocityY.abs() < 50) return;

    final simulation = ClampingScrollSimulation(
      position: _scrollController.offset,
      velocity: velocityY,
      tolerance: const Tolerance(
        velocity: 1.0,
        distance: 0.5,
      ),
    );

    _flingController.value = _scrollController.offset;
    _flingController.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const NeverScrollableScrollPhysics(),
        child: widget.child,
      ),
    );
  }
}