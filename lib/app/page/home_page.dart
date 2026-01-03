import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/home_components/home_treasures.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/lucky_custom_material_indicator.dart';
import 'package:flutter_app/components/swiper_banner.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/core/providers/index.dart';

import 'home_components/home_skeleton.dart';

/// 首页 Home Page
/// 包含轮播图、宝贝列表、广告位、数据统计等模块 including carousel, treasure list, ad space, data statistics, etc.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(homeBannerProvider);
    final treasures = ref.watch(homeTreasuresProvider);

    /// 下拉刷新 refresh handler
    Future<void> onRefresh() async {
      /// only delete cache, not re-fetch data
      ref.invalidate(homeBannerProvider);
      ref.invalidate(homeTreasuresProvider);
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
          cacheExtent: 1000,// 提前缓存区域，提升滚动流畅度 pre-cache area to improve scrolling smoothness
          slivers: [
            // 轮播图 Banner
            banners.when(
              data: (list) => SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: SwiperBanner(banners: list),
                ),
              ),
              error: (_, __) => HomeBannerSkeleton(),
              loading: () => HomeBannerSkeleton(),
            ),

            /// 宝贝列表 Treasure List
            treasures.when(
              data: (data){
                if(data.isNotEmpty){
                 return HomeTreasures(treasures: data);
                }
                return HomeTreasureSkeleton();
              },
              error: (_, __) => HomeTreasureSkeleton(),
              loading: () => HomeTreasureSkeleton(),
            ),

            /// bottom padding 底部留白
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),

            const SliverFillRemaining(
              hasScrollBody: false, // prevent scrolling 当内容不足时防止滚动,只是填充剩余空间
              fillOverscroll: false,
              child: SizedBox.shrink(),
            )
          ],
        ),
      ),
    );
  }
}



