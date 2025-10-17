import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 可用于 SliverPersistentHeader 的 TabBar 委托
/// 可以实现滚动时吸顶效果 tab bar delegate for SliverPersistentHeader
/// ✅ 支持自定义指示器 custom indicator support
/// ✅ 支持自定义渲染 tab item support
/// ✅ 支持自定义颜色 custom colors support
/// ✅ 支持自定义高度 custom height support
/// ✅ 支持自定义圆角 custom radius support
/// ✅ 支持自定义最小宽度 custom min width support
/// ✅ 支持自定义内边距 custom padding support
/// ✅ 支持自定义文字样式 custom text style support
/// ✅ 支持自定义背景色 custom background color support

class LuckySliverTabBarDelegate<T> extends SliverPersistentHeaderDelegate {
  final TabController? controller; // tab 控制器 tab controller
  final List<T> tabs; // tab 数据 tab data
  final Color? indicatorColor; // 指示器颜色 indicator color
  final Color? backgroundColor; // 背景颜色 background color
  final EdgeInsetsGeometry padding; // 外边距 outer padding
  final Widget Function(T item) renderItem; // 渲染 tab item render tab item
  final double height; /// tab 高度 tab height
  final double radius; /// 指示器圆角 indicator radius
  final double minWidth; /// 指示器最小宽度 indicator min width
  final double itemPaddingX; /// 指示器宽度扩展 padding indicator width padding
  final EdgeInsetsGeometry labelPadding; // tab item 内边距 tab item padding
  final TextStyle? labelStyle; // 选中 tab 文字样式 selected tab text style
  final TextStyle? unselectedLabelStyle; // 未选中 tab 文字样式 unselected tab text style
  final void Function(T item)? onTap; // tab 点击事件 tab tap event

  LuckySliverTabBarDelegate({
    required this.controller,
    required this.tabs,
    this.indicatorColor,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 0.0),
    this.labelPadding = const EdgeInsets.symmetric(horizontal: 20),
    this.height = 40,
    this.radius = 8,
    this.minWidth = 50,
    this.itemPaddingX = 10,
    this.labelStyle,
    this.unselectedLabelStyle,
    this.onTap,
    required this.renderItem,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {

    if(controller == null){
      return SizedBox.shrink();
    }

    return Container(
      color: backgroundColor,
      padding: EdgeInsets.symmetric(horizontal: 8.w).add(padding),
      alignment: Alignment.centerLeft,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelPadding: labelPadding,
        labelStyle: labelStyle??TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14.w,
            color: context.textPrimaryOnBrand
        ),
        indicatorSize: TabBarIndicatorSize.label,
        unselectedLabelStyle: unselectedLabelStyle ?? TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14.w,
          color: context.textQuaternary500
        ),
        indicator: _LuckyIndicator(
          color: indicatorColor??context.bgBrandSolid,
          controller: controller!,
          height: height,
          radius: radius,
          minWidth: minWidth,
          itemPaddingX: itemPaddingX,
        ),
        dividerColor: Colors.transparent,
        tabAlignment: TabAlignment.start,
        splashFactory: NoSplash.splashFactory,
        splashBorderRadius: BorderRadius.circular(0),
        /// 禁用水波纹效果 disable ripple effect
        enableFeedback: false,
        onTap: (index) {
          if (onTap != null) {
            onTap!(tabs[index]);
          }
        },
        tabs: tabs.map((item) {
          return renderItem(item);
        }).toList(),
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant LuckySliverTabBarDelegate oldDelegate) {
    return false;
  }
}

/// 自定义指示器 custom indicator
class _LuckyIndicator extends Decoration {
  final Color color;
  final TabController controller;
  final double height;
  final double radius;
  final double minWidth;
  final double itemPaddingX;

  const _LuckyIndicator({
    required this.color,
    required this.controller,
    required this.height,
    required this.radius,
    required this.minWidth,
    required this.itemPaddingX,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? coChange]) {
    return _LuckyIndicatorPainter(
      color: color,
      controller: controller,
      height: height,
      radius: radius,
      minWidth: minWidth,
      itemPaddingX: itemPaddingX,
    );
  }
}

/// 自定义指示器绘制 custom indicator painter
class _LuckyIndicatorPainter extends BoxPainter {
  final Color color;
  final TabController controller;
  final double height;
  final double radius;
  final double minWidth;
  final double itemPaddingX;

  _LuckyIndicatorPainter({
    required this.color,
    required this.controller,
    required this.height,
    required this.radius,
    required this.minWidth,
    required this.itemPaddingX,
  });

  // 缓存
  int? _from, _to;

  //新值
  double? _fromW, _toW;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    /// ✅ 计算当前 Tab 的位置与宽度 current tab position & width
    final rect = offset & configuration.size!;
    final radius = Radius.circular(this.radius.w);

    /// ✅ 绘制圆角方块 draw rounded rectangle
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    /// ✅ 计算动画进度 calculate animation progress
    final value = controller.animation?.value ?? controller.index.toDouble();
    final from = value.floor();
    final progress = value % 1; // 0.0 ~ 1.0
    final to = (value.round()).clamp(0, controller.length - 1);

    /// ✅ 计算宽度 calculate width
    if (_from != from || _to != to) {
      _from = from;
      _to = to;
      _fromW = null;
      _toW = null;
    }

    /// ✅ 计算宽度 calculate width (仅计算一次 only calculate once)
    if (progress < 0.05) {
      _fromW = rect.width;
    }
    if (progress > 0.95) {
      _toW = rect.width;
    }

    /// ✅ 计算宽度 calculate width
    final baseW = (progress <= 0.5)
        ? (_fromW ?? rect.width)
        : (_toW ?? rect.width);
    final pillW = (baseW + itemPaddingX).clamp(minWidth, double.infinity);

    // ✅ 以中心为基准生成圆角方块 draw rounded rectangle centered
    final RRect rrect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: rect.center, width: pillW.w, height: height),
      topLeft: radius.w,
      topRight: radius.w,
      bottomLeft: radius.w,
      bottomRight: radius.w,
    );

    canvas.drawRRect(rrect, paint);
  }
}
