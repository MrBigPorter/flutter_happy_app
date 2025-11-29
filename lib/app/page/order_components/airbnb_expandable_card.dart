// airbnb_expandable_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'zoomable_edge_scroll_view.dart';

typedef AirbnbClosedBuilder = Widget Function(
    BuildContext context,
    VoidCallback open,
    );

/// 中间可滚 body
typedef AirbnbOpenBodyBuilder = Widget Function(
    BuildContext context,
    ScrollController scrollController,
    double scrollOffset,
    VoidCallback close,
    );

/// 顶部 Header（固定在卡片内部）
typedef AirbnbHeaderBuilder = Widget Function(
    BuildContext context,
    double scrollOffset,
    VoidCallback close,
    );

/// 底部 BottomBar（固定在卡片内部）
typedef AirbnbBottomBarBuilder = Widget Function(
    BuildContext context,
    double scrollOffset,
    VoidCallback close,
    );

class AirbnbExpandableCard extends StatefulWidget {
  final AirbnbClosedBuilder closedBuilder;
  final AirbnbOpenBodyBuilder openBodyBuilder;

  final AirbnbHeaderBuilder? headerBuilder;
  final AirbnbBottomBarBuilder? bottomBarBuilder;

  final double maxWidthFactor;
  final double maxHeightFactor;
  final double borderRadius;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;
  final Color barrierColor;

  const AirbnbExpandableCard({
    super.key,
    required this.closedBuilder,
    required this.openBodyBuilder,
    this.headerBuilder,
    this.bottomBarBuilder,
    this.maxWidthFactor = 0.96,
    this.maxHeightFactor = 0.92,
    this.borderRadius = 28.0,
    this.transitionDuration = const Duration(milliseconds: 420),
    this.reverseTransitionDuration = const Duration(milliseconds: 360),
    this.barrierColor = const Color(0x40000000),
  });

  @override
  State<AirbnbExpandableCard> createState() =>
      _AirbnbExpandableCardState();
}

class _AirbnbExpandableCardState extends State<AirbnbExpandableCard>
    with SingleTickerProviderStateMixin {
  final GlobalKey _cardKey = GlobalKey();
  bool _isExpanded = false;

  late final AnimationController _reboundCtrl;
  late final Animation<double> _reboundCurve;
  final ValueNotifier<double> _heroProgress =
  ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _reboundCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _reboundCurve = CurvedAnimation(
      parent: _reboundCtrl,
      curve: Curves.easeOutBack,
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

    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final fromRect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      size.width,
      size.height,
    );

    _reboundCtrl.stop();
    _reboundCtrl.value = 0.0;
    _heroProgress.value = 0.0;

    setState(() {
      _isExpanded = true;
    });

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
            openBodyBuilder: widget.openBodyBuilder,
            headerBuilder: widget.headerBuilder,
            bottomBarBuilder: widget.bottomBarBuilder,
            barrierColor: widget.barrierColor,
            heroProgress: _heroProgress,
          );
        },
        transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
          return child;
        },
      ),
    );

    if (!mounted) return;
    setState(() {
      _isExpanded = false;
      _heroProgress.value = 0.0;
    });
    _reboundCtrl.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: _isExpanded,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _reboundCtrl,
          _heroProgress,
        ]),
        builder: (context, child) {
          final tHero = _heroProgress.value;

          final baseScale = lerpDouble(1.0, 0.93, tHero)!;
          final baseOpacity = lerpDouble(1.0, 0.32, tHero)!;
          final baseDy = lerpDouble(0.0, 6.w, tHero)!;

          final reboundT = _reboundCurve.value;
          final reboundScale =
          lerpDouble(1.02, 1.0, reboundT)!;
          final reboundDy =
          lerpDouble(-2.w, 0.0, reboundT)!;

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

// ==================== overlay / hero 部分 ====================

class _AirbnbOverlayRouteBody extends StatelessWidget {
  final Rect fromRect;
  final double closedRadius;
  final double maxWidthFactor;
  final double maxHeightFactor;
  final AirbnbOpenBodyBuilder openBodyBuilder;
  final AirbnbHeaderBuilder? headerBuilder;
  final AirbnbBottomBarBuilder? bottomBarBuilder;
  final Color barrierColor;
  final ValueNotifier<double> heroProgress;

  final ValueNotifier<double> dimFactor =
  ValueNotifier<double>(1.0);

  _AirbnbOverlayRouteBody({
    required this.fromRect,
    required this.closedRadius,
    required this.maxWidthFactor,
    required this.maxHeightFactor,
    required this.openBodyBuilder,
    required this.headerBuilder,
    required this.bottomBarBuilder,
    required this.barrierColor,
    required this.heroProgress,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
            final baseAlpha = barrierColor.opacity;
            final currentAlpha = baseAlpha * maskCurve.value * dim;
            final currentBlur = 18 * maskCurve.value * dim;

            return Stack(
              children: [
                // 背景虚化 + 遮罩
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
                // 卡片本体
                _AnimatedCardFromRect(
                  fromRect: fromRect,
                  toRect: toRect,
                  heroProgress: heroProgress,
                  child: _ZoomableDialogShell(
                    borderRadius: closedRadius,
                    openBodyBuilder: openBodyBuilder,
                    headerBuilder: headerBuilder,
                    bottomBarBuilder: bottomBarBuilder,
                    onClose: close,
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
  final AirbnbOpenBodyBuilder openBodyBuilder;
  final AirbnbHeaderBuilder? headerBuilder;
  final AirbnbBottomBarBuilder? bottomBarBuilder;
  final VoidCallback onClose;
  final ValueChanged<double>? onDimFactorChanged;

  const _ZoomableDialogShell({
    required this.borderRadius,
    required this.openBodyBuilder,
    required this.onClose,
    this.headerBuilder,
    this.bottomBarBuilder,
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
      maxRadius: borderRadius,
      onDismiss: onClose,

      // 顶部固定 header
      headerBuilder: headerBuilder == null
          ? null
          : (ctx, scrollOffset) {
        return headerBuilder!(ctx, scrollOffset, onClose);
      },

      // 底部固定 bottomBar
      bottomBuilder: bottomBarBuilder == null
          ? null
          : (ctx, scrollOffset) {
        return bottomBarBuilder!(ctx, scrollOffset, onClose);
      },

      // 中间可滚 body
      bodyBuilder:
          (ctx, scrollController, scrollOffset) {
        if (onDimFactorChanged != null) {
          // 暂时先固定 1.0，有需要你可以用 scrollOffset / 下拉距离去算
          onDimFactorChanged!(1.0);
        }
        return openBodyBuilder(
          ctx,
          scrollController,
          scrollOffset,
          onClose,
        );
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
        final t = curved.value;

        if (heroProgress != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            heroProgress!.value = t;
          });
        }

        final center = fromRect.center;
        const double scaleW = 1.06;
        const double scaleH = 1.08;
        const double lift = 10.0;

        double heroWidth = fromRect.width * scaleW;
        double heroHeight = fromRect.height * scaleH;

        heroWidth = heroWidth.clamp(fromRect.width, toRect.width);
        heroHeight =
            heroHeight.clamp(fromRect.height, toRect.height * 0.96);

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

        const double midT = 0.38;
        Rect current;
        if (t <= midT) {
          final phase = (t / midT).clamp(0.0, 1.0);
          final eased = Curves.easeOutCubic.transform(phase);
          current = Rect.lerp(fromRect, heroRect, eased)!;
        } else {
          final phase =
          ((t - midT) / (1 - midT)).clamp(0.0, 1.0);
          final eased =
          Curves.easeInOutCubic.transform(phase);
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