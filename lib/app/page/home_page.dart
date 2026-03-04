import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/page/home_components/home_treasures.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/lucky_custom_material_indicator.dart';
import 'package:flutter_app/components/swiper_banner.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/core/providers/index.dart';


import 'home_components/group_buying_section.dart';
import 'home_components/home_skeleton.dart';



class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(homeBannerProvider);
    final treasures = ref.watch(homeTreasuresProvider);

    //  监听拼团数据
    final hotGroups = ref.watch(homeGroupBuyingProvider);

    /// 下拉刷新
    Future<void> onRefresh() async {
      // 1. 触发高级触觉反馈
      HapticFeedback.mediumImpact();

      // 2. 使用并发请求，强制所有 Provider 去拿最新数据。
      // 因为使用了 SWR 机制，底层 state 直接被覆盖，页面不会出现哪怕 1 毫秒的白屏/骨架屏闪烁！
      await Future.wait([
        ref.read(homeBannerProvider.notifier).forceRefresh(),
        ref.read(homeTreasuresProvider.notifier).forceRefresh(),
         ref.read(homeGroupBuyingProvider.notifier).forceRefresh(),
      ]);
    }

    return BaseScaffold(
      showBack: false,
      body: LuckyCustomMaterialIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: platformScrollPhysics(),
          cacheExtent: 1000,
          slivers: [
            // ------------------------------------------------------
            // 1. Banner 轮播图
            // ------------------------------------------------------
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

            // ------------------------------------------------------
            // 2.  热门拼团区 (真实接口驱动)
            // ------------------------------------------------------
            hotGroups.when(
              data: (data) {
                // 如果后端返回空数组，直接隐藏区域
                if (data.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

                return SliverToBoxAdapter(
                  child: GroupBuyingSection(
                    title: " Hot Group Buy",
                    list: data,
                  ),
                );
              },
              // 加载中或出错时不显示，保持页面整洁，等待数据回来自动弹入
              error: (err, stack) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // ------------------------------------------------------
            // 3. 宝贝列表 (瀑布流)
            // ------------------------------------------------------
            treasures.when(
              data: (data) {
                if (data.isNotEmpty) {
                  return HomeTreasures(treasures: data);
                }
                return HomeTreasureSkeleton();
              },
              error: (_, __) => HomeTreasureSkeleton(),
              loading: () => HomeTreasureSkeleton(),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 20.h)),

            const SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: false,
              child: SizedBox.shrink(),
            )
          ],
        ),
      ),
    );
  }
}