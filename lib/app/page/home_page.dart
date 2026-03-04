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

/// Optimized HomePage: Now supports auto-refresh when returning from other pages
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

// Use RouteAware to detect when the user pops back to this screen
class _HomePageState extends ConsumerState<HomePage> with RouteAware {

  /// Explicit Manual Refresh (With Haptic Feedback)
  Future<void> _onManualRefresh() async {
    HapticFeedback.mediumImpact();
    await Future.wait([
      ref.read(homeBannerProvider.notifier).forceRefresh(),
      ref.read(homeTreasuresProvider.notifier).forceRefresh(),
      ref.read(homeGroupBuyingProvider.notifier).forceRefresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final banners = ref.watch(homeBannerProvider);
    final treasures = ref.watch(homeTreasuresProvider);
    final hotGroups = ref.watch(homeGroupBuyingProvider);

    return BaseScaffold(
      showBack: false,
      body: LuckyCustomMaterialIndicator(
        onRefresh: _onManualRefresh,
        child: CustomScrollView(
          physics: platformScrollPhysics(),
          cacheExtent: 1000,
          slivers: [
            // 1. Banner Section
            banners.when(
              skipLoadingOnRefresh: true, // Crucial: Prevents flickering
              data: (list) => SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: SwiperBanner(banners: list),
                ),
              ),
              error: (_, __) => const HomeBannerSkeleton(),
              loading: () => const HomeBannerSkeleton(),
            ),

            // 2. Hot Group Buy Section
            hotGroups.when(
              skipLoadingOnRefresh: true,
              data: (data) {
                if (data.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverToBoxAdapter(
                  child: GroupBuyingSection(
                    title: "Hot Group Buy",
                    list: data,
                  ),
                );
              },
              error: (err, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // 3. Treasures Waterfall
            treasures.when(
              skipLoadingOnRefresh: true,
              data: (data) {
                if (data.isNotEmpty) {
                  return HomeTreasures(treasures: data);
                }
                return const HomeTreasureSkeleton();
              },
              error: (_, __) => const HomeTreasureSkeleton(),
              loading: () => const HomeTreasureSkeleton(),
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