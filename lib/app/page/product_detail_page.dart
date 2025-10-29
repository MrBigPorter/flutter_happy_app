import 'package:flutter/material.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key});
  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with TickerProviderStateMixin {
  // ====== 配置（可按需改）======
  static const double _maxHeightFactor = 0.90; // 高度占屏比
  static const double _radius = 16.0;          // 顶部圆角
  static const bool _clickBgToClose = true;    // 点击遮罩关闭
  static const bool _showClose = true;         // 右上角关闭按钮
  static const Duration _inDur = Duration(milliseconds: 280);
  static const Duration _outDur = Duration(milliseconds: 220);

  late final AnimationController _ctl;

  double _startY = 0, _startVal = 1;
  bool _draggingSheet = false; // 当前手势是否交给外层 Sheet
  bool _isAtTop = true;        // 内容是否滚到顶
  final ScrollController _scrollCtl = ScrollController();

  Future<void> _animateOpen() async {
    await _ctl.animateTo(1.0, duration: _inDur, curve: Curves.easeOutCubic);
  }

  Future<void> _animateClose() async {
    await _ctl.animateBack(0.0, duration: _outDur, curve: Curves.easeInCubic);
  }

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: 1,
      value: 0,
      duration: _inDur,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _animateOpen());

    _scrollCtl.addListener(() {
      final atTop = _scrollCtl.positions.isNotEmpty
          ? _scrollCtl.position.pixels <= 0.0
          : true;
      if (atTop != _isAtTop) setState(() => _isAtTop = atTop);
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final h = media.size.height;
    final sheetH = h * _maxHeightFactor;

    final barrierColor =
    Theme.of(context).colorScheme.scrim.withOpacity(0.45);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 遮罩
          AnimatedBuilder(
            animation: _ctl,
            builder: (_, __) => Opacity(
              opacity: _ctl.value.clamp(0.0, 1.0),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _clickBgToClose ? () async { await _animateClose(); if (mounted) Navigator.of(context).maybePop(); } : null,
                child: Container(color: barrierColor),
              ),
            ),
          ),

          // 面板
          AnimatedBuilder(
            animation: _ctl,
            builder: (_, child) {
              final dy = (1 - _ctl.value) * sheetH;
              return Transform.translate(offset: Offset(0, dy), child: child);
            },
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: double.infinity,
                height: sheetH, // 贴底满宽，内部再做 SafeArea
                child: Material(
                  color: surfaceColor,
                  elevation: 16,
                  shadowColor: Colors.black.withOpacity(0.25),
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(_radius)),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,

                    // 开始：只有在顶部才把手势交给外层
                    onVerticalDragStart: (d) {
                      _draggingSheet = _isAtTop;
                      if (_draggingSheet) {
                        _startY = d.globalPosition.dy;
                        _startVal = _ctl.value;
                      }
                    },

                    // 更新：向下拖时驱动外层；向上且内容能滚时还权给内部
                    onVerticalDragUpdate: (d) {
                      if (!_draggingSheet) return;
                      final dy = d.globalPosition.dy - _startY;

                      if (dy < 0 &&
                          _scrollCtl.hasClients &&
                          !_scrollCtl.position.atEdge) {
                        _draggingSheet = false;
                        setState(() {});
                        return;
                      }

                      final v = (_startVal - dy / sheetH).clamp(0.0, 1.0);
                      _ctl.value = v;
                    },

                    // 结束：判定关闭或复位
                    onVerticalDragEnd: (d) async {
                      if (_draggingSheet) {
                        final v = d.velocity.pixelsPerSecond.dy;
                        final shouldClose = v > 900 || _ctl.value < 0.6;
                        if (shouldClose) {
                          await _animateClose();
                          if (mounted) Navigator.of(context).maybePop();
                        } else {
                          await _ctl.forward();
                        }
                      }
                      _draggingSheet = false;
                    },

                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(_radius)),
                      child: SafeArea(
                        top: false, // 贴底，内部给底部安全区
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            final atTop = n.metrics.pixels <= 0;
                            if (atTop != _isAtTop) _isAtTop = atTop;

                            // 下拉越界时交给外层
                            final isPullingDown = n.metrics.pixels < 0;
                            if (isPullingDown && _isAtTop) {
                              _draggingSheet = true;
                              setState(() {});
                              return true;
                            }
                            return false;
                          },
                          child: Stack(
                            children: [
                              // 可滚内容
                              AbsorbPointer(
                                absorbing: _draggingSheet,
                                child: ListView.builder(
                                  controller: _scrollCtl,
                                  physics: _draggingSheet
                                      ? const NeverScrollableScrollPhysics()
                                      : const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 32, 16, 16 + 12), // 顶部留给抓手/关闭
                                  itemCount: 100,
                                  itemBuilder: (_, i) =>
                                      ListTile(title: Text('内容项 #$i')),
                                ),
                              ),

                              // 顶部抓手
                              Positioned(
                                top: 8,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    width: 48,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[400],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),

                              // 右上角关闭
                              if (_showClose)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, size: 22),
                                    onPressed: () async {
                                      await _animateClose();
                                      if (mounted) {
                                        Navigator.of(context).maybePop();
                                      }
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}