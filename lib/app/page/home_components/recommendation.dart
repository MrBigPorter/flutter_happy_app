import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/product_item.dart';
import 'package:flutter_app/core/models/index.dart';

import '../../routes/app_router.dart';

/// Recommendation Section (Dual-column Grid Layout)
/// Optimized: Removed VisibilityDetector, leveraging GridView's native lazy-loading
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

          // Section Title
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: context.textPrimary900,
            ),
          ),
          SizedBox(height: 15.h),

          // Product Grid
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            // Disable GridView's own scrolling since it's inside a CustomScrollView
            physics: const NeverScrollableScrollPhysics(),
            //  Performance Tip: Enable repaint boundaries to isolate cell rendering
            addRepaintBoundaries: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 12.h,
              // Aspect ratio fine-tuned based on ProductItem height to prevent overflow
              childAspectRatio: 165.w / 380.h,
            ),
            itemCount: list!.length,
            itemBuilder: (context, index) {
              final item = list![index];

              //  Core Optimization: Staggered animation delay using modulo (%)
              // Since it's a 2-column grid, (index % 2) creates a nice 0ms / 50ms alternating delay
              final animationDelay = ((index % 2) * 50).ms;

              return ProductCard(item: item)
                  .animate(delay: animationDelay) // Trigger animation instantly upon cell build
                  .fadeIn(duration: 450.ms, curve: Curves.easeOut)
                  .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1), curve: Curves.easeOutBack)
                  .slideY(begin: 0.08, end: 0, duration: 500.ms, curve: Curves.easeOutQuart);
            },
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

/// Individual Product Card Widget
class ProductCard extends StatelessWidget {
  final ProductListItem item;

  const ProductCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => appRouter.push('/product/${item.treasureId}'),
      // ProductItem internally handles its own countdown via ValueNotifier
      // avoiding entire grid re-renders
      child: ProductItem(
        data: item,
        imgWidth: 165,
        imgHeight: 165,
      ),
    );
  }
}