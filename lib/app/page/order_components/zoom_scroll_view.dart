import 'package:flutter/material.dart';

typedef ScrollBodyBuilder = Widget Function(
    BuildContext context,
    ScrollController scrollController,
    double scrollOffset,
    );

/// ZoomScrollView
/// ------------------------------------------------------------------
/// - 顶部继续下拉：内容 + bottomBar 一起下移 + 轻微缩小
/// - 手指松开那一刻：
///   - 看松手时那一下的下拉距离（_releaseOverscroll）
///   - >= 阈值：走一小段“快速下沉缩小”动画 → 动画结束立刻 onDismiss()
///   - <  阈值：回弹复位，不关闭
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

  /// 提供给外部 header 用的滚动偏移（只算 >= 0 的部分）
  double _scrollOffset = 0.0;

  /// 整体位移 & 缩放
  double _translateY = 0.0;
  double _scale = 1.0;

  /// 当前这一轮是否「在顶部往下拖」
  bool _dragFromTop = false;

  /// 手指在顶部拖动时的当前下拉距离（实时值）
  double _currentOverscroll = 0.0;

  /// 记录“松手那一刻”的下拉距离（只看这一下）
  double _releaseOverscroll = 0.0;

  /// 当前是否已经在执行关闭流程
  bool _isClosing = false;

  /// 关闭阈值（px）：下拉超过这个距离就认为是想关
  static const double _dismissDragDistance = 120.0;

  /// 最多缩小 8%
  static const double _maxScaleDelta = 0.08;

  /// 关闭动画控制器
  late final AnimationController _closeController;
  double _closeStartTranslateY = 0.0;
  double _closeStartScale = 1.0;

  @override
  void initState() {
    super.initState();
    _closeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140), // 关的更干脆一点
    )
      ..addListener(() {
        final t = Curves.easeInCubic.transform(_closeController.value);
        // 关闭时再往下沉一点、再缩小一点
        setState(() {
          _translateY = _closeStartTranslateY + 60.0 * t;
          _scale = _closeStartScale - (_closeStartScale - 0.85) * t;
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onDismiss();
        }
      });
  }

  @override
  void dispose() {
    _closeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _resetTransform() {
    if (_translateY == 0.0 && _scale == 1.0) return;
    setState(() {
      _translateY = 0.0;
      _scale = 1.0;
    });
  }

  void _startCloseAnimation() {
    if (_isClosing) return;
    _isClosing = true;

    // 避免列表自己再弹一段
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }

    _closeStartTranslateY = _translateY;
    _closeStartScale = _scale;

    _closeController.forward(from: 0.0);
  }

  bool _handleScroll(ScrollNotification notification) {
    if (_isClosing) return false;

    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical) return false;

    // 1️⃣ 通用：header 渐变 offset（>= 0 的部分）
    if (notification is ScrollUpdateNotification ||
        notification is OverscrollNotification) {
      final off = metrics.pixels > 0 ? metrics.pixels : 0.0;
      if (off != _scrollOffset) {
        _scrollOffset = off;
        widget.onScrollOffsetChanged?.call(off);
      }
    }

    // 2️⃣ 一轮开始：重置标记
    if (notification is ScrollStartNotification) {
      _dragFromTop = false;
      _currentOverscroll = 0.0;
      _releaseOverscroll = 0.0;
    }

    // 3️⃣ 滚动过程
    if (notification is ScrollUpdateNotification) {
      final pixels = metrics.pixels;
      final bool isUserDrag = notification.dragDetails != null;

      if (isUserDrag) {
        // 👆 手指真实拖动
        if (pixels < 0.0) {
          // 顶部下拉
          _dragFromTop = true;
          _currentOverscroll = -pixels; // 当前下拉距离（正数）

          final dragForScale =
          _currentOverscroll.clamp(0.0, _dismissDragDistance);

          setState(() {
            _translateY = _currentOverscroll;
            final t = (dragForScale / _dismissDragDistance).clamp(0.0, 1.0);
            _scale = 1.0 - _maxScaleDelta * t;
          });
        } else {
          // 离开 overscroll 区域
          if (_dragFromTop) {
            _dragFromTop = false;
          }
          _resetTransform();
        }
      } else {
        // 👇 这里是“手指已经松开后”的惯性 / 回弹阶段
        if (_dragFromTop && _releaseOverscroll == 0.0 && pixels < 0.0) {
          // 第一帧惯性更新，仍然在 overscroll 里：
          // 认为这是“松手那一刻”的 overscroll
          _releaseOverscroll = _currentOverscroll;

          if (_releaseOverscroll >= _dismissDragDistance) {
            // ✅ 松手那一下已经超过阈值：立刻走关闭动画，不再看回弹
            _startCloseAnimation();
          } else {
            // ❌ 不够阈值：回弹复位
            _resetTransform();
          }
        } else if (pixels >= 0.0) {
          // 已经回到正常区域：确保复位
          _resetTransform();
        }
      }
    }

    // 4️⃣ 一轮完全结束（惯性也停了）
    if (notification is ScrollEndNotification) {
      _dragFromTop = false;
      _currentOverscroll = 0.0;
      _releaseOverscroll = 0.0;
      if (!_isClosing) {
        _resetTransform();
      }
    }

    return false; // 不拦截默认滚动
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScroll,
      child: Transform.translate(
        offset: Offset(0, _translateY),
        child: Transform.scale(
          scale: _scale,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              // 上面：可滚内容
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: widget.bodyBuilder(
                    context,
                    _scrollController,
                    _scrollOffset,
                  ),
                ),
              ),
              // 下面：bottomBar（跟着整体 transform 走）
              widget.bottomBar,
            ],
          ),
        ),
      ),
    );
  }
}