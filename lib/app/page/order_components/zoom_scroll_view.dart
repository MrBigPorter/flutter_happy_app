import 'package:flutter/material.dart';

typedef ScrollBodyBuilder = Widget Function(
    BuildContext context,
    ScrollController scrollController,
    double scrollOffset,
    );

/// ZoomScrollView
/// ------------------------------------------------------------------
/// - 内部：
///   - SingleChildScrollView（正常滚动）
///   - bottomBar（固定在底部）
/// - 对外表现为一张「卡片」：内容 + bottomBar 一起做 Transform（位移 + 缩放）
///
/// 行为：
/// - 列表不在顶部：正常滚动，和系统一样
/// - 列表在顶部 & 手指向下拖：进入「拖动关闭模式」
///     * 卡片整体跟着手指走（translateY + scale）
///     * 松手：
///         - 拖动距离 >= 阈值 → 短动画下沉 + 缩小 → onDismiss()
///         - 否则 → 短动画回弹到原位
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

enum _AnimType { none, rebound, dismiss }

class _ZoomScrollViewState extends State<ZoomScrollView>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  /// 提供给外部 Header 淡入用的 offset（只取 >= 0 部分）
  double _scrollOffset = 0.0;

  /// 当前整体位移 & 缩放
  double _translateY = 0.0;
  double _scale = 1.0;

  /// 拖动关闭模式下累计的 Y 位移
  double _dragOffset = 0.0;

  /// 当前是否正在「拖动关闭」
  bool _isDraggingToDismiss = false;

  /// 当前是否在做关闭 or 回弹动画
  bool _isAnimating = false;

  /// Pointer 跟踪（只跟一个手指）
  int? _activePointerId;
  double _lastPointerY = 0.0;

  /// 关闭阈值：拖动超过这么多就算要关
  static const double _dismissDragDistance = 120.0;

  /// 最多缩小 8%
  static const double _maxScaleDelta = 0.08;

  late final AnimationController _animController;
  late Animation<double> _animTranslate;
  late Animation<double> _animScale;

  _AnimType _animType = _AnimType.none;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollChanged);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    )
      ..addListener(() {
        setState(() {
          _translateY = _animTranslate.value;
          _scale = _animScale.value;
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (_animType == _AnimType.rebound) {
            // 回弹结束：彻底复位
            _dragOffset = 0.0;
            _translateY = 0.0;
            _scale = 1.0;
          } else if (_animType == _AnimType.dismiss) {
            // 关闭动画结束：通知外部关闭
            widget.onDismiss();
          }
          _animType = _AnimType.none;
          _isAnimating = false;
        }
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScrollChanged() {
    // 正在拖动关闭 / 动画中，不给 header 发 offset，避免抖动
    if (_isDraggingToDismiss || _isAnimating) return;

    final offset = _scrollController.offset;
    final effective = offset > 0 ? offset : 0.0;
    if (effective != _scrollOffset) {
      _scrollOffset = effective;
      widget.onScrollOffsetChanged?.call(effective);
    }
  }

  void _startReboundAnimation() {
    if (_isAnimating) return;
    _isAnimating = true;
    _animType = _AnimType.rebound;

    _animController.duration = const Duration(milliseconds: 160);

    _animTranslate = Tween<double>(
      begin: _translateY,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animScale = Tween<double>(
      begin: _scale,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward(from: 0.0);
  }

  void _startDismissAnimation() {
    if (_isAnimating) return;
    _isAnimating = true;
    _animType = _AnimType.dismiss;

    // 避免 ScrollView 自己再弹一段
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }

    _animController.duration = const Duration(milliseconds: 140);

    _animTranslate = Tween<double>(
      begin: _translateY,
      end: _translateY + 80.0,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInCubic,
      ),
    );

    _animScale = Tween<double>(
      begin: _scale,
      end: 0.85,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInCubic,
      ),
    );

    _animController.forward(from: 0.0);
  }

  /// 手指按下：记录 pointer，用来算后续的 dy
  void _onPointerDown(PointerDownEvent event) {
    if (_isAnimating) {
      _animController.stop();
      _animType = _AnimType.none;
      _isAnimating = false;
    }

    _activePointerId = event.pointer;
    _lastPointerY = event.position.dy;
    _isDraggingToDismiss = false;
    _dragOffset = 0.0;
  }

  /// 手指移动：如果滚到顶部且向下拖，就进入「拖动关闭模式」
  void _onPointerMove(PointerMoveEvent event) {
    if (_isAnimating || _activePointerId != event.pointer) return;

    final dy = event.position.dy - _lastPointerY;
    _lastPointerY = event.position.dy;

    // 如果还没进入「拖动关闭模式」，先看看是否满足条件：
    // 1. 向下拖动  2. 列表在顶部（offset <= 0.5）
    if (!_isDraggingToDismiss) {
      if (dy > 0 &&
          _scrollController.hasClients &&
          _scrollController.offset <= 0.5) {
        _isDraggingToDismiss = true;
        // 保证 ScrollView 不再往下 overscroll
        _scrollController.jumpTo(0.0);
      } else {
        // 不满足条件，交给 ScrollView 正常滚动
        return;
      }
    }

    // 已经在「拖动关闭模式」：卡片跟着手指走
    _dragOffset += dy;
    if (_dragOffset < 0) _dragOffset = 0;

    final dragForScale =
    _dragOffset.clamp(0.0, _dismissDragDistance); // 缩放不超过阈值
    final t = (dragForScale / _dismissDragDistance).clamp(0.0, 1.0);

    setState(() {
      _translateY = _dragOffset;
      _scale = 1.0 - _maxScaleDelta * t;
    });

    // 强制 ScrollView 一直保持在顶部，避免视觉上内容也在跟着滚
    if (_scrollController.hasClients &&
        _scrollController.offset != 0.0) {
      _scrollController.jumpTo(0.0);
    }
  }

  /// 手指抬起：根据拖动距离判断关闭 / 回弹
  void _onPointerUp(PointerUpEvent event) {
    if (_isAnimating || _activePointerId != event.pointer) {
      _activePointerId = null;
      return;
    }
    _activePointerId = null;

    if (!_isDraggingToDismiss) return;

    _isDraggingToDismiss = false;

    final bool shouldDismiss = _dragOffset >= _dismissDragDistance;

    if (shouldDismiss) {
      _startDismissAnimation();
    } else {
      _startReboundAnimation();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_activePointerId == event.pointer) {
      _activePointerId = null;
      if (_isDraggingToDismiss && !_isAnimating) {
        _isDraggingToDismiss = false;
        _startReboundAnimation();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: Transform.translate(
        offset: Offset(0, _translateY),
        child: Transform.scale(
          scale: _scale,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              // 上方：正常可滚内容
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
              // 下方：bottomBar，跟内容一起被 Transform
              widget.bottomBar,
            ],
          ),
        ),
      ),
    );
  }
}