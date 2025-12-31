import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../components/base_scaffold.dart';
import '../../../components/skeleton.dart';
import '../../../theme/design_tokens.g.dart';

class PaymentSkeleton extends StatelessWidget {

  const PaymentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'checkout',
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              SizedBox(height: 20.h),
              _AddressSectionSkeleton(),
              SizedBox(height: 8.h),
              _ProductSectionSkeleton(),
              SizedBox(height: 8.h),
              _InfoSectionSkeleton(),
              SizedBox(height: 8.h),
              _VoucherSectionSkeleton(),
              SizedBox(height: 8.h),
              _PaymentMethodSectionSkeleton(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNavigationBarSkeleton(),
    );
  }
}

class _AddressSectionSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(right: 16.w),
      width: double.infinity,
      height: 80.w,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(context.radiusXl),
      ),
      child: Row(
        children: [
          SizedBox(width: 10.w),
          Skeleton.react(
            width: 24.w,
            height: 24.h,
            borderRadius: BorderRadius.circular(12.r),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Skeleton.react(
                  width: double.infinity,
                  height: 10.h,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                SizedBox(height: 8.h),
                Skeleton.react(
                  width: double.infinity,
                  height: 10.h,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSectionSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(context.radiusXl),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton.react(
                  width: 80.w,
                  height: 80.h,
                  borderRadius: BorderRadius.circular(context.radiusLg),
                ),
                SizedBox(width: 12.h),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton.react(
                        width: double.infinity,
                        height: 12.h,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      SizedBox(height: 8.h),
                      Skeleton.react(
                        width: double.infinity,
                        height: 12.h,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      SizedBox(height: 8.h),
                      Skeleton.react(
                        width: double.infinity,
                        height: 12.h,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      SizedBox(height: 8.h),
                      Skeleton.react(
                        width: 80.w,
                        height: 12.h,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.h),
                Skeleton.react(
                  width: 20.w,
                  height: 12.h,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Expanded(child: Container()),
                Skeleton.react(
                  width: 190.w,
                  height: 36.h,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSectionSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(context.radiusXl),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Skeleton.react(
                      width: 120.w,
                      height: 12.h,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    Expanded(child: Container()),
                  ],
                ),
                SizedBox(height: 18.h),
                Row(
                  children: [
                    Skeleton.react(
                      width: 80.w,
                      height: 12.h,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    Expanded(child: Container()),
                    Skeleton.react(
                      width: 50.w,
                      height: 12.h,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                Row(
                  children: [
                    Skeleton.react(
                      width: 130.w,
                      height: 12.h,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    Expanded(child: Container()),
                    Skeleton.react(
                      width: 30.w,
                      height: 12.h,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                Row(
                  children: [
                    Skeleton.react(
                      width: 80.w,
                      height: 12.h,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    Expanded(child: Container()),
                    Skeleton.react(
                      width: 50.w,
                      height: 12.h,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoucherSectionSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(context.radiusXl),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Skeleton.react(
                      width: 80.w,
                      height: 12.h,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    Expanded(child: Container()),
                    Skeleton.react(
                      width: 80.w,
                      height: 12.h,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                Row(
                  children: [
                    Skeleton.react(
                      width: 120.w,
                      height: 12.h,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    Expanded(child: Container()),
                    Skeleton.react(
                      width: 80.w,
                      height: 12.h,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    SizedBox(width: 10.h),
                    Skeleton.react(
                      width: 36.w,
                      height: 20.h,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodSectionSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(context.radiusXl),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Skeleton.react(
                      width: 140.w,
                      height: 12.h,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                Row(
                  children: [
                    Skeleton.react(
                      width: 20.w,
                      height: 20.h,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    SizedBox(width: 10.h),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Skeleton.react(
                          width: 80.w,
                          height: 12.h,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        SizedBox(height: 8.h),
                        Skeleton.react(
                          width: 120.w,
                          height: 12.h,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ],
                    ),
                    Spacer(),
                    Skeleton.react(
                      width: 16.w,
                      height: 16.h,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigationBarSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      width: double.infinity,
      height: 80.h,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(context.radiusXl),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  children: [
                    Skeleton.react(
                      width: 80.w,
                      height: 12.h,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    SizedBox(height: 8.h),
                    Skeleton.react(
                      width: 100.w,
                      height: 12.h,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ],
                ),
                SizedBox(width: 16.h),
                Skeleton.react(
                  width: 120.w,
                  height: 40.h,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
