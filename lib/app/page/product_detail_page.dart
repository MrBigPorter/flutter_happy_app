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
    final detailAsync = ref.watch(productDetailProvider(widget.productId));
    final statusAsync = ref.watch(productRealtimeStatusProvider(widget.productId));
    final webBaseUrl = ref.watch(configProvider.select((s) => s.webBaseUrl));

    final expandedHeight = 250.w;
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom.clamp(0.0, 9999.0);

    return detailAsync.when(
      //Banners 核心优化 4：全局无缝刷新防闪烁，哪怕被 invalidate，也绝不回退到加载骨架屏
      skipLoadingOnRefresh: true,
      data: (detail) {
        return Scaffold(
          body: CustomScrollView(
            key: _pageStorageKey,
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: expandedHeight,
                backgroundColor: context.bgPrimary,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  icon: Icon(CupertinoIcons.back, color: context.fgPrimary900, size: 24.w),
                ),
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

              const SliverToBoxAdapter(child: CouponSection()),

              SliverToBoxAdapter(
                child: TopTreasureSection(
                  item: detail,
                  realTimeItem: statusAsync.value,
                  url: webBaseUrl,
                ),
              ),

              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: GroupSection(
                    treasureId: detail.treasureId,
                    item: detail,
                    realTimeStatus: statusAsync.value,
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 8.w)),

              SliverToBoxAdapter(
                child: DetailContentSection(
                  ruleContent: detail.ruleContent,
                  desc: detail.desc,
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 100.w)),
            ],
          ),
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
                  realTimeStatus: statusAsync.value,
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