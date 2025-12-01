import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

typedef ScrollBodyBuilder = Widget Function(
    BuildContext context,
    ScrollController scrollController,
    ScrollPhysics physics, // 把 Physics 传出去，由父组件控制
    );

class ZoomScrollView extends StatefulWidget {
  final ScrollBodyBuilder bodyBuilder;
  final Widget bottomBar;
  final VoidCallback onDismiss;
  final ValueChanged<double>? onScrollOffsetChanged;

  const ZoomScrollView({
    super.key,
    required this.bodyBuilder,
    required this.bottomBar,
    required this.onDismiss,
    this.onScrollOffsetChanged,
  });

  @override
  State<ZoomScrollView> createState() => _ZoomScrollViewState();
}

class _ZoomScrollViewState extends State<ZoomScrollView>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  // 动画控制器
  late final AnimationController _animController;
  late Animation<double> _animTranslate;
  late Animation<double> _animScale;

  // 状态变量
  double _translateY = 0.0;
  double _scale = 1.0;
  bool _isDragging = false;
  bool _isAnimating = false; // 是否正在执行回弹或关闭动画

  // 速度追踪
  VelocityTracker? _velocityTracker;

  // 阈值配置
  static const double _dismissThreshold = 100.0; // 距离阈值
  static const double _velocityThreshold = 800.0; // 速度阈值 (像素/秒)
  static const double _minScale = 0.88; // 最小缩放比例

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250), // iOS spring 默认大约是 250-300ms
    )..addListener(() {
      setState(() {
        _translateY = _animTranslate.value;
        _scale = _animScale.value;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_isDragging || _isAnimating) return;
    widget.onScrollOffsetChanged?.call(_scrollController.offset);
  }

  // 计算阻尼：随着距离增加，移动越来越难
  // 模拟 iOS UIScrollView 的 rubber-banding 公式
  double _applyFriction(double overscroll) {
    // 简单的指数衰减模拟阻尼
    // 0 -> 0
    // 100 -> 80
    // 500 -> 200
    if (overscroll <= 0) return 0;
    return 50 * math.log(1 + overscroll / 50);
    // 或者用线性衰减: return overscroll * 0.5; (最简单)
    // 下面这个公式手感更像 iOS：
    // return math.pow(overscroll, 0.8).toDouble();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_isAnimating) return; // 动画中禁止打断，或者你可以选择 stop 动画接管
    _velocityTracker = VelocityTracker.withKind(event.kind);
    _isDragging = false;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isAnimating) return;
    _velocityTracker?.addPosition(event.timeStamp, event.position);

    final delta = event.delta.dy;
    final isAtTop = !_scrollController.hasClients || _scrollController.offset <= 0;

    // 状态机：
    // 1. 如果已经在拖拽中 -> 更新 translateY
    // 2. 如果不在拖拽中，但在顶部且向下滑动 -> 开启拖拽模式

    if (_isDragging) {
      // 已经在拖拽模式：完全接管
      // 这里不使用 event.delta.dy 直接加，因为会导致不跟手
      // 我们基于总的拖动距离来计算（稍微简化逻辑，直接累加 delta）

      double newTranslate = _translateY + delta;

      // 增加阻力感：如果 delta > 0 (向下拉)，系数变小
      if (delta > 0 && _translateY > 0) {
        // 模拟阻力：随着 _translateY 变大，delta 的效用减弱
        double friction = math.max(0.2, 1.0 - (_translateY / 600.0));
        newTranslate = _translateY + delta * friction;
      }

      if (newTranslate < 0) newTranslate = 0; // 不允许向上推过头

      setState(() {
        _translateY = newTranslate;
        // 计算缩放：最大位移 400 时达到最小缩放
        double progress = (_translateY / 400.0).clamp(0.0, 1.0);
        _scale = 1.0 - (1.0 - _minScale) * progress;
      });

    } else {
      // 尚未开始拖拽
      if (isAtTop && delta > 0) {
        // 触发拖拽
        setState(() {
          _isDragging = true;
        });
        // 吃掉这个 delta，或者让它作为初始动量
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isAnimating) return;

    final velocity = _velocityTracker?.getVelocity().pixelsPerSecond.dy ?? 0.0;
    _velocityTracker = null;

    if (_isDragging) {
      setState(() {
        _isDragging = false;
      });

      // 判断是否关闭：距离够长 或者 速度够快（且方向向下）
      bool shouldDismiss = _translateY > _dismissThreshold || velocity > _velocityThreshold;

      // 如果速度是负的（向上甩），即使距离够了也应该回弹
      if (velocity < -500) {
        shouldDismiss = false;
      }

      if (shouldDismiss) {
        _runDismissAnimation(velocity);
      } else {
        _runReboundAnimation();
      }
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _velocityTracker = null;
    if (_isDragging) {
      setState(() {
        _isDragging = false;
      });
      _runReboundAnimation();
    }
  }

  void _runReboundAnimation() {
    _isAnimating = true;
    _animTranslate = Tween<double>(begin: _translateY, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutQuart), // 使用更平滑的曲线
    );
    _animScale = Tween<double>(begin: _scale, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutQuart),
    );

    _animController.reset();
    _animController.forward().then((_) {
      _isAnimating = false;
    });
  }

  void _runDismissAnimation(double velocity) {
    _isAnimating = true;

    // 如果有初速度，动画应该更快
    double endY = MediaQuery.of(context).size.height;
    // 简单的时长计算，速度越快时间越短
    int durationMs = 200;
    if (velocity > 1000) durationMs = 150;

    _animController.duration = Duration(milliseconds: durationMs);

    _animTranslate = Tween<double>(begin: _translateY, end: endY).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animScale = Tween<double>(begin: _scale, end: 0.8).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.reset();
    _animController.forward().then((_) {
      // 动画结束后回调
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 关键点：当正在拖拽时，禁用列表本身的滚动 Physics
    // 这比 jumpTo(0) 更平滑，也不会打断渲染管线
    final ScrollPhysics currentPhysics = _isDragging
        ? const NeverScrollableScrollPhysics()
        : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      behavior: HitTestBehavior.translucent, // 允许穿透，防止阻挡内部点击
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          // 性能优化：RepaintBoundary 隔离重绘区域
          return RepaintBoundary(
            child: Transform.translate(
              offset: Offset(0, _translateY),
              child: Transform.scale(
                scale: _scale,
                alignment: Alignment.bottomCenter, // 视觉上通常以底部或中心缩放会更好，看设计需求，原生多为 center
                child: Column(
                  children: [
                    Expanded(
                      child: widget.bodyBuilder(
                        context,
                        _scrollController,
                        currentPhysics, // 将 Physics 注入进去
                      ),
                    ),
                    widget.bottomBar,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}