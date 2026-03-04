import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/page/home_components/home_treasures.dart';
import 'package:flutter_app/app/routes/app_router.dart';
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
class _HomePageState extends ConsumerState<HomePage> {

  late VoidCallback _routeListener;
  bool _wasOnHome = true;

  @override
  void initState() {
    super.initState();

    //  核心逻辑：无论通过什么极其复杂的链路，只要 URL 最终回到了 /home，就触发刷新！
    _routeListener = (){
      if(!mounted) return;
       // 获取当前最新的 URL 路径
      final location = appRouter.routerDelegate.currentConfiguration.uri.path;
      final isOnHome = location == "/home";

      // 状态机判断：如果刚刚不在首页，现在回到了首页 -> 触发刷新
      if(isOnHome && !_wasOnHome){
        _silentRefresh();
        _wasOnHome = isOnHome;
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_){
      appRouter.routerDelegate.addListener(_routeListener);
    });

  }

  @override
  void dispose() {
    appRouter.routerDelegate.removeListener(_routeListener);
    super.dispose();
  }


  /// 静默刷新：不闪屏、不显示 Loading
  Future<void> _silentRefresh() async {
    await Future.wait([
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