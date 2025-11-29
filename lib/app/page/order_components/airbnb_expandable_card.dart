// airbnb_expandable_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/order_components/zoomable_edge_scroll_view.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

typedef AirbnbClosedBuilder = Widget Function(
    BuildContext context,
    VoidCallback open,
    );

typedef AirbnbOpenBuilder = Widget Function(
    BuildContext context,
    double scrollOffset,
    VoidCallback close,
    );

class AirbnbExpandableCard extends StatefulWidget {
  final AirbnbClosedBuilder closedBuilder;
  final AirbnbOpenBuilder openBuilder;

  /// 展开后卡片最大宽度占屏幕宽度比例
  final double maxWidthFactor;

  /// 展开后卡片最大高度占屏幕高度比例
  final double maxHeightFactor;

  /// 卡片圆角（收起态用）
  final double borderRadius;

  /// 展开动画时长
  final Duration transitionDuration;

  /// 收起动画时长
  final Duration reverseTransitionDuration;

  /// 遮罩基础颜色（逻辑上用这个，但真正 alpha 会跟动画和拖动一起变）
  final Color barrierColor;

  const AirbnbExpandableCard({
    super.key,
    required this.closedBuilder,
    required this.openBuilder,
    this.maxWidthFactor = 0.96,
    this.maxHeightFactor = 0.92,
    this.borderRadius = 28.0,
    this.transitionDuration = const Duration(milliseconds: 420),
    this.reverseTransitionDuration = const Duration(milliseconds: 360),
    this.barrierColor = const Color(0x40000000),
  });

  @override
  State<AirbnbExpandableCard> createState() => _AirbnbExpandableCardState();
}

class _AirbnbExpandableCardState extends State<AirbnbExpandableCard>
    with SingleTickerProviderStateMixin {
  /// 列表中“收起态卡片”的位置
  final GlobalKey _cardKey = GlobalKey();

  /// 当前这张卡片是否已经在展开态（Overlay 上那张）
  bool _isExpanded = false;

  /// 关闭回来时，底部这张卡片的小回弹动画
  late final AnimationController _reboundCtrl;
  late final Animation<double> _reboundCurve;

  /// hero 动画进度（0 → 1），由 overlay 那张卡片驱动
  final ValueNotifier<double> _heroProgress = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _reboundCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _reboundCurve = CurvedAnimation(
      parent: _reboundCtrl,
      curve: Curves.easeOutBack, // 关闭时的“韧性”
    );
  }

  @override
  void dispose() {
    _reboundCtrl.dispose();
    _heroProgress.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final ctx = _cardKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;

    // 1️⃣ 当前卡片在屏幕坐标系里的 Rect
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final fromRect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      size.width,
      size.height,
    );

    // 展开前把回弹动画停掉 & 归零
    _reboundCtrl.stop();
    _reboundCtrl.value = 0.0;
    _heroProgress.value = 0.0;

    // 2️⃣ 标记：列表里的这张卡片进入“背景态”
    setState(() {
      _isExpanded = true;
    });

    // 3️⃣ 推透明路由 + RectTween 动画
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: widget.transitionDuration,
        reverseTransitionDuration: widget.reverseTransitionDuration,
        pageBuilder: (ctx, animation, secondaryAnimation) {
          return _AirbnbOverlayRouteBody(
            fromRect: fromRect,
            closedRadius: widget.borderRadius,
            maxWidthFactor: widget.maxWidthFactor,
            maxHeightFactor: widget.maxHeightFactor,
            openBuilder: widget.openBuilder,
            barrierColor: widget.barrierColor,
            heroProgress: _heroProgress, // 👈 同步进度
          );
        },
        transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
          return child; // 不再额外 Fade 一遍，避免“闪一下”
        },
      ),
    );

    // 4️⃣ 关闭回来：让 closed 卡片做一个“收紧 + 轻轻落地”的小回弹
    if (!mounted) return;
    setState(() {
      _isExpanded = false;
      _heroProgress.value = 0.0; // 回到初始
    });
    _reboundCtrl.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      // 展开的时候避免底下还能点到
      ignoring: _isExpanded,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _reboundCtrl,
          _heroProgress,
        ]),
        builder: (context, child) {
          final tHero = _heroProgress.value; // 0 → 1

          // 🔥 加强一点：底部卡片明显“沉下去、暗下去”
          final baseScale = lerpDouble(1.0, 0.93, tHero)!; // 原来 0.97
          final baseOpacity = lerpDouble(1.0, 0.32, tHero)!; // 原来 0.55
          final baseDy = lerpDouble(0.0, 6.w, tHero)!; // 下沉一点

          // 回弹：1.02 → 1.0（很轻），只在关闭后那一小段时间起作用
          final reboundT = _reboundCurve.value; // 0 → 1
          final reboundScale = lerpDouble(1.02, 1.0, reboundT)!;
          final reboundDy = lerpDouble(-2.w, 0.0, reboundT)!;

          final scale = baseScale * reboundScale;
          final dy = baseDy + reboundDy;

          return Opacity(
            opacity: baseOpacity,
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: child,
              ),
            ),
          );
        },
        child: Container(
          key: _cardKey,
          child: widget.closedBuilder(context, _open),
        ),
      ),
    );
  }
}

// ==================== 下面 overlay / hero 部分保持上一版不变 ====================

class _AirbnbOverlayRouteBody extends StatelessWidget {
  final Rect fromRect;
  final double closedRadius;
  final double maxWidthFactor;
  final double maxHeightFactor;
  final AirbnbOpenBuilder openBuilder;
  final Color barrierColor;

  /// hero 进度同步给列表里的 closedBuilder
  final ValueNotifier<double> heroProgress;

  // 拖动时的“亮度/遮罩”因子（0 ~ 1）
  final ValueNotifier<double> dimFactor = ValueNotifier<double>(1.0);

  _AirbnbOverlayRouteBody({
    required this.fromRect,
    required this.closedRadius,
    required this.maxWidthFactor,
    required this.maxHeightFactor,
    required this.openBuilder,
    required this.barrierColor,
    required this.heroProgress,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // 用比例 + 居中（maxWidthFactor / maxHeightFactor = 1 就是全屏）
    final double targetWidth = size.width * maxWidthFactor;
    final double targetHeight = size.height * maxHeightFactor;

    final Rect toRect = Rect.fromLTWH(
      (size.width - targetWidth) / 2,
      (size.height - targetHeight) / 2,
      targetWidth,
      targetHeight,
    );

    void close() {
      Navigator.of(context).maybePop();
    }

    final route = ModalRoute.of(context)!;
    final animation = route.animation!;
    final maskCurve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return AnimatedBuilder(
      animation: maskCurve,
      builder: (context, _) {
        return ValueListenableBuilder<double>(
          valueListenable: dimFactor,
          builder: (context, dim, __) {
            // 背景遮罩 alpha/模糊 跟 route 动画 + 拖动一起变
            final baseAlpha = barrierColor.opacity;
            final currentAlpha = baseAlpha * maskCurve.value * dim;
            final currentBlur = 18 * maskCurve.value * dim;

            return Stack(
              children: [
                // 1️⃣ 背景虚化 + 遮罩（完全拦截手势）
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: close,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: currentBlur,
                        sigmaY: currentBlur,
                      ),
                      child: Container(
                        color: barrierColor.withOpacity(currentAlpha),
                      ),
                    ),
                  ),
                ),

                // 2️⃣ fromRect → heroRect → toRect 的卡片
                _AnimatedCardFromRect(
                  fromRect: fromRect,
                  toRect: toRect,
                  heroProgress: heroProgress, // 👈 把进度写回去
                  child: _ZoomableDialogShell(
                    borderRadius: closedRadius,
                    openBuilder: openBuilder,
                    onClose: close,
                    // 👇 下拉时实时调节 dimFactor，拖得越多越亮
                    onDimFactorChanged: (value) {
                      dimFactor.value = value;
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ZoomableDialogShell extends StatelessWidget {
  final double borderRadius;
  final AirbnbOpenBuilder openBuilder;
  final VoidCallback onClose;

  /// 下拉时修改遮罩亮度的回调（0 ~ 1）
  final ValueChanged<double>? onDimFactorChanged;

  const _ZoomableDialogShell({
    required this.borderRadius,
    required this.openBuilder,
    required this.onClose,
    this.onDimFactorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ZoomableEdgeScrollView(
      enableTopEdgeDismiss: true,
      enableScale: true,
      maxDragDistance: 220.0,
      minScale: 0.96,
      scaleAlignment: Alignment.topCenter,
      baseRadius: borderRadius,
      maxRadius: borderRadius == 0 ? 0 : borderRadius + 8.w,
      onDismiss: onClose,
      builder: (context, scrollOffset) {
        // 利用 scrollOffset < 0 代表下拉的距离，来调节遮罩亮度
        if (onDimFactorChanged != null) {
          double drag = 0;
          if (scrollOffset < 0) {
            drag = (-scrollOffset / 220.0).clamp(0.0, 1.0);
          }
          final dim = 1.0 - drag * 0.8; // 最多亮到 20%
          onDimFactorChanged!(dim);
        }

        return openBuilder(context, scrollOffset, onClose);
      },
    );
  }
}

class _AnimatedCardFromRect extends StatelessWidget {
  final Rect fromRect;
  final Rect toRect;
  final Widget child;
  final ValueNotifier<double>? heroProgress;

  const _AnimatedCardFromRect({
    required this.fromRect,
    required this.toRect,
    required this.child,
    this.heroProgress,
  });

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)!;
    final animation = route.animation!;

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn,
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final t = curved.value; // 0 → 1 / 1 → 0
        heroProgress?.value = t; // 👈 同步给 closedBuilder

        // ① hero 中间态：模拟从列表里“站起来”
        final center = fromRect.center;
        const double scaleW = 1.06;
        const double scaleH = 1.08;
        const double lift = 10.0;

        double heroWidth = fromRect.width * scaleW;
        double heroHeight = fromRect.height * scaleH;

        heroWidth = heroWidth.clamp(fromRect.width, toRect.width);
        heroHeight = heroHeight.clamp(fromRect.height, toRect.height * 0.96);

        Rect heroRect = Rect.fromCenter(
          center: center,
          width: heroWidth,
          height: heroHeight,
        ).translate(0, -lift);

        const double minTop = 8.0;
        if (heroRect.top < minTop) {
          final dyFix = minTop - heroRect.top;
          heroRect = heroRect.translate(0, dyFix);
        }

        // ② 两段插值：前 38% “站起来”，后面飞到目标位
        const double midT = 0.38;

        Rect current;
        if (t <= midT) {
          final phase = (t / midT).clamp(0.0, 1.0);
          final eased = Curves.easeOutCubic.transform(phase);
          current = Rect.lerp(fromRect, heroRect, eased)!;
        } else {
          final phase = ((t - midT) / (1 - midT)).clamp(0.0, 1.0);
          final eased = Curves.easeInOutCubic.transform(phase);
          current = Rect.lerp(heroRect, toRect, eased)!;
        }

        return Positioned(
          left: current.left,
          top: current.top,
          width: current.width,
          height: current.height,
          child: child,
        );
      },
    );
  }
}