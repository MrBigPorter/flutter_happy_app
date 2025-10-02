import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 首页精选骨架屏 Home Featured Skeleton
class FeaturedSkeleton extends StatelessWidget {
  const FeaturedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 4.h,
        crossAxisSpacing: 2.w,
        childAspectRatio: 157/344.w,
      ),
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.bgPrimary,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            children: [
              Skeleton.react(
                width: double.infinity,
                height: 157.h,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.r),
                  topRight: Radius.circular(8.r),
                ),
              ),
              SizedBox(height: 8.w),
              Skeleton.react(
                width: 140.w,
                height: 20.w,
                borderRadius: BorderRadius.circular(0),
              ),
              SizedBox(height: 4.w),
              Skeleton.react(
                width: 140.w,
                height: 20.w,
                borderRadius: BorderRadius.circular(0),
              ),
              SizedBox(height: 8.w),
              Skeleton.react(
                width: 53.w,
                height: 22.w,
                borderRadius: BorderRadius.circular(4.r),
              ),
              SizedBox(height: 8),
              Skeleton.react(width: 140.w, height: 4.w),
              SizedBox(height: 10.w),
              Skeleton.react(width: 100.w, height: 20.w),
              SizedBox(height: 20.w),
              Skeleton.react(width: 120.w, height: 49.w),
            ],
          ),
        );
      },
    );
  }
}
