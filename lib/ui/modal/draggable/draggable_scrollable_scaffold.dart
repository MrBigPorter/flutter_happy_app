import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';

// 定义构建滚动内容的函数类型，必须接收 controller 和 physics 以便组件内部控制
typedef ScrollBodyBuilder =
    Widget Function(
      BuildContext context,
      ScrollController controller,
      ScrollPhysics physics,
    );

typedef DraggableHeaderBuilder =
    Widget Function(
      BuildContext context,
      double dragProgress,
      ScrollController controller,
    );

/// 提供给子组件访问的拖拽状态 InheritedWidget
/// 包含当前拖拽进度和偏移量
/// 进度范围 0.0 - 1.0
/// 偏移量为垂直拖拽的像素值
/// 子组件可通过 DraggableSheetStatus.of(context) 获取实例
/// 或通过 DraggableSheetStatus.progressOf(context) 获取进度值
class DraggableSheetStatus extends InheritedWidget {
  final double progress; // 0.0 - 1.0
  final double dragOffset; // 垂直拖拽偏移量

  const DraggableSheetStatus({
    super.key,
    required super.child,
    required this.progress,
    required this.dragOffset,
  });

  static double progressOf(BuildContext context) {
    final status = context
        .dependOnInheritedWidgetOfExactType<DraggableSheetStatus>();
    return status?.progress ?? 0.0;
  }

  static DraggableSheetStatus? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DraggableSheetStatus>();
  }

  @override
  bool updateShouldNotify(covariant DraggableSheetStatus oldWidget) {
    return progress != oldWidget.progress || dragOffset != oldWidget.dragOffset;
  }
}

class DraggableScrollableScaffold extends StatefulWidget {
  /// 构建内部滚动视图的 Builder
  final ScrollBodyBuilder bodyBuilder;

  /// 悬浮在内容之上的组件（如关闭按钮或标题栏），不随内容滚动，但随卡片缩放
  final DraggableHeaderBuilder? headerBuilder;

  /// 固定在底部的组件（如操作按钮）
  final Widget? bottomBar;

  /// 关闭时的回调（通常执行 Navigator.pop）
  final VoidCallback onDismiss;

  /// Hero 动画标签，用于连接列表页和详情页
  final String? heroTag;

  /// 卡片内容的背景色
  final Color? backgroundColor;

  // --- 配置参数 ---
  final double dismissThreshold; // 触发关闭的拖拽距离阈值
  final double scaleTarget; // 最大缩放比例（例如 0.92）
  final double radiusTarget; // 最大圆角大小
  final Duration animationDuration; // 回弹动画时长

  const DraggableScrollableScaffold({
    super.key,
    required this.bodyBuilder,
    required this.onDismiss,
    this.headerBuilder,
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
  // 核心控制器
  late final ScrollController _scrollController;
  late final AnimationController _animController;

  // 动画值（用于回弹）
  late Animation<double> _animTranslateY;
  late Animation<double> _animScale;
  late Animation<double> _animRadius;

  // [状态标志]
  bool _isDragging = false; // 是否正在手势拖拽中
  bool _isAnimating = false; // 是否正在执行回弹动画中

  // [UI 变换参数]
  double _translateY = 0.0; // 垂直位移距离
  double _scale = 1.0; // 当前缩放比例
  double _borderRadius = 0.0; // 当前圆角大小

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // 初始化回弹动画控制器
    _animController =
        AnimationController(vsync: this, duration: widget.animationDuration)
          ..addListener(() {
            // 监听动画每一帧，更新状态，驱动 UI 重绘
            setState(() {
              _translateY = _animTranslateY.value;
              _scale = _animScale.value;
              _borderRadius = _animRadius.value;
            });
          });
  }

  @override
  void dispose() {
    // [重要] 销毁控制器，防止内存泄漏
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    // 如果正在回弹，禁止打断，防止状态冲突
    if (_isAnimating) return;
    _isDragging = false;
  }

  // [核心逻辑] 处理手指移动
  void _onPointerMove(PointerMoveEvent event) {
    if (_isAnimating) return;

    final dy = event.delta.dy; // 手指垂直移动的增量

    // 判断列表是否已滚动到顶部
    final isAtTop =
        !_scrollController.hasClients || _scrollController.offset <= 0;

    // 获取屏幕高度，用于计算阻尼系数
    final screenHeight = MediaQuery.of(context).size.height;

    // --- 分支 A: 已经在拖拽模式 ---
    if (_isDragging) {
      // 1. 计算物理阻尼 (Friction)
      // 公式含义：拉得越远(_translateY越大)，摩擦力越大(friction越小)，拉起来越费劲
      double friction = 1.0 - (_translateY / screenHeight).clamp(0.0, 0.7);
      _translateY += dy * friction;

      // 禁止向上推过头（不允许负位移）
      if (_translateY < 0) _translateY = 0;

      // 2. 计算视觉进度 (Progress)
      // 设定：拉动半个屏幕高度时，达到最大形变
      double progress = (_translateY / (screenHeight / 2)).clamp(0.0, 1.0);

      // 3. 映射属性
      // 缩放：1.0 -> 0.92
      _scale = 1.0 - (1.0 - widget.scaleTarget) * progress;
      // 圆角：0 -> 32
      _borderRadius = widget.radiusTarget * (progress * 4).clamp(0.0, 1.0);

      setState(() {});
    }
    // --- 分支 B: 检测是否应该开始拖拽 ---
    else {
      // 如果列表在顶部，且手指还在向下滑动
      if (isAtTop && dy > 0) {
        setState(() {
          _isDragging = true;
          // 注意：这里没有立即加 dy，而是标记状态。
          // 让下一帧 PointerMove 带着 friction 去平滑计算，防止第一帧跳变。
        });
      }
    }
  }

  // [回弹逻辑] 松手后如果没关闭，弹回原位
  void _runReboundAnim() {
    _isAnimating = true;
    // 使用 easeOutQuart 曲线，模拟强力磁铁吸附效果（快进慢出）
    final curve = Curves.easeOutQuart;

    _animTranslateY = Tween<double>(
      begin: _translateY,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _animController, curve: curve));
    _animScale = Tween<double>(
      begin: _scale,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: curve));
    _animRadius = Tween<double>(
      begin: _borderRadius,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _animController, curve: curve));

    _animController.reset();
    _animController.forward().then((_) {
      if (mounted) _isAnimating = false;
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isAnimating) return;
    if (_isDragging) {
      _isDragging = false;
      // 判断是否超过关闭阈值
      if (_translateY > widget.dismissThreshold) {
        widget.onDismiss.call(); // 触发关闭
      } else {
        _runReboundAnim(); // 触发回弹
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
    // [手势接管关键]
    // 当拖拽整个卡片时，禁止内部列表滚动，确保手势不冲突
    ScrollPhysics physics = _isDragging
        ? const NeverScrollableScrollPhysics()
        : const BouncingScrollPhysics();

    // 计算背景透明度：拉得越远越透明
    final normalizedProgress =
        (_translateY / (MediaQuery.of(context).size.height / 2)).clamp(
          0.0,
          1.0,
        );
    final bgOpacity = 1.0 - normalizedProgress;

    final double blurSigma = 10.0 * bgOpacity;

    // 构建页面主体内容
    Widget cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(_borderRadius), // 动态圆角
      child: RepaintBoundary(
        // [性能优化]
        // 开启 RepaintBoundary，拖拽时将内容缓存为纹理。
        // GPU 只需移动纹理，无需重绘复杂的子组件，大幅提升帧率。
        child: Container(
          color: widget.backgroundColor ?? context.bgPrimary,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // [Hero 保护]
              // 在 Hero 动画飞行初期，容器高度可能极小。
              // 此时隐藏内容，防止 RenderFlex Overflow 溢出报错。
              if (constraints.maxHeight < 100) {
                return const SizedBox.shrink();
              }
              // [布局结构] 使用 Stack 实现悬浮头部的正确层级
              return DraggableSheetStatus(
                progress: normalizedProgress,
                dragOffset: _translateY,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // 滚动区域
                        Expanded(
                          child: widget.bodyBuilder(
                            context,
                            _scrollController,
                            physics,
                          ),
                        ),
                        // 底部固定栏
                        if (widget.bottomBar != null) widget.bottomBar!,
                      ],
                    ),
                    // 悬浮头部 (如关闭按钮)，浮在内容之上
                    if (widget.headerBuilder != null)
                      widget.headerBuilder!(
                        context,
                        normalizedProgress,
                        _scrollController,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    // 如果提供了 Hero 标签，包裹 Material 组件以支持飞行动画
    if (widget.heroTag != null) {
      cardContent = Hero(
        tag: widget.heroTag!,
        child: Material(type: MaterialType.transparency, child: cardContent),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false, // 防止键盘弹出挤压布局
      body: Stack(
        children: [
          // 1. 背景遮罩层
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Container(
                color: Colors.black.withValues(alpha: 0.3 * bgOpacity),
              ),
            ),
          ),

          // 2. 交互层
          Positioned.fill(
            child: Listener(
              // [无盲区监听] 确保点击透明区域也能触发手势
              behavior: HitTestBehavior.translucent,
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: Transform.translate(
                offset: Offset(0, _translateY), // 应用位移
                child: Transform.scale(
                  scale: _scale, // 应用缩放
                  alignment: Alignment.bottomCenter, // 底部对齐，实现抽屉效果
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
