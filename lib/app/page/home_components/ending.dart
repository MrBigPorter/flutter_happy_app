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
    if (list == null || list!.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: context.textPrimary900,
            ),
          ),
        ),
        SizedBox(
          // 根据 ProductItem 的实际高度微调，确保不溢出
          height: 380.h,
          child: ListView.separated(
            key: PageStorageKey('ending_list_$title'),
            clipBehavior: Clip.none,
            padding: EdgeInsets.only(left: 16.w, top: 12.h, right: 16.w),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: list!.length,
            // ✨ 性能优化：禁用默认重绘边界，由 HorizontalAnimatedItem 内部按需控制
            addRepaintBoundaries: false,
            cacheExtent: 800.w, // 预加载两三个卡片的宽度，滑动更丝滑
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final item = list![index];
              return HorizontalAnimatedItem(
                uniqueKey: item.treasureId,
                index: index,
                child: ProductItem(data: item),
              );
            },
          ),
        ),
      ],
    );
  }
}

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
      duration: const Duration(milliseconds: 450),
    );

    // 前两个元素直接启动动画，避免白屏感
    if (widget.index < 2) {
      _startAnimation(isFast: false, forceSync: true);
    }
  }

  void _startAnimation({required bool isFast, bool forceSync = false}) {
    if (_hasStarted) return;
    _hasStarted = true;

    if (isFast) {
      _controller.value = 1.0;
    } else {
      // 横向排列延迟减小，让进场序列感更紧凑
      final delayMs = 30 * (widget.index % 5);
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
        // 横向露出 5% 就开始动画
        if (info.visibleFraction > 0.05) {
          _startAnimation(isFast: info.visibleFraction > 0.8);
        }
      },
      // ✨ 性能优化：动画执行期间独立 Layer
      child: RepaintBoundary(
        child: widget.child
            .animate(controller: _controller, autoPlay: false)
            .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        // 3D 翻转优化：begin 改为 -0.15 (约8度)，角度太大会导致透视变形看起来很假
            .flipH(
          begin: -0.15,
          end: 0,
          duration: 450.ms,
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
        )
            .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 450.ms,
          curve: Curves.easeOut,
        ),
      ),
    );
  }
}