import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/home_components/home_ad.dart';
import 'package:flutter_app/app/page/home_components/home_statistics.dart';
import 'package:flutter_app/app/page/home_components/home_treasures.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/featured_skeleton.dart';
import 'package:flutter_app/components/home_banner.dart';
import 'package:flutter_app/components/lucky_custom_material_indicator.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/core/providers/index.dart';

/// 首页 Home Page
/// 包含轮播图、宝贝列表、广告位、数据统计等模块 including carousel, treasure list, ad space, data statistics, etc.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(homeBannerProvider);
    final treasures = ref.watch(homeTreasuresProvider);
    final ads = ref.watch(homeAdProvider);
    final statistics = ref.watch(homeStatisticsProvider);

    /// 下拉刷新 refresh handler
    Future<void> onRefresh() async {
      /// only delete cache, not re-fetch data
      ref.invalidate(homeBannerProvider);
      ref.invalidate(homeTreasuresProvider);
      ref.invalidate(homeAdProvider);
      ref.invalidate(homeStatisticsProvider);

      /// wait for a while to show the refresh effect
      await Future.delayed(const Duration(milliseconds: 600));
    }

    return BaseScaffold(
      showBack: false,
      body: LuckyCustomMaterialIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: platformScrollPhysics(),
          slivers: [
            // 轮播图 Banner
            banners.when(
              data: (list) =>
                  SliverToBoxAdapter(child: HomeBanner(banners: list)),
              error: (_, __) => HomeBannerSkeleton(),
              loading: () => HomeBannerSkeleton(),
            ),

            /// statistics 统计数据
            statistics.when(
              data: (data) =>
                  SliverToBoxAdapter(child: HomeStatistics(statistics: data)),
              error: (_, __) => HomeStatisticsSkeleton(),
              loading: () => HomeStatisticsSkeleton(),
            ),

            /// ad 广告位
            ads.when(
              data: (data) => SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: HomeAd(list: data),
                ),
              ),
              error: (_, __) => HomeAdSkeleton(),
              loading: () => HomeAdSkeleton(),
            ),

            /// 宝贝列表 Treasure List
            treasures.when(
              data: (data) => HomeTreasures(treasures: data),
              error: (_, __) => HomeTreasureSkeleton(),
              loading: () => HomeTreasureSkeleton(),
            ),

            /// bottom padding 底部留白
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),
          ],
        ),
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
        child: FeaturedSkeleton(),
      ),
    );
  }
}

/// home ad loading skeleton
class HomeAdSkeleton extends StatelessWidget {
  const HomeAdSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          children: [
            Skeleton.react(width: double.infinity, height: 114),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Skeleton.react(width: 205, height: 267),
                SizedBox(width: 8.w),
                Column(
                  children: [
                    Skeleton.react(width: 130, height: 130),
                    SizedBox(height: 8.h),
                    Skeleton.react(width: 130, height: 130),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// home ad loading skeleton
class HomeStatisticsSkeleton extends StatelessWidget {
  const HomeStatisticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
        child: Skeleton.react(width: double.infinity, height: 80),
      ),
    );
  }
}

/// home banner loading skeleton
class HomeBannerSkeleton extends StatelessWidget {
  const HomeBannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Skeleton.react(width: double.infinity, height: 356),
      ),
    );
  }
}
