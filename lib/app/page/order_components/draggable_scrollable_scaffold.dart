import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';

typedef ScrollBodyBuilder = Widget Function(
    BuildContext context, ScrollController controller, ScrollPhysics physics);

class DraggableScrollableScaffold extends StatefulWidget {
  final ScrollBodyBuilder bodyBuilder;
  final Widget? floatingHeader;
  final Widget? bottomBar;
  final VoidCallback onDismiss;
  final String? heroTag;
  final Color? backgroundColor;

  final double dismissThreshold;
  final double scaleTarget;
  final double radiusTarget;
  final Duration animationDuration;

  const DraggableScrollableScaffold({
    super.key,
    required this.bodyBuilder,
    required this.onDismiss,
    this.floatingHeader,
    this.bottomBar,
    this.heroTag,
    this.backgroundColor,
    this.dismissThreshold = 150.0,
    this.scaleTarget = 0.92,
    this.radiusTarget = 32.0,
    this.animationDuration = const Duration(milliseconds: 350),
  });

  @override
  State<DraggableScrollableScaffold> createState() =>
      _DraggableScrollableScaffoldState();
}

class _DraggableScrollableScaffoldState
    extends State<DraggableScrollableScaffold>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _animController;
  late Animation<double> _animTranslateY;
  late Animation<double> _animScale;
  late Animation<double> _animRadius;

  bool _isDragging = false;
  bool _isAnimating = false;

  double _translateY = 0.0;
  double _scale = 1.0;
  double _borderRadius = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
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
    final isAtTop =
        !_scrollController.hasClients || _scrollController.offset <= 0;

    // 建议：如果对性能极度敏感，可将此值通过 build 传递或缓存
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isDragging) {
      double friction = 1.0 - (_translateY / screenHeight).clamp(0.0, 0.7);
      _translateY += dy * friction;

      if (_translateY < 0) _translateY = 0;

      double progress = (_translateY / (screenHeight / 2)).clamp(0.0, 1.0);

      _scale = 1.0 - (1.0 - widget.scaleTarget) * progress;
      _borderRadius = widget.radiusTarget * (progress * 4).clamp(0.0, 1.0);

      setState(() {});
    } else {
      if (isAtTop && dy > 0) {
        setState(() {
          _isDragging = true;
        });
      }
    }
  }

  void _runReboundAnim() {
    _isAnimating = true;
    final curve = Curves.easeOutQuart;

    _animTranslateY = Tween<double>(begin: _translateY, end: 0.0)
        .animate(CurvedAnimation(parent: _animController, curve: curve));
    _animScale = Tween<double>(begin: _scale, end: 1.0)
        .animate(CurvedAnimation(parent: _animController, curve: curve));
    _animRadius = Tween<double>(begin: _borderRadius, end: 0.0)
        .animate(CurvedAnimation(parent: _animController, curve: curve));

    _animController.reset();
    _animController.forward().then((_) {
      if (mounted) _isAnimating = false;
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isAnimating) return;
    if (_isDragging) {
      _isDragging = false;
      if (_translateY > widget.dismissThreshold) {
        widget.onDismiss.call();
      } else {
        _runReboundAnim();
      }
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_isDragging) {
      _isDragging = false;
      _runReboundAnim();
    }
  }

  @override
  Widget build(BuildContext context) {
    ScrollPhysics physics = _isDragging
        ? const NeverScrollableScrollPhysics()
        : const BouncingScrollPhysics();

    final bgOpacity = 1.0 - (_translateY / 600.0).clamp(0.0, 1.0);

    Widget cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(_borderRadius),
      child: RepaintBoundary(
        child: Container(
          color: widget.backgroundColor ?? context.bgPrimary,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 1. Hero 动画保护：如果高度太小，不渲染内容
              if (constraints.maxHeight < 100) {
                return const SizedBox.shrink();
              }
              // 2. 布局结构优化：使用 Stack 而不是 Column
              // 这样 floatingHeader 是真正的“浮动”，不会占据内容空间
              return Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: widget.bodyBuilder(
                          context,
                          _scrollController,
                          physics,
                        ),
                      ),
                      if (widget.bottomBar != null) widget.bottomBar!,
                    ],
                  ),
                  if (widget.floatingHeader != null) widget.floatingHeader!,
                ],
              );
            },
          ),
        ),
      ),
    );

    if (widget.heroTag != null) {
      cardContent = Hero(
        tag: widget.heroTag!,
        child: Material(
          type: MaterialType.transparency,
          child: cardContent,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. 遮罩层：强制使用黑色，确保在 DarkMode 下也是变暗而不是变白
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5 * bgOpacity),
            ),
          ),
          // 2. 手势监听层：使用 Positioned.fill 撑满全屏
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: Transform.translate(
                offset: Offset(0, _translateY),
                child: Transform.scale(
                  scale: _scale,
                  alignment: Alignment.bottomCenter,
                  child: cardContent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}