import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/components/skeleton.dart';

import '../../../theme/design_tokens.g.dart';

class ProductDetailSkeleton extends StatelessWidget {
  const ProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const BannerSectionSkeleton(),
            const CouponSectionSkeleton(),
            const TopTreasureSectionSkeleton(),
            const GroupSectionSkeleton(),
            SizedBox(height: 20.h),
            const DetailSectionSkeleton(),
          ],
        ),
      ),
    );
  }
}

class BannerSectionSkeleton extends StatelessWidget {
  const BannerSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeleton.react(
      width: double.infinity,
      height: 250.h,
      borderRadius: BorderRadius.zero,
    );
  }
}

class CouponSectionSkeleton extends StatelessWidget {
  const CouponSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      child: SizedBox(
        height: 22.h,
        child: Row(
          children: List.generate(
            4,
            (index) => Container(
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              alignment: Alignment.center,
              child: Skeleton.react(
                width: 50.w,
                height: 22.h,
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TopTreasureSectionSkeleton extends StatelessWidget {
  const TopTreasureSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: context.bgPrimary,
          border: Border.all(color: context.borderPrimary),
          borderRadius: BorderRadius.circular(context.radiusMd),
        ),
        child: Column(
          children: [
            Skeleton.react(
              width: double.infinity,
              height: 20.h,
              borderRadius: BorderRadius.circular(4.r),
            ),
            SizedBox(height: 16.h),
            Skeleton.react(
              width: 120.w,
              height: 32.h,
              borderRadius: BorderRadius.circular(4.r),
            ),
            SizedBox(height: 16.h),
            Skeleton.react(
              width: double.infinity,
              height: 80.h,
              borderRadius: BorderRadius.circular(4.r),
            ),
            SizedBox(height: 16.h),
            Skeleton.react(
              width: double.infinity,
              height: 40.h,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ],
        ),
      ),
    );
  }
}


class GroupSectionSkeleton extends StatelessWidget {
  const GroupSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Container(
          decoration: BoxDecoration(
            color: context.bgPrimary,
            border: Border.all(color: context.borderPrimary),
            borderRadius: BorderRadius.circular(context.radiusMd),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(12.w),
                child: Skeleton.react(
                  width: 120.w,
                  height: 20.h,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              ...List.generate(
                3,
                    (_) => ListTile(
                  leading: Skeleton.circle(width: 40.w, height: 40.w),
                  title: Skeleton.react(
                    width: double.infinity,
                    height: 16.h,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  trailing: Skeleton.react(
                    width: 16.w,
                    height: 16.w,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
            ],
          ),
        )
    );
  }
}

class DetailSectionSkeleton extends StatelessWidget {
  const DetailSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          Skeleton.react(
            width: double.infinity,
            height: 40.h,
            borderRadius: BorderRadius.circular(8.r),
          ),
          SizedBox(height: 16.h),
          Skeleton.react(
            width: double.infinity,
            height: 200.h,
            borderRadius: BorderRadius.circular(8.r),
          ),
        ],
      ),
    );
  }
}
