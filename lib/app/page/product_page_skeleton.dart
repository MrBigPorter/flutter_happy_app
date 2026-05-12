import 'package:flutter/material.dart';
import 'package:flutter_app/components/product_item.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Product page skeleton — shown while the product_page.dart chunk loads.
/// Matches the real ProductPage layout: category pills + product grid.
class ProductPageSkeleton extends StatelessWidget {
  const ProductPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category pills (simulated with skeleton tabs)
        SizedBox(
          height: 60.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
            itemCount: 4,
            separatorBuilder: (_, _) => SizedBox(width: 8.w),
            itemBuilder: (_, _) => Skeleton.react(
              width: 60.w,
              height: 30.h,
              borderRadius: BorderRadius.circular(8.h),
            ),
          ),
        ),
        // Product grid skeleton
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 22,
                crossAxisSpacing: 6,
                childAspectRatio: 166 / 365,
              ),
              itemCount: 10,
              itemBuilder: (_, _) =>
                  const RepaintBoundary(child: ProductItemSkeleton()),
            ),
          ),
        ),
      ],
    );
  }
}
