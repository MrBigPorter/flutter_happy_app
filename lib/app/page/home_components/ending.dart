import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math; // 引入 math 库用于限制高度

import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/product_item.dart';
import 'package:flutter_app/core/models/index.dart';

/// Ending Section (Horizontal Scrolling List)
/// Optimized: Utilizes pure numeric AspectRatio + Max Height constraints
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
        // 🚀 优化 1：不用 SizedBox，改用 Container + BoxConstraints
        Container(
          constraints: BoxConstraints(
            // 高度使用 380.h，但最高绝对不允许超过 420 像素！
            // 这样既在手机上保持了比例，又保证了在 iPad 上卡片不会变得像砖头一样大
            maxHeight: math.min(380.h, 420.0),
          ),
          child: ListView.separated(
            key: PageStorageKey('ending_list_$title'),
            clipBehavior: Clip.none,
            padding: EdgeInsets.only(left: 16.w, top: 12.h, right: 16.w),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: list!.length,
            cacheExtent: 800.w,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final item = list![index];
              final animationDelay = ((index % 5) * 30).ms;

              return AspectRatio(
                aspectRatio: 165 / 380,
                child: ProductItem(
                  data: item,
                  // 🚀 优化 2：删除了无用的 imgWidth 和 imgHeight
                  // 因为现在的 ProductItem 是遇方则方，无需外部指手画脚
                ),
              )
                  .animate(delay: animationDelay)
                  .fadeIn(duration: 400.ms, curve: Curves.easeOut)
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