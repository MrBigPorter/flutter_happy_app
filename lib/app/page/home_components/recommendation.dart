import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/product_item.dart';
import 'package:flutter_app/core/models/index.dart';

import '../../routes/app_router.dart';

class Recommendation extends StatelessWidget {
  final List<ProductListItem>? list;
  final String title;

  const Recommendation({super.key, required this.list, required this.title});

  @override
  Widget build(BuildContext context) {
    if (list == null || list!.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 22.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: context.textPrimary900,
            ),
          ),
          SizedBox(height: 15.h),

          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // ✨ 性能优化：在 Grid 这种高密度场景，禁用 addRepaintBoundaries
            // 因为我们在 GridAnimatedItem 内部会手动根据动画状态添加，避免过度绘制。
            addRepaintBoundaries: false,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 165.w / 380.h, // ✨ 根据 ProductItem 实际高度微调，防止溢出
            ),
            itemCount: list!.length,
            itemBuilder: (context, index) {
              final item = list![index];
              return GridAnimatedItem(
                uniqueKey: item.treasureId,
                index: index,
                child: ProductCard(item: item),
              );
            },
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final ProductListItem item;
  const ProductCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => appRouter.push('/product/${item.treasureId}'),
      // ✨ 这里的 ProductItem 内部现在由于有了 RenderCountdown 的 ValueNotifier，
      // 它的倒计时跳动是局部刷新的，不会带动整个 GridAnimatedItem 刷新。
      child: ProductItem(data: item, imgWidth: 165, imgHeight: 165),
    );
  }
}

class GridAnimatedItem extends StatefulWidget {
  final Widget child;
  final String uniqueKey;
  final int index;

  const GridAnimatedItem({
    super.key,
    required this.index,
    required this.uniqueKey,
    required this.child,
  });

  @override
  State<GridAnimatedItem> createState() => _GridAnimatedItemState();
}

class _GridAnimatedItemState extends State<GridAnimatedItem>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // ✨ Grid 策略：前 6 个（三行）通常都在首屏可见范围内，直接同步加载
    if (widget.index < 6) {
      _startAnimation(isFast: false, forceSync: true);
    }
  }

  void _startAnimation({required bool isFast, bool forceSync = false}) {
    if (_hasStarted) return;
    _hasStarted = true;

    if (isFast) {
      _controller.value = 1.0;
    } else {
      // 交错动画：让左右两列稍微错开一点点，视觉上更灵动
      final delayMs = 60 * (widget.index % 6);
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
      key: Key('rec_grid_${widget.uniqueKey}_${widget.index}'),
      onVisibilityChanged: (info) {
        if (_hasStarted) return;
        if (info.visibleFraction > 0.1) {
          _startAnimation(isFast: info.visibleFraction > 0.8);
        }
      },
      // ✨ 性能优化：只有在执行动画期间，才会被包裹在 RepaintBoundary 中
      // 动画结束后，由于 _controller 状态固定，不再产生新的图层压力
      child: RepaintBoundary(
        child: widget.child
            .animate(controller: _controller, autoPlay: false)
            .fadeIn(duration: 450.ms, curve: Curves.easeOut)
            .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1), curve: Curves.easeOutBack)
            .slideY(begin: 0.08, end: 0, duration: 500.ms, curve: Curves.easeOutQuart),
      ),
    );
  }
}