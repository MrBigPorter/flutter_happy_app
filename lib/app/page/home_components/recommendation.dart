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
    // 1. 安全拦截
    if (list == null || list!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 22.h),

          /// 标题
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: context.textPrimary900,
            ),
          ),
          SizedBox(height: 15.h),

          /// 2. Grid 列表
          // 使用 addRepaintBoundaries: false 可以在复杂列表中稍微提升性能，
          GridView.builder(
            padding: EdgeInsets.zero,
            // 移除内边距，完全由外层控制
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.w, // 建议减小一点间距，30w 可能太大了，看起来散
              childAspectRatio: 165.w / 380.h,
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

          // 底部留白，防止到底太局促
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

/// 商品卡片封装
class ProductCard extends StatelessWidget {
  final ProductListItem item;

  const ProductCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // 3. 点击事件统一处理
    return GestureDetector(
      onTap: () {
        appRouter.push('/product/${item.treasureId}');
      },
      child: ProductItem(data: item, imgWidth: 165, imgHeight: 165),
    );
  }
}

/// ---------------------------------------------------------
/// Grid 动画单元 (针对双列布局调优)
/// ---------------------------------------------------------
class GridAnimatedItem extends StatefulWidget {
  final Widget child;
  final String uniqueKey;
  final int index;

  const GridAnimatedItem({
    super.key,
    required this.child,
    required this.index,
    required this.uniqueKey,
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
      duration: const Duration(milliseconds: 500), // Grid 动画可以稍微慢一点点，更优雅
    );

    //  Grid 首屏保护策略：
    // Grid 一屏通常有 6-8 个。为了防止打开页面时下面几个也白屏，
    // 我们把前 4 个 (两行) 设为同步启动。
    if (widget.index < 4) {
      _startAnimation(isFast: false, forceSync: true);
    }
  }

  void _startAnimation({required bool isFast, bool forceSync = false}) {
    if (_hasStarted) return;
    _hasStarted = true;

    if (isFast) {
      _controller.value = 1.0;
    } else {
      //  Grid 瀑布流逻辑：
      // 我们希望左边先动，右边紧接着动，而不是一行一行整齐划一。
      // (index % 10) 让循环周期变长，动效更自然。
      final delayMs = 40 * (widget.index % 10);

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
      //  Key 必须唯一
      key: Key('rec_grid_${widget.uniqueKey}_${widget.index}'),
      onVisibilityChanged: (info) {
        if (_hasStarted) return;

        if (info.visibleFraction > 0.01) {
          // Grid 密度大，前 6 个都算首屏
          bool isFirstScreen = widget.index < 6;

          // Grid 很难瞬间露出 100%，所以只要露出一半以上就算快滑
          bool isFast = !isFirstScreen && (info.visibleFraction > 0.5);

          _startAnimation(isFast: isFast);
        }
      },
      child: _buildAnimatedContent(),
    );
  }

  Widget _buildAnimatedContent() {
    return widget.child
        .animate(controller: _controller, autoPlay: false)
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        //  动画方向：Grid 适合轻微的上浮 (SlideUp)
        // 也可以尝试 scale(begin: 0.95) 配合 fade，做成"浮出水面"的感觉
        .slideY(
          begin: 0.1, // 10% 的高度位移
          end: 0,
          duration: 400.ms,
          curve: Curves.easeOutQuart, // Quart 曲线更柔和
        );
  }
}
