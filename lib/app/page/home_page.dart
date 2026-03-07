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
class _HomePageState extends ConsumerState<HomePage> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    // register this widget as an observer to app lifecycle events
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // unregister the observer when the widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app is resumed (e.g., user returns to this page), trigger a refresh
    if (state == AppLifecycleState.resumed) {
      _silentRefresh();
    }
  }

  Future<void> _silentRefresh() async {
    await Future.wait([
      ref.read(homeBannerProvider.notifier).forceRefresh(),
      ref.read(homeTreasuresProvider.notifier).forceRefresh(),
      ref.read(homeGroupBuyingProvider.notifier).forceRefresh(),
    ]);
  }

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

    // Listen to the refresh trigger. When it becomes true, perform a silent refresh and then reset the trigger.
    ref.listen(homeNeedsRefreshProvider, (previous, next) {
      if (next == true) {
        _silentRefresh();
        ref.read(homeNeedsRefreshProvider.notifier).state = false;
      }
    });

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
              skipLoadingOnRefresh: true,
              skipLoadingOnReload: true, // 🚀 修复 3：补上重载免死金牌，彻底告别骨架屏闪烁！
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
              skipLoadingOnReload: true, // 🚀 修复 3
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
              skipLoadingOnReload: true, // 🚀 修复 3
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