import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/product_item.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:visibility_detector/visibility_detector.dart';

class Ending extends StatelessWidget {
  final List<ProductListItem>? list;
  final String title;

  const Ending({super.key, required this.list, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: context.textPrimary900,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 366.h,
          child: ListView.separated(
            key: PageStorageKey('ending_list_$title'),
            clipBehavior: Clip.none,
            padding: EdgeInsets.only(left: 16.w, top: 12.h, right: 16.w),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: list!.length,
            cacheExtent: 500,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final item = list![index];
              return HorizontalAnimatedItem(
                uniqueKey: item.treasureId, // 确保有唯一ID
                index: index,
                // 确保 ProductItem 内部不要再包 GestureDetector 了，否则手势可能冲突
                // 如果需要点击，建议包在这里，或者 ProductItem 内部处理
                child: ProductItem(data: item),
              );
            },
          ),
        ),
      ],
    );
  }
}


/// ---------------------------------------------------------
/// 横向动画列表项 (3D 翻转进场版 - 旗舰级效果)
/// ---------------------------------------------------------
class HorizontalAnimatedItem extends StatefulWidget {
  final Widget child;
  final String uniqueKey;
  final int index;

  const HorizontalAnimatedItem({
    super.key,
    required this.child,
    required this.index,
    required this.uniqueKey,
  });

  @override
  State<HorizontalAnimatedItem> createState() => _HorizontalAnimatedItemState();
}

class _HorizontalAnimatedItemState extends State<HorizontalAnimatedItem>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {

  late final AnimationController _controller;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // 稍微慢一点点，让翻转看清楚
    );

    //  Index 0 必须同步启动
    if (widget.index == 0) {
      _startAnimation(isFast: false, forceSync: true);
    }
  }

  void _startAnimation({required bool isFast, bool forceSync = false}) {
    if (_hasStarted) return;
    _hasStarted = true;

    if (isFast) {
      _controller.value = 1.0;
    } else {
      // 🌊 瀑布流：横向列表延迟稍微短一点，更紧凑
      final delayMs = 40 * (widget.index % 4);

      if (delayMs == 0 || forceSync) {
        _controller.forward();
      } else {
        Future.delayed(Duration(milliseconds: delayMs), () {
          if (mounted) _controller.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return VisibilityDetector(
      key: Key('ending_item_${widget.uniqueKey}_${widget.index}'),
      onVisibilityChanged: (info) {
        if (_hasStarted) return;

        if (info.visibleFraction > 0.01) {
          // 横向首屏判定
          bool isFirstScreen = widget.index < 4;
          // 横向滑动容易产生快滑，保留快滑检测
          bool isFast = !isFirstScreen && (info.visibleFraction > 0.5 || info.visibleFraction == 1.0);

          _startAnimation(isFast: isFast);
        }
      },
      child: _buildAnimatedContent(),
    );
  }

  Widget _buildAnimatedContent() {
    return widget.child
        .animate(
      controller: _controller,
      autoPlay: false,
    )
        .fadeIn(
      duration: 400.ms,
      curve: Curves.easeOut,
    )
    // 核心动画更换：3D 翻转
    // 效果：卡片像门一样打开，或者像翻牌一样展示
        .flipH(
      begin: -0.3, // -0.3 弧度，大概 15度左右，微微向后倾斜
      end: 0,      // 0 是正对屏幕
      duration: 500.ms,
      curve: Curves.easeOutBack, // 带一点点回弹，显得很有灵性
      alignment: Alignment.center, // 以中心为轴旋转
    )
    // 配合轻微的缩放，增强 3D 纵深感
        .scale(
      begin: const Offset(0.9, 0.9),
      end: const Offset(1, 1),
      duration: 500.ms,
      curve: Curves.easeOut,
    );
  }
}