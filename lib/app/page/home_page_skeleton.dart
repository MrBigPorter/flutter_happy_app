import 'package:flutter/material.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Home page skeleton — shown while the home_page.dart chunk loads.
/// Matches the real HomePage layout: swiper banner, flash sale, group buying,
/// and treasure grid sections, all rendered as shimmer placeholders.
class HomePageSkeleton extends StatelessWidget {
  const HomePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SafeSingleChildScrollView(
      child: Column(
        children: [
          // 1. Swiper banner skeleton
          _BannerSkeleton(),
          SizedBox(height: 16),

          // 2. Flash sale section skeleton
          _FlashSaleSkeleton(),
          SizedBox(height: 16),

          // 3. Group buying section skeleton
          _GroupBuyingSkeleton(),
          SizedBox(height: 16),

          // 4. Treasure grid skeleton
          _TreasureGridSkeleton(),
        ],
      ),
    );
  }
}

/// Wraps content in a non-scrollable scroll view to prevent interference
/// with the real page scroll physics once the chunk loads.
class _SafeSingleChildScrollView extends StatelessWidget {
  const _SafeSingleChildScrollView({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 40.h),
      child: child,
    );
  }
}

/// Swiper banner skeleton — 2:1 aspect ratio shimmer placeholder.
class _BannerSkeleton extends StatelessWidget {
  const _BannerSkeleton();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Skeleton.react(
      width: screenWidth - 32.w,
      height: (screenWidth - 32.w) / 2,
      borderRadius: BorderRadius.circular(12.r),
    );
  }
}

/// Flash sale section skeleton — timer row + horizontal product cards.
class _FlashSaleSkeleton extends StatelessWidget {
  const _FlashSaleSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header + timer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Skeleton.react(
              width: 100.w,
              height: 20.h,
              borderRadius: BorderRadius.circular(4.r),
            ),
            Skeleton.react(
              width: 80.w,
              height: 20.h,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        // Horizontal scrollable product cards
        SizedBox(
          height: 180.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, _) => SizedBox(width: 12.w),
            itemBuilder: (_, _) => SizedBox(
              width: 140.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton.react(
                    width: 140.w,
                    height: 140.w,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  SizedBox(height: 8.h),
                  Skeleton.react(
                    width: 100.w,
                    height: 14.h,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Group buying section skeleton — two side-by-side wide cards.
class _GroupBuyingSkeleton extends StatelessWidget {
  const _GroupBuyingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Skeleton.react(
          width: 120.w,
          height: 20.h,
          borderRadius: BorderRadius.circular(4.r),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: Skeleton.react(
                width: 160,
                height: 160.h,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Skeleton.react(
                width: 160,
                height: 160.h,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Treasure grid skeleton — 2-column grid with product item skeletons.
class _TreasureGridSkeleton extends StatelessWidget {
  const _TreasureGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Skeleton.react(
          width: 80.w,
          height: 20.h,
          borderRadius: BorderRadius.circular(4.r),
        ),
        SizedBox(height: 12.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: 6,
          itemBuilder: (_, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton.react(
                width: 160,
                height: 120.h,
                borderRadius: BorderRadius.circular(8.r),
              ),
              SizedBox(height: 8.h),
              Skeleton.react(
                width: 160,
                height: 14.h,
                borderRadius: BorderRadius.circular(4.r),
              ),
              SizedBox(height: 4.h),
              Skeleton.react(
                width: 60.w,
                height: 14.h,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
