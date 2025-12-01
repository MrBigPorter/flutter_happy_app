import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

typedef ScrollBodyBuilder = Widget Function(
    BuildContext context, ScrollController controller, ScrollPhysics physics);

class AirbnbStyleScaffold extends StatefulWidget {
  final ScrollBodyBuilder bodyBuilder;
  final Widget bottomBar;
  /// 浮动在内容之上的组件（通常是 Header），会跟随卡片一起缩放
  final Widget floatingHeader;
  final VoidCallback onDismiss;
  /// 【新增】Hero 动画标签，用于连接列表页和详情页
  final String? heroTag;

  const AirbnbStyleScaffold({
    super.key,
    required this.bodyBuilder,
    required this.bottomBar,
    required this.floatingHeader,
    required this.onDismiss,
    this.heroTag, // 【新增】构造函数接收 tag
  });

  @override
  State<AirbnbStyleScaffold> createState() => _AirbnbStyleScaffoldState();
}

class _AirbnbStyleScaffoldState extends State<AirbnbStyleScaffold>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animController;
  late Animation<double> _animTranslateY;
  late Animation<double> _animScale;
  late Animation<double> _animRadius;

  double _translateY = 0.0;
  double _scale = 1.0;
  double _borderRadius = 0.0;
  bool _isDragging = false;
  bool _isAnimating = false;

  // 配置参数
  static const double _dismissThreshold = 150.0; // 拉动超过多少则关闭
  static const double _scaleTarget = 0.92; // 缩放目标
  static const double _radiusTarget = 32.0; // 圆角目标

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..addListener(() {
      setState(() {
        _translateY = _animTranslateY.value;
        _scale = _animScale.value;
        _borderRadius = _animRadius.value;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_isAnimating) return;
    _isDragging = false;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isAnimating) return;

    final dy = event.delta.dy;
    bool isAtTop = !_scrollController.hasClients || _scrollController.offset <= 0;

    if (_isDragging) {
      double friction = 1.0 - (_translateY / 800.0).clamp(0.0, 0.7);
      _translateY += dy * friction;
      if (_translateY < 0) _translateY = 0;

      double progress = (_translateY / 400.0).clamp(0.0, 1.0);

      _scale = 1.0 - ((1.0 - _scaleTarget) * progress);
      _borderRadius = _radiusTarget * (progress * 4).clamp(0.0, 1.0);

      setState(() {});
    } else {
      if (isAtTop && dy > 0) {
        setState(() => _isDragging = true);
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isAnimating) return;
    if (_isDragging) {
      _isDragging = false;
      // 【修改】核心逻辑变动
      if (_translateY > _dismissThreshold) {
        // 1. 如果超过阈值，直接调用 onDismiss (pop)
        // 2. 不要再跑手动动画了，Flutter 的 Hero 会接管剩下的一切
        // 3. Hero 会从当前的 _translateY 和 _scale 状态直接飞回列表页
        widget.onDismiss();
      } else {
        // 没超过阈值，回弹复位
        _runReboundAnim();
      }
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_isDragging) {
      setState(() => _isDragging = false);
      _runReboundAnim();
    }
  }

  // 回弹动画保持不变
  void _runReboundAnim() {
    _isAnimating = true;
    _animTranslateY = Tween<double>(begin: _translateY, end: 0)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutQuart));
    _animScale = Tween<double>(begin: _scale, end: 1.0)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutQuart));
    _animRadius = Tween<double>(begin: _borderRadius, end: 0.0)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutQuart));

    _animController.reset();
    _animController.forward().then((_) => _isAnimating = false);
  }

  // 【移除】 _runDismissAnim 方法被删除
  // 因为我们不再需要手动的"向下掉落"动画，而是依赖 Hero 的"缩回"动画

  @override
  Widget build(BuildContext context) {
    double bgOpacity = 1.0 - (_translateY / 600.0).clamp(0.0, 1.0);

    ScrollPhysics physics = _isDragging
        ? const NeverScrollableScrollPhysics()
        : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

    // 【新增】将卡片内容提取出来
    Widget cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(_borderRadius),
      child: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: _scale < 1.0
                ? [const BoxShadow(color: Colors.black26, blurRadius: 40, spreadRadius: 10)]
                : null
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: widget.bodyBuilder(context, _scrollController, physics),
                ),
                widget.bottomBar,
              ],
            ),
            widget.floatingHeader,
          ],
        ),
      ),
    );

    // 【新增】如果有 heroTag，用 Hero 包裹卡片内容
    if (widget.heroTag != null) {
      cardContent = Hero(
        tag: widget.heroTag!,
        // 使用 Material 包裹防止飞行过程中文字出现黄色下划线
        child: Material(
          type: MaterialType.transparency,
          child: cardContent,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. 动态背景遮罩
          GestureDetector(
            onTap: () {
              // 点击空白处，如果卡片已经缩小，则回弹；如果想直接关闭也可以调 widget.onDismiss()
              if (_scale < 1.0) widget.onDismiss();
            },
            child: Container(
              color: Colors.black.withOpacity(0.5 * bgOpacity),
            ),
          ),

          // 2. 缩放的主体卡片
          Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
            child: Transform.translate(
              offset: Offset(0, _translateY),
              child: Transform.scale(
                scale: _scale,
                alignment: Alignment.bottomCenter,
                // Hero 应该包裹在 Transform 内部，ClipRRect 外部/内部皆可，
                // 这里的顺序是 Transform -> Hero -> ClipRRect -> Container
                child: cardContent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}