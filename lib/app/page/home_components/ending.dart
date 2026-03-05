import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/product_item.dart';
import 'package:flutter_app/core/models/index.dart';

/// Ending Section (Horizontal Scrolling List)
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
          height: 380.h,
          child: ListView.separated(
            key: PageStorageKey('ending_list_$title'),
            clipBehavior: Clip.none,
            padding: EdgeInsets.only(left: 16.w, top: 12.h, right: 16.w),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: list!.length,
            cacheExtent: 800.w,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final item = list![index];
              final animationDelay = ((index % 5) * 30).ms;

              //  核心修复：必须加上 AspectRatio！
              // 它把无底洞一样的水平列表宽度，强制约束成了与高度对应的有限数值！
              return AspectRatio(
                aspectRatio: 165 / 380,
                child: ProductItem(
                  data: item,
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