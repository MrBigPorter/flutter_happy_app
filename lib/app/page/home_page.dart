import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/page/home_components/flash_sale_section.dart';
import 'package:flutter_app/app/page/home_components/home_treasures.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/lucky_custom_material_indicator.dart';
import 'package:flutter_app/components/pwa_banners.dart';
import 'package:flutter_app/components/swiper_banner.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_app/utils/image/image_preloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/core/models/index.dart';

import '../../utils/image/image_optimization_init.dart';
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

  /// 【修复 P0-2】用来防止重复触发预加载的标志
  bool _hasPreloadedImages = false;
  /// App 最后一次进入前台的时间，用于 resume 刷新的时间门槛（P2）
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 只做系统初始化，不在此读 Provider 数据（数据还未到达）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initImageSystem();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 【修复 P2】5 分钟内不重复刷新，避免接电话/锁屏后立即触发无意义的 API 并发
      final now = DateTime.now();
      if (_lastRefreshTime == null ||
          now.difference(_lastRefreshTime!) > const Duration(minutes: 5)) {
        _lastRefreshTime = now;
        _silentRefresh();
      }
    }
  }

  Future<void> _silentRefresh() async {
    await Future.wait([
      ref.read(homeBannerProvider.notifier).forceRefresh(),
      ref.read(homeTreasuresProvider.notifier).forceRefresh(),
      ref.read(homeGroupBuyingProvider.notifier).forceRefresh(),
    ]);
  }

  /// 只负责初始化图片优化系统（不预加载动态数据）
  Future<void> _initImageSystem() async {
    try {
      final imageOptimization = ImageOptimizationInit();
      if (!imageOptimization.isCoreInitialized) {
        await imageOptimization.initializeCore();
      }
      if (!imageOptimization.isInitialized) {
        await imageOptimization.initialize(context);
      }
      // 预加载静态图片（icon/logo 等无需 API 数据）
      await imageOptimization.preloadStaticImages(context);
      debugPrint('[HomePage] Image system initialized.');
    } catch (e) {
      debugPrint('[HomePage] Image system init failed: $e');
    }
  }

  /// 预加载首页关键图片
  /// 预加载首页关键图片
  Future<void> _preloadHomeImages() async {
    try {
      final preloader = ImagePreloader();

      // 获取首页数据
      final banners = ref.read(homeBannerProvider);
      final treasures = ref.read(homeTreasuresProvider);
      final hotGroups = ref.read(homeGroupBuyingProvider);
      final flashSaleSessions = ref.read(flashSaleActiveSessionsProvider);

      List<String> imageUrls = [];

      // 1. 收集轮播图图片（逻辑宽度 375）
      banners.whenData((bannerList) {
        for (final banner in bannerList) {
          if (banner.bannerImgUrl.isNotEmpty) {
            imageUrls.add(ImageOptimizationInit().generateResponsiveUrl(
              originalUrl: banner.bannerImgUrl,
              width: 375,
              height: 356,
            ));
          }
        }
      });

      // 2. 收集商品图片（逻辑宽度 166）
      treasures.whenData((treasureList) {
        for (final treasure in treasureList) {
          for (final product in treasure.treasureResp ?? []) {
            final img = product.treasureCoverImg ?? '';
            if (img.isNotEmpty) {
              imageUrls.add(ImageOptimizationInit().generateResponsiveUrl(
                originalUrl: img,
                width: 166,
                height: 166,
              ));
            }
          }
        }
      });

      // 3. 收集团购图片（逻辑宽度 166）
      hotGroups.whenData((groupList) {
        for (final group in groupList) {
          final img = group.treasureCoverImg ?? '';
          if (img.isNotEmpty) {
            imageUrls.add(ImageOptimizationInit().generateResponsiveUrl(
              originalUrl: img,
              width: 166,
              height: 166,
            ));
          }
        }
      });

      // 4. 收集 Flash Sale 图片（逻辑宽度 115）
      flashSaleSessions.whenData((sessionList) {
        if (sessionList.isNotEmpty) {
          final products = ref.read(flashSaleSessionProductsProvider(sessionList.first.id));
          products.whenData((productData) {
            for (final productItem in productData.list) {
              final img = productItem.product.treasureCoverImg ?? '';
              if (img.isNotEmpty) {
                imageUrls.add(ImageOptimizationInit().generateResponsiveUrl(
                  originalUrl: img,
                  width: 115,
                  height: 115,
                ));
              }
            }
          });
        }
      });

      // 去重并预加载
      if (imageUrls.isNotEmpty) {
        final uniqueUrls = imageUrls.toSet().toList();
        debugPrint('[HomePage] Preloading ${uniqueUrls.length} images for home page (including Flash Sale)');

        final criticalUrls = uniqueUrls.take(10).toList();
        await preloader.preloadUrls(criticalUrls, context); // 此时传进去的就是带有 cdn-cgi 的最终地址了

        if (uniqueUrls.length > 10) {
          final remainingUrls = uniqueUrls.sublist(10);
          Future(() => preloader.preloadUrls(remainingUrls, context));
        }
      }
    } catch (e) {
      debugPrint('[HomePage] Image preloading failed: $e');
    }
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

    // 【修复 P0-2】数据就绪后才触发动态预加载，且只触发一次。
    // 用 addPostFrameCallback 避免在 build 过程中调用异步方法。
    if (!_hasPreloadedImages) {
      final hasBanners = banners.hasValue && (banners.value?.isNotEmpty ?? false);
      final hasTreasures = treasures.hasValue && (treasures.value?.isNotEmpty ?? false);
      if (hasBanners || hasTreasures) {
        _hasPreloadedImages = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _preloadHomeImages();
        });
      }
    }

    return BaseScaffold(
      showBack: false,
      body: LuckyCustomMaterialIndicator(
        onRefresh: _onManualRefresh,
        child: CustomScrollView(
          physics: platformScrollPhysics(),
          cacheExtent: 1500,
          slivers: [
            // 0. PWA Install Banner (Web only, auto-hides when not applicable)
            const SliverToBoxAdapter(child: PwaInstallBanner()),

            // 1. Banner Section
            banners.when(
              skipLoadingOnRefresh: true,
              skipLoadingOnReload: true, //  修复 3：补上重载免死金牌，彻底告别骨架屏闪烁！
              data: (list) => SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: SwiperBanner(
                    banners: list,
                    blurhashExtractor: (Banners item) => item.blurhash,
                  ),
                ),
              ),
              error: (_, __) => const HomeBannerSkeleton(),
              loading: () => const HomeBannerSkeleton(),
            ),

            // 2. Flash Sale Section (auto-hidden when no active sessions)
            const SliverToBoxAdapter(child: FlashSaleSection()),

            // 3. Hot Group Buy Section
            hotGroups.when(
              skipLoadingOnRefresh: true,
              skipLoadingOnReload: true, //  修复 3
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

            // 4. Treasures Waterfall
            treasures.when(
              skipLoadingOnRefresh: true,
              skipLoadingOnReload: true, //  修复 3
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