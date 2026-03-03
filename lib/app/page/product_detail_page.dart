import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/product_detail/detail_sections.dart';
import 'package:flutter_app/app/page/product_detail/join_treasure_bar.dart';
import 'package:flutter_app/app/page/product_detail/product_detail_skeleton.dart';
import 'package:flutter_app/core/store/config_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:go_router/go_router.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;
  final dynamic queryParams;

  const ProductDetailPage({
    super.key,
    required this.productId,
    this.queryParams,
  });

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bottomBarController;
  late final Animation<Offset> _offsetBarAnimation;
  late final Animation<double> _opacityBarAnimation;

  // Storage keys to preserve scroll position
  late final PageStorageKey _bannerStorageKey;
  late final PageStorageKey _pageStorageKey;

  @override
  void initState() {
    super.initState();
    _bannerStorageKey = PageStorageKey('product_detail_banner_${widget.productId}');
    _pageStorageKey = PageStorageKey('product_detail_page_${widget.productId}');

    _bottomBarController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _opacityBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bottomBarController, curve: Curves.easeOut),
    );

    _offsetBarAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _bottomBarController, curve: Curves.easeOutCubic),
    );

    _bottomBarController.forward();
  }

  @override
  void dispose() {
    _bottomBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch static details (cached, returns instantly)
    final detailAsync = ref.watch(productDetailProvider(widget.productId));
    // Watch real-time status (not cached, updates dynamic inventory/price)
    final statusAsync = ref.watch(productRealtimeStatusProvider(widget.productId));
    final webBaseUrl = ref.watch(configProvider.select((s) => s.webBaseUrl));

    final expandedHeight = 250.w;
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom.clamp(0.0, 9999.0);

    return detailAsync.when(
      data: (detail) {
        return Scaffold(
          body: CustomScrollView(
            key: _pageStorageKey,
            slivers: [
              // 1. App Bar & Banner
              SliverAppBar(
                pinned: true,
                expandedHeight: expandedHeight,
                backgroundColor: context.bgPrimary,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  onPressed: () {
                    // Check if there is a previous page in the routing stack
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      // Fallback: Redirect to home if opened via DeepLink
                      context.go('/home');
                    }
                  },
                  icon: Icon(CupertinoIcons.back, color: context.fgPrimary900, size: 24.w),
                ),
                // Optimized FlexibleSpaceBar avoiding manual opacity calculations
                flexibleSpace: FlexibleSpaceBar(
                  expandedTitleScale: 1.0,
                  titlePadding: EdgeInsets.only(left: 56.w, right: 16.w, bottom: 14.w),
                  title: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final isCollapsed = constraints.maxHeight <= kToolbarHeight + MediaQuery.of(context).padding.top + 10;
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isCollapsed ? 1.0 : 0.0,
                        child: Text(
                          detail.treasureName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.textMd,
                            fontWeight: FontWeight.w700,
                            color: context.fgPrimary900,
                          ),
                        ),
                      );
                    },
                  ),
                  background: BannerSection(
                    banners: [detail.treasureCoverImg ?? ''],
                    storageKey: _bannerStorageKey,
                    height: expandedHeight,
                  ),
                ),
              ),

              // 2. Main Content Sections

              // Integrated Coupon Section (Live API Connection)
              const SliverToBoxAdapter(child: CouponSection()),

              SliverToBoxAdapter(
                child: TopTreasureSection(
                  item: detail,
                  realTimeItem: statusAsync.value,
                  url: webBaseUrl,
                ),
              ),

              // Optimized long list rendering using RepaintBoundary
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: GroupSection(treasureId: detail.treasureId),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 8.w)),

              SliverToBoxAdapter(
                child: DetailContentSection(
                  ruleContent: detail.ruleContent,
                  desc: detail.desc,
                ),
              ),

              // Bottom padding to prevent content from being obscured by the bottom bar
              SliverToBoxAdapter(child: SizedBox(height: 100.w)),
            ],
          ),

          // 3. Bottom Bar (Join / Pre-sale)
          bottomNavigationBar: AnimatedPadding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: FadeTransition(
              opacity: _opacityBarAnimation,
              child: SlideTransition(
                position: _offsetBarAnimation,
                child: JoinTreasureBar(
                  groupId: widget.queryParams?['groupId'],
                  item: detail,
                ),
              ),
            ),
          ),
        );
      },
      error: (err, stack) => const ProductDetailSkeleton(),
      loading: () => const ProductDetailSkeleton(),
    );
  }
}