import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Tab bar with underline indicator
/// support auto scroll into view when tab is active
/// support skeleton loading before data loaded
/// [data] list of tab items
/// [activeItem] current active tab item
/// [renderItem] function to render tab item
/// [onChangeActive] function to change active tab item
/// [autoScrollIntoView] whether auto scroll active tab into view, default true
/// [height] height of tab bar, default 44
/// [tabCount] number of tabs to show in skeleton loading, default 4
/// example:
/// ```dart
/// Tabs<String>(
///  data: ["All", "Hot", "Tech", "Home", "Cash",
///  "Other"],
///  activeItem: active,
///  renderItem: (item)=>Center(
///  child: Text(item),
///  ),
///  onChangeActive: (item)=>{
///  setState(() {
///  active = item;
///  })
///  }
///  )
///  ```

class Tabs<T> extends StatefulWidget {
  final List<T> data;  /// list of tab items
  final T activeItem;  /// current active tab item
  final Widget Function(T item) renderItem; /// function to render tab item
  final void Function(T v) onChangeActive;  /// function to change active tab item
  final bool autoScrollIntoView; /// whether auto scroll active tab into view
  final double height; /// height of tab bar
  final int tabCount; /// number of tabs to show in skeleton loading

  const Tabs({
    super.key,
    required this.data,
    required this.activeItem,
    required this.renderItem,
    required this.onChangeActive,
    this.autoScrollIntoView = true,
    this.height = 44,
    this.tabCount = 4,
  });

  @override
  State<Tabs> createState() => _TabsState<T>();
}

/// state of Tabs
/// manage indicator position and width
/// manage scroll controller
/// manage keys for each tab item
/// and update indicator position and width when data changed or scroll
/// or active item changed
/// also handle skeleton loading when data is empty
class _TabsState<T> extends State<Tabs<T>> {
  final _tabsKey = <GlobalKey>[]; /// keys for each tab item
  double _indicatorLeft = 0; /// left position of indicator
  double _indicatorWidth = 0; /// width of indicator
  bool pressed = false; /// whether tab item is pressed

  late ScrollController _scrollController;

  /// dispose scroll controller
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// after first frame rendered, need to update indicator position and width
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
    ..addListener((){
      /// when scroll, need to update indicator position
      _updateIndicator();
    });
    _tabsKey.addAll(List.generate(widget.data.length, (_) => GlobalKey()));
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateIndicator());
  }

  /// when data changed, need to update keys
  /// and update indicator position and width
  @override
  void didUpdateWidget(covariant Tabs<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    /// if data length changed, need to update keys
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateIndicator());
  }

  /// update indicator position and width
  void _updateIndicator({bool scrollToView = false}) {
    final index = findIndex<T>(widget.data, widget.activeItem );
    if (index < 0 || index >= _tabsKey.length) return;

    /// get render box of active tab item
    final renderBox =
        _tabsKey[index].currentContext?.findRenderObject() as RenderBox?;
    /// get render box of parent (ListView)
    final parentBox = context.findRenderObject() as RenderBox?;


    if (renderBox != null && parentBox != null) {
      /// get position of active tab item relative to parent
      final position = renderBox.localToGlobal(
        Offset.zero,
        ancestor: parentBox,
      );
      setState(() {
        _indicatorLeft = position.dx;
        _indicatorWidth = renderBox.size.width;
      });

      /// auto scroll active tab into view
      /// only when scrollToView is true (after tap)
      /// and autoScrollIntoView is true
      /// and scroll controller has clients
      /// and only scroll when tab is not fully visible
      /// (e.g. tab is partially visible or not visible)
      if(scrollToView && widget.autoScrollIntoView && _scrollController.hasClients) {
        final screenWidth = parentBox.size.width;
        final tabEndInViewport = position.dx + renderBox.size.width;
        final buffer = 16.w;

        /// if tab is fully visible, do nothing
        /// if tab is partially visible or not visible, scroll to center it
        double target = _scrollController.offset;
        target = tabEndInViewport - screenWidth/2 + buffer; // 16 padding

        final max = _scrollController.position.maxScrollExtent;
        final min = _scrollController.position.minScrollExtent;

        // ensure target is within scroll range
        target = target.clamp(min, max);

        if((target - _scrollController.offset).abs() > 0.5){
          _scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    /// skeleton loading before data loaded
    if (widget.data.isNullOrEmpty) {
      return SizedBox(
        height: widget.height.h,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.tabCount, (_) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 12.h),
              child: Skeleton.react(
                width: 60.w,
                height: widget.height.h,
                borderRadius: BorderRadius.circular(context.radiusSm),
              ),
            );
          }),
        ),
      );
    }

    final activeIndex = findIndex<T>(widget.data, widget.activeItem );

    /// auto scroll active tab into view
    return SizedBox(
      height: widget.height.w,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          /// underline/current highline Box for active tab
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            left: _indicatorLeft,
            bottom: 0,
            width: _indicatorWidth,
            height: widget.height.w,
            child: Container(
              decoration: BoxDecoration(
                color: context.bgBrandSolid,
                borderRadius: BorderRadius.all(Radius.circular(8.r)),
              ),
            ),
          ),

          /// tabs
          ListView.separated(
            controller: _scrollController,
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.only(left: 16.w, right: 16.w),
            scrollDirection: Axis.horizontal,
            itemCount: widget.data.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (_, index) {
              final item = widget.data[index];
              final isActive = index == activeIndex;
              return _TabBarItem<T>(
                index: index,
                isActive: isActive,
                item: item,
                renderItem: widget.renderItem,
                onChangeActive: widget.onChangeActive,
                tabsKey: _tabsKey,
                height: widget.height,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Individual tab item with press animation
class _TabBarItem<T> extends StatefulWidget {
  final int index;
  final T item;
  final bool isActive;
  final Widget Function(T item) renderItem;
  final void Function(T item) onChangeActive;
  final List<GlobalKey> _tabsKey;
  final double? height;

  const _TabBarItem({
    required this.index,
    required this.item,
    required this.isActive,
    required this.renderItem,
    required this.onChangeActive,
    required List<GlobalKey> tabsKey,
    this.height,
  }) : _tabsKey = tabsKey;

  @override
  _TabBarItemState<T> createState() => _TabBarItemState<T>();
}

/// Individual tab item with press animation
/// avoid effect to other tabs when one tab is pressed
/// so use StatefulWidget here
class _TabBarItemState<T> extends State<_TabBarItem<T>> {
  bool pressed = false;

  @override
  build(BuildContext context) {
    return GestureDetector(
      key: widget._tabsKey[widget.index],
      onTap: (){
        widget.onChangeActive(widget.item);
        WidgetsBinding.instance.addPostFrameCallback((_){
          final state = context.findAncestorStateOfType<_TabsState<T>>();
          state?._updateIndicator(scrollToView: true);
        });
      },
      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) => setState(() => pressed = false),
      onTapCancel: () => setState(() => pressed = false),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        height: widget.height!.h,
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 14.w,
            fontWeight: FontWeight.w500,
            color: widget.isActive
                ? context.textPrimaryOnBrand
                : context.textQuaternary500,
          ),
          child: AnimatedScale(
            scale: pressed ? 0.7 : 1.0,
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            child: widget.renderItem(widget.item),
          ),
        ),
      ),
    );
  }
}
