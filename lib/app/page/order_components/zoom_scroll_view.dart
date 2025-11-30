import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// 顶部固定区域（不随内容滚动，只跟着卡片整体动）
/// [scrollOffset] 是 body 的滚动偏移，可用来做透明度、阴影等联动
typedef ZoomHeaderBuilder = Widget Function(
    BuildContext context,
    double scrollOffset,
    );

/// 底部固定区域（不随内容滚动，只跟着卡片整体动）
typedef ZoomBottomBuilder = Widget Function(
    BuildContext context,
    double scrollOffset,
    );

/// 中间可滚区域（真正的 ScrollView）
/// [scrollController] 用于在 body 内部联动滚动
/// [scrollOffset] 是当前滚动偏移
typedef ZoomBodyBuilder = Widget Function(
    BuildContext context,
    ScrollController scrollController,
    double scrollOffset,
    );

/// ZoomScrollView
/// ------------------------------------------------------------------
/// - header / bottom 固定在卡片内部的上下
/// - 中间 body 单独滚动
/// - 向上：只滚 body，banner 不卷走
/// - 向下：先让 body 回到顶部，然后再进入“下拉缩放关闭”模式
class ZoomScrollView extends StatefulWidget {
  /// 下拉达到一定距离 / 速度后触发的关闭回调
  final VoidCallback onDismiss;

  /// 是否启用下拉时的缩放效果（关掉就只位移 + 圆角，不缩放）
  final bool enableScale;

  /// 下拉最大距离（用于计算缩放 / 圆角变化）
  final double maxDragExtent;

  /// 基础圆角（未下拉时）
  final double baseRadius;

  /// 下拉到 [maxDragExtent] 时的最大圆角
  final double maxRadius;

  /// 下拉时的最小缩放值（值越接近 1，缩放越轻）
  final double minScale;

  /// 是否允许顶部下拉关闭
  final bool enableTopEdgeDismiss;

  /// 下拉多少像素触发关闭（距离阈值）
  final double dismissDragThreshold;

  /// 惯性滚动的弹簧参数（越大越“硬”/越快）
  final double springMass;
  final double springStiffness;
  final double springDamping;

  /// 惯性滚动的容差（velocity 越小，滚得越远；distance 影响精度）
  final double toleranceVelocity;
  final double toleranceDistance;

  /// 顶部固定区域（可以是 Banner + 小 Header 的 Stack）
  final ZoomHeaderBuilder? headerBuilder;

  /// 底部固定区域
  final ZoomBottomBuilder? bottomBuilder;

  /// 中间可滚区域
  final ZoomBodyBuilder bodyBuilder;

  final ValueChanged<double>? onScrollOffsetChanged;

  const ZoomScrollView({
    super.key,
    required this.onDismiss,
    this.enableScale = true,
    this.maxDragExtent = 200.0,
    this.baseRadius = 0.0,
    this.maxRadius = 30.0,
    this.minScale = 0.9,
    this.enableTopEdgeDismiss = true,
    this.dismissDragThreshold = 100.0,

    // 惯性滚动参数（偏 iOS 手感）
    this.springMass = 0.5,
    this.springStiffness = 80.0,
    this.springDamping = 12.0,
    this.toleranceVelocity = 1.0,
    this.toleranceDistance = 1.0,

    this.headerBuilder,
    this.bottomBuilder,
    required this.bodyBuilder,
    this.onScrollOffsetChanged,
  });

  @override
  State<ZoomScrollView> createState() => _ZoomScrollViewState();
}

class _ZoomScrollViewState extends State<ZoomScrollView>
    with TickerProviderStateMixin {
  /// 控制中间 body 区域的滚动
  final ScrollController _scrollController = ScrollController();

  /// 用于模拟惯性滚动的 AnimationController（unbounded，值范围不受 0~1 限制）
  late final AnimationController _flingController;

  /// 下拉失败后的回弹动画（把卡片弹回初始位置）
  late final AnimationController _reboundController;

  /// 当前这次手势是否已经进入“edge 下拉模式”
  /// 一旦进入，本次手势就只负责拉整张卡片，不再滚内容
  bool _isEdgeDragging = false;

  /// 当前卡片整体在 Y 方向上的偏移量
  double _cardTranslateY = 0.0;

  /// 当前卡片整体的缩放值
  double _cardScale = 1.0;

  /// 当前卡片的圆角
  double _cardRadius = 0.0;

  /// 回弹动画起始时的位移 / 缩放 / 圆角（用于插值）
  double _reboundStartTranslateY = 0.0;
  double _reboundStartScale = 1.0;
  double _reboundStartRadius = 0.0;

  /// body 区域当前的滚动偏移
  double _scrollOffset = 0.0;

  /// body 内容是否已经滚到顶部
  bool get _isBodyAtTop {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    // 加一点浮点容差
    return position.pixels <= position.minScrollExtent + 0.5;
  }

  @override
  void initState() {
    super.initState();

    _cardRadius = widget.baseRadius;

    // unbounded：允许值任意增减，用来承载 scroll offset
    _flingController = AnimationController.unbounded(vsync: this)
      ..addListener(_handleFlingTick);

    // 回弹：把当前的 translateY / scale / radius 动画插值回初始值
    _reboundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
      final t =
      Curves.easeOutBack.transform(_reboundController.value);
      setState(() {
        _cardTranslateY =
        lerpDouble(_reboundStartTranslateY, 0.0, t)!;
        _cardScale =
        lerpDouble(_reboundStartScale, 1.0, t)!;
        _cardRadius = lerpDouble(
          _reboundStartRadius,
          widget.baseRadius,
          t,
        )!;
      });
    });

    // 同步 body scrollOffset 给 header / bottom / bodyBuilder 用来做联动
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _flingController.dispose();
    _scrollController.dispose();
    _reboundController.dispose();
    super.dispose();
  }

  void _handleScroll(){
    final offset = _scrollController.offset;
    if (offset == _scrollOffset) return;

    setState(() {
      _scrollOffset = offset;
    });

    // 👇 通知外层（比如 OrderDetailPage）
    widget.onScrollOffsetChanged?.call(offset);
  }

  /// 在 edge 下拉模式中，根据 dy 更新整体位移 / 缩放 / 圆角
  void _applyEdgeDrag(double dy) {
    if (dy <= 0) return; // 只处理下拉
    setState(() {
      // 限制在 0 ~ maxDragExtent 之间
      _cardTranslateY =
          (_cardTranslateY + dy).clamp(0.0, widget.maxDragExtent);

      // 标准化到 0~1
      final rawT =
      (_cardTranslateY / widget.maxDragExtent).clamp(0.0, 1.0);
      // 用一个 easeOut 曲线，让前半段更轻，后半段更明显
      final easeT = Curves.easeOut.transform(rawT);

      // 缩放
      if (widget.enableScale) {
        _cardScale = 1.0 - easeT * (1.0 - widget.minScale);
      } else {
        _cardScale = 1.0;
      }

      // 圆角：从 baseRadius 过渡到 maxRadius
      if (widget.maxRadius > widget.baseRadius) {
        _cardRadius = widget.baseRadius +
            easeT * (widget.maxRadius - widget.baseRadius);
      } else {
        _cardRadius = widget.baseRadius;
      }
    });
  }

  /// 开始回弹动画：记录当前状态为起点，再缓动回 origin
  void _startRebound() {
    _reboundStartTranslateY = _cardTranslateY;
    _reboundStartScale = _cardScale;
    _reboundStartRadius = _cardRadius;

    _reboundController
      ..reset()
      ..forward();
  }

  /// pan 结束：根据本次手势模式（edge / normal）分别处理
  void _onPanEnd(DragEndDetails details) {
    // 1️⃣ edge 下拉模式结束
    if (_isEdgeDragging) {
      final velocityY = details.velocity.pixelsPerSecond.dy;

      // 速度阈值：下拉够快可以直接触发关闭
      const double velocityThreshold = 900.0;
      final bool fastEnough = velocityY > velocityThreshold;

      // 距离阈值：拖动距离超过 dismissDragThreshold 也可以触发关闭
      final bool farEnough =
          _cardTranslateY >= widget.dismissDragThreshold;

      if (fastEnough || farEnough) {
        widget.onDismiss();
      } else {
        // 已经回到顶部附近 → 直接复位
        if (_cardTranslateY == 0.0) {
          _cardScale = 1.0;
          _cardRadius = widget.baseRadius;
        } else {
          // 否则做个回弹动画
          _startRebound();
        }
      }

      _isEdgeDragging = false;
      return;
    }

    // 2️⃣ 普通滚动模式，处理惯性滚动（只作用于 body）
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final velocityY = -details.velocity.pixelsPerSecond.dy;

    // 速度太小就不触发 fling，避免轻微晃动也开始模拟
    if (velocityY.abs() < 50.0) return;

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

  /// pan 过程中，根据当前状态决定：滚内容 / 下拉卡片
  void _onPanUpdate(DragUpdateDetails details) {
    final dy = details.delta.dy;

    // 1️⃣ 已经在 edge 模式：整次手势都只操作整张卡片
    if (_isEdgeDragging) {
      _applyEdgeDrag(dy);
      return;
    }

    // 2️⃣ 还没进入 edge 模式

    // ====================== 上滑：全部当成“滚 body” ======================
    if (dy < 0) {
      _scrollBy(dy);
      return;
    }

    // ====================== 下滑：先 body 回顶，再考虑下拉关闭 ======================
    if (dy > 0) {
      double deltaDown = dy;

      // 1）先让 body 往回滚到顶部
      if (!_isBodyAtTop && _scrollController.hasClients) {
        final currentOffset = _scrollController.offset;
        final recover = math.min(deltaDown, currentOffset);

        if (recover > 0) {
          _scrollBy(recover); // dy>0，往下滚
          deltaDown -= recover;
        }
      }

      // 2）body 已经在顶部，且允许下拉关闭 → 剩余的才进入 edge 下拉模式
      if (deltaDown > 0 &&
          widget.enableTopEdgeDismiss &&
          _isBodyAtTop) {
        _isEdgeDragging = true;
        _applyEdgeDrag(deltaDown);
      }

      return;
    }
  }

  /// pan 开始：停止一切动画，重置手势模式
  void _onPanStart(DragStartDetails details) {
    _stopFling();
    _stopRebound();
    _isEdgeDragging = false;
  }

  /// 用 dy 改变 ScrollView 的 offset（带边界 clamp）
  void _scrollBy(double dy) {
    if (!_scrollController.hasClients) return;

    // 手指上滑（dy < 0）→ offset 变大 → 内容往上
    // 手指下滑（dy > 0）→ offset 变小 → 内容往下
    final newOffset = _scrollController.offset - dy;

    final position = _scrollController.position;
    final clampedOffset = math.min(
      position.maxScrollExtent,
      math.max(position.minScrollExtent, newOffset),
    );

    _scrollController.jumpTo(clampedOffset);
  }

  /// fling 动画每一帧 tick 时，把 controller 的值映射到 scroll offset 上
  void _handleFlingTick() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final min = position.minScrollExtent;
    final max = position.maxScrollExtent;

    var value = _flingController.value;

    // 安全防护：超出边界则 clamp + 停止动画
    if (value < min || value > max) {
      value = value.clamp(min, max);
      _flingController.stop();
    }

    _scrollController.jumpTo(value);
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

  @override
  Widget build(BuildContext context) {
    // header / body / bottom 放在有高度约束的 Column 里
    // header / bottom 固定，只有中间 Expanded 区域在滚动
    final content = Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        if (widget.headerBuilder != null)
          widget.headerBuilder!(context, _scrollOffset),

        // 中间可滚区域
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            // 手势完全由外层 GestureDetector 接管，ScrollView 自己不处理手势
            physics: const NeverScrollableScrollPhysics(),
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

    // 卡片圆角裁剪（随着下拉过程中的 _cardRadius 动态变化）
    if (widget.baseRadius > 0.0 || widget.maxRadius > 0.0) {
      wrapped = ClipRRect(
        borderRadius: BorderRadius.circular(_cardRadius),
        child: wrapped,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque, // 空白区域也能响应手势
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: Offset(0, _cardTranslateY),
        child: Transform.scale(
          scale: _cardScale,
          alignment: Alignment.topCenter, // 从顶部缩放，更接近“从顶部拉下”的感觉
          child: wrapped,
        ),
      ),
    );
  }
}