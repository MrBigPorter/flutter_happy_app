import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../components/skeleton.dart';
import '../../../theme/design_tokens.g.dart';

/// home banner loading skeleton
class HomeBannerSkeleton extends StatelessWidget {
  const HomeBannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w,vertical: 16.h),
        child: Skeleton.react(width: double.infinity, height: 356),
      ),
    );
  }
}

/// home treasures loading skeleton
class HomeTreasureSkeleton extends StatelessWidget {
  const HomeTreasureSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          children: [
            SpecialAreaSkeleton(),
            SizedBox(height: 16.h),
            EndingSkeleton(),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}

class EndingSkeleton extends StatelessWidget {
  const EndingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Skeleton.react(
            width: 120.w,
            height: 20.h,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        SizedBox(
          height: 380.h,
          child: ListView.separated(
            padding: EdgeInsets.only(left: 16.w, top: 12.h, right: 16.w),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              return Skeleton.react(
                width: 140.w,
                height: 350.h,
                borderRadius: BorderRadius.circular(8.r),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SpecialAreaSkeleton extends StatelessWidget {

  const SpecialAreaSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Skeleton.react(
            width: 120.w,
            height: 20.h,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: List.generate(3, (index) {
              BorderRadius borderRadius = BorderRadius.zero;
              if (index == 0) {
                borderRadius = BorderRadius.only(
                  topLeft: Radius.circular(8.r),
                  topRight: Radius.circular(8.r),
                );
              } else if (index == 2) {
                borderRadius = BorderRadius.only(
                  bottomLeft: Radius.circular(8.r),
                  bottomRight: Radius.circular(8.r),
                );
              }
              return Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(left: 12.w, right: 12.w, top: 12.h),
                    decoration: BoxDecoration(
                      color: context.bgPrimary,
                      borderRadius: borderRadius,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Skeleton.react(
                              width: 80.w,
                              height: 80.w,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Skeleton.react(
                                    width: double.infinity,
                                    height: 16.h,
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  SizedBox(height: 8.h),
                                  Skeleton.react(
                                    width: double.infinity,
                                    height: 12.h,
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            Skeleton.react(
                              width: 60.w,
                              height: 14.h,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            Spacer(),
                            Skeleton.react(
                              width: 60.w,
                              height: 14.h,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            Spacer(),
                            Skeleton.react(
                              width: 80.w,
                              height: 36.h,
                              borderRadius: BorderRadius.circular(18.r),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  if (index < 2)
                    Divider(height: 1.h, color: context.borderSecondary),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
