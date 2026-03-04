import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/product_item.dart';
import 'package:flutter_app/core/models/index.dart';

/// Ending Section (Horizontal Scrolling List)
/// Optimized: Removed VisibilityDetector, utilizing ListView's native lazy-loading
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
        // Section Title
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

        // Horizontal List Container
        SizedBox(
          // Fine-tuned based on ProductItem's actual height to prevent overflow
          height: 380.h,
          child: ListView.separated(
            key: PageStorageKey('ending_list_$title'),
            clipBehavior: Clip.none,
            padding: EdgeInsets.only(left: 16.w, top: 12.h, right: 16.w),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: list!.length,
            // Performance Tip: Preload 2-3 cards ahead for smoother scrolling
            cacheExtent: 800.w,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final item = list![index];

              // Core Optimization: Staggered animation using modulo (%)
              // Delays will loop: 0ms, 30ms, 60ms, 90ms, 120ms... ensuring smooth entry
              final animationDelay = ((index % 5) * 30).ms;

              return ProductItem(data: item)
                  .animate(delay: animationDelay) // Trigger instantly upon lazy build
                  .fadeIn(duration: 400.ms, curve: Curves.easeOut)
              // Subtle 3D flip optimization (approx 8 degrees)
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
              );
            },
          ),
        ),
      ],
    );
  }
}