import 'package:flutter/material.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/theme/design_tokens.g.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Me page skeleton — shown while the me_page.dart chunk loads.
/// Matches the real MePage layout: avatar row, order card, wallet card, menu grid.
class MePageSkeleton extends StatelessWidget {
  const MePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 40.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Avatar row
          Row(
            children: [
              const Skeleton.circle(width: 64, height: 64),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton.react(
                      width: 120.w,
                      height: 20.h,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    SizedBox(height: 8.h),
                    Skeleton.react(
                      width: 80.w,
                      height: 16.h,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // 2. Order management card
          _buildCard(
            context,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                4,
                (index) => Column(
                  children: [
                    Skeleton.react(
                      width: 28.w,
                      height: 28.w,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    SizedBox(height: 6.h),
                    Skeleton.react(
                      width: 40.w,
                      height: 12.h,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // 3. Wallet card
          _buildCard(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton.react(
                  width: 100.w,
                  height: 16.h,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    3,
                    (index) => Column(
                      children: [
                        Skeleton.react(
                          width: 32.w,
                          height: 32.w,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        SizedBox(height: 6.h),
                        Skeleton.react(
                          width: 48.w,
                          height: 12.h,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // 4. Core menu grid (2 rows × 4 columns)
          _buildCard(
            context,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    4,
                    (index) => _menuItem(),
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    4,
                    (index) => _menuItem(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: child,
    );
  }

  Widget _menuItem() {
    return Column(
      children: [
        Skeleton.react(
          width: 32.w,
          height: 32.w,
          borderRadius: BorderRadius.circular(8.r),
        ),
        SizedBox(height: 6.h),
        Skeleton.react(
          width: 40.w,
          height: 12.h,
          borderRadius: BorderRadius.circular(4.r),
        ),
      ],
    );
  }
}
