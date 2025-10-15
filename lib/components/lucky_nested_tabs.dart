import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/custom_cupertino_sliver_refresh_control.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sliver_tools/sliver_tools.dart';

class LuckyNestedTabs<T> extends ConsumerStatefulWidget {
  final List<T> tabs;
  final T? activeItem;
  final Widget Function(T item) renderItem;
  final void Function(T item) onChange;
  final List<Widget> children;
  final List<Widget>? renderBeforeTabs;
  final List<Widget>? renderAfterTabs;
  final Future<void> Function()? onRefresh;

  final double height;

  const LuckyNestedTabs({
    super.key,
    required this.tabs,
    required this.renderItem,
    required this.onChange,
    required this.children,
    this.activeItem,
    this.height = 60,
    this.renderAfterTabs,
    this.renderBeforeTabs,
    this.onRefresh,
  });

  @override
  ConsumerState<LuckyNestedTabs<T>> createState() => _LuckyNestedTabsState<T>();
}

class _LuckyNestedTabsState<T> extends ConsumerState<LuckyNestedTabs<T>>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  late List<GlobalKey> _tabKeys;
  final _barKey = GlobalKey();
  int _lastReportedIndex = -1;


  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabController = TabController(length: widget.tabs.length, vsync: this);

    _syncInitialIndex();

    _attachTabListener();

    _addTabKeys(widget.tabs);
  }

  void _attachTabListener() {
    _tabController.addListener(() {
      final anim = _tabController.animation?.value;
      if(anim == null) return;
      final i = anim.round().clamp(0, widget.tabs.length - 1);
      final settled = (anim - i).abs() < 1e-4;
      if (settled && i != _lastReportedIndex) {
        _lastReportedIndex = i;
        // 如果外部已经是同一个 item，也可以不回调（可选）
        if (widget.activeItem == null || widget.tabs[i] != widget.activeItem) {
          widget.onChange(widget.tabs[i]);
        }
      }
    });


  }

  void _syncInitialIndex() {
    if (widget.activeItem != null) {
      final index = widget.tabs.indexWhere((e) => e == widget.activeItem);
      if (index >= 0) _tabController.index = index;
    }
  }

  void _addTabKeys(List<T> list) {
    _tabKeys = List.generate(list.length, (index) => GlobalKey());
  }

  @override
  void didUpdateWidget(covariant LuckyNestedTabs<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabs.length != oldWidget.tabs.length) {
      _tabController.dispose();
      _tabController = TabController(length: widget.tabs.length, vsync: this);
      _syncInitialIndex();
      _attachTabListener();
      _addTabKeys(widget.tabs);
    } else if (widget.activeItem != oldWidget.activeItem) {
      final newIndex = widget.tabs.indexWhere((e) => e == widget.activeItem);
      if (newIndex >= 0 && newIndex != _tabController.index) {
        _tabController.animateTo(newIndex);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverOverlapAbsorber(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          sliver: MultiSliver(
            children: [
              if (widget.onRefresh != null)
                CustomCupertinoSliverRefreshControl(
                  onRefresh: widget.onRefresh!,
                ),
              if (widget.renderBeforeTabs != null)
                ...widget.renderBeforeTabs!.map(
                  (child) =>
                      child is SliverToBoxAdapter ||
                          child is SliverList ||
                          child is SliverGrid
                      ? child
                      : SliverToBoxAdapter(child: child),
                ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _LuckyTabsHeaderDelegate<T>(
                  tabKeys: _tabKeys,
                  barKey: _barKey,
                  tabs: widget.tabs,
                  activeItem: widget.activeItem,
                  renderItem: widget.renderItem,
                  onChange: (t) {
                    final index = widget.tabs.indexWhere((e) => e == t);
                    if (index >= 0) {
                      _tabController.animateTo(index);
                      widget.onChange(t);
                    }
                  },
                  height: widget.height,
                  controller: _tabController,
                ),
              ),
              if (widget.renderAfterTabs != null)
                ...widget.renderAfterTabs!.map(
                  (child) =>
                      child is SliverToBoxAdapter ||
                          child is SliverList ||
                          child is SliverGrid
                      ? child
                      : SliverToBoxAdapter(child: child),
                ),
            ],
          ),
        ),
      ],
      body:TabBarView(
        controller: _tabController,
        children: widget.children,
      ),
    );
  }
}


class _LuckyTabsHeaderDelegate<T> extends SliverPersistentHeaderDelegate {
  final List<T> tabs;
  final T? activeItem;
  final Widget Function(T item) renderItem;
  final void Function(T item) onChange;
  final double height;
  final TabController controller;
  final List<GlobalKey> tabKeys;
  final GlobalKey barKey;

  _LuckyTabsHeaderDelegate({
    required this.tabs,
    required this.renderItem,
    required this.onChange,
    this.activeItem,
    this.height = 60,
    required this.controller,
    required this.tabKeys,
    required this.barKey,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      child: SizedBox(
        height: maxExtent.w,
        child: TabBar(
          controller: controller,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          tabs: List.generate(tabs.length, (index) => renderItem(tabs[index])),
          indicator: SnapPillIndicator(
            controller: controller,
            color: context.fgBrandPrimary,
            height: 40.w,
            radius: 8.w,
            padX: 0,
            minWidth: 30.w,
            snapAt: 0.5,
          ),
          labelPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.w),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          labelStyle: TextStyle(
            fontSize: 16.w,
            fontWeight: FontWeight.w500,
            color: context.bgPrimary,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 14.w,
            fontWeight: FontWeight.w500,
            color: context.textQuaternary500,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          isScrollable: true,
          dividerColor: Colors.transparent,
          tabAlignment: TabAlignment.start,
          onTap: (i){
            controller.animateTo(i);
          },
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _LuckyTabsHeaderDelegate oldDelegate) {
    if (oldDelegate.tabs != tabs ||
        oldDelegate.height != height ||
        oldDelegate.controller != controller ||
        oldDelegate.activeItem != activeItem) {
      return true;
    }
    return false;
  }
}

/// SnapPillIndicator: A pill-shaped tab indicator that snaps width based on tab width
/// and animation progress.
/// Usage:
/// indicator: SnapPillIndicator(
///  controller: _tabController,
///  color: Colors.blue,
///  height: 28,
///  radius: 12,
///  padX: 12,
///  minWidth: 40,
///  snapAt: 0.5,
///  ),
///  Parameters:
///  - controller: TabController, required
///  - color: Color, required
///  - height: double, default 28
///  - radius: double, default 12
///  - padX: double, horizontal padding, default 12
///  - minWidth: double, minimum width, default 40
///  - snapAt: double, snap threshold (0~1), default 0.
///  When animation progress crosses this threshold, width snaps to target tab width.
class SnapPillIndicator extends Decoration {
  final TabController controller;
  final Color color;
  final double height;
  final double radius;
  final double padX; // 宽度 padding
  final double minWidth; // 最小宽 minWidth
  final double snapAt; // 宽度切换阈值 (0~1)

  const SnapPillIndicator({
    required this.controller,
    required this.color,
    this.height = 28,
    this.radius = 12,
    this.padX = 12,
    this.minWidth = 40,
    this.snapAt = 0.5,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _SnapPillPainter(this, onChanged);
}

class _SnapPillPainter extends BoxPainter {
  final SnapPillIndicator d;

  _SnapPillPainter(this.d, super.onChanged);

  int? _from, _to;
  double? _fromW, _toW;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    if (cfg.size == null) return;

    /// 当前 tab rect, 包含 padding, 不含 margin , 相对于 TabBar 左上角
    final rect = offset & cfg.size!;

    /// 当前动画进度  0~length-1
    final anim = d.controller.animation?.value ?? d.controller.index.toDouble();

    /// 计算 from/to tab 的宽度
    final from = anim.floor();

    /// 进度 0~1
    final t = (anim - from).clamp(0.0, 1.0);

    /// to 索引 0~length-1
    final to = (anim.round()).clamp(0, d.controller.length - 1);

    /// 取 from/to tab 的 rect
    if (_from != from || _to != to) {
      /// 索引变了，重置宽度缓存  index changed, reset width cache
      _from = from;
      _to = to;
      _fromW = null;
      _toW = null;
    }

    /// 取 from tab 宽度, get from tab width
    if (t < .05) _fromW = rect.width;
    if (t > .95) _toW = rect.width;

    // 宽度在中点瞬切，避免爬行；没拿到就用当前 rect 宽, width snaps at midpoint to avoid crawling; use current rect width if not available
    final baseW = (t < d.snapAt)
        ? (_fromW ?? rect.width)
        : (_toW ?? rect.width);
    final pillW = (baseW + d.padX * 2).clamp(d.minWidth, double.infinity);

    /// 计算胶囊位置 calculate pill position
    final pillRect = Rect.fromCenter(
      center: rect.center,
      width: pillW,
      height: d.height,
    );

    final paint = Paint()..color = d.color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, Radius.circular(d.radius)),
      paint,
    );
  }
}
