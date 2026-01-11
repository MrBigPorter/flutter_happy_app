import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/product_detail/detail_sections.dart';
import 'package:flutter_app/app/page/product_detail/join_treasure_bar.dart';
import 'package:flutter_app/app/page/product_detail/product_detail_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
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

  // Storage keys
  late final PageStorageKey _bannerStorageKey;
  late final PageStorageKey _pageStorageKey;

  @override
  void initState() {
    super.initState();
    _bannerStorageKey = PageStorageKey(
      'product_detail_banner_${widget.productId}',
    );
    _pageStorageKey = PageStorageKey('product_detail_page_${widget.productId}');

    _bottomBarController = AnimationController(
      duration: const Duration(milliseconds: 600), // 稍微调快一点动画
      vsync: this,
    );

    _opacityBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bottomBarController, curve: Curves.easeOut),
    );

    _offsetBarAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _bottomBarController,
            curve: Curves.easeOutCubic,
          ),
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
    //监听【静态详情】(带缓存，瞬间返回)
    final detailAsync = ref.watch(productDetailProvider(widget.productId));
    //监听【实时状态】(不缓存，每次进都会请求，慢几百毫秒)
    final statusAsync = ref.watch(
      productRealtimeStatusProvider(widget.productId),
    );
    final webBaseUrl = ref.watch(
      luckyProvider.select((s) => s.sysConfig.webBaseUrl),
    );

    final expandedHeight = 250.w;
    final bottomPadding = MediaQuery.viewInsetsOf(
      context,
    ).bottom.clamp(0.0, 9999.0);

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
                  onPressed: () => {
                    // 1. 检查路由栈里是否有上一页
                    if (context.canPop())
                      {
                        // 如果有，正常返回
                        context.pop(),
                      }
                    else
                      {
                        // 2. 如果没有（说明是从 DeepLink 直接空降进来的）
                        // 手动跳转回首页
                        context.go('/home'),
                      },
                  },
                  icon: Icon(
                    CupertinoIcons.back,
                    color: context.fgPrimary900,
                    size: 24.w,
                  ),
                ),
                // 优化：使用 FlexibleSpaceBar 避免手动计算 Opacity 带来的复杂性
                flexibleSpace: FlexibleSpaceBar(
                  expandedTitleScale: 1.0, // 禁止标题缩放
                  titlePadding: EdgeInsets.only(
                    left: 56.w,
                    right: 16.w,
                    bottom: 14.w,
                  ),
                  title: LayoutBuilder(
                    builder: (ctx, constraints) {
                      // 简单的判断：当折叠到一定程度显示标题
                      final isCollapsed =
                          constraints.maxHeight <=
                              kToolbarHeight +
                                  MediaQuery.of(context).padding.top +
                                  10;
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isCollapsed ? 1.0 : 0.0,
                        child: Text(
                          // 这里是商品名，来自 API，无需翻译
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

              // 2. Sections
              // 💡 提示：在 CouponSection 内部请使用 'product_detail.section_coupon'.tr()
              SliverToBoxAdapter(child: const CouponSection()),

              SliverToBoxAdapter(
                child: TopTreasureSection(
                  item: detail,
                  realTimeItem: statusAsync.value,
                  url: webBaseUrl,
                ),
              ),

              // 使用 RepaintBoundary 优化长列表滚动的性能
              // 💡 提示：在 GroupSection 内部请使用 'product_detail.section_group'.tr()
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: GroupSection(treasureId: detail.treasureId),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 8.w)),

              // 💡 提示：在 DetailContentSection 内部的 Tab 标题请使用 
              // 'product_detail.tab_desc'.tr() 和 'product_detail.tab_rules'.tr()
              SliverToBoxAdapter(
                child: DetailContentSection(
                  ruleContent: detail.ruleContent,
                  desc: detail.desc,
                ),
              ),

              // 底部留白，防止内容被 Bar 遮挡
              SliverToBoxAdapter(child: SizedBox(height: 100.w)),
            ],
          ),

          // 3. Bottom Bar (Join / Pre-sale)
          // 💡 提示：在 JoinTreasureBar 内部请使用 
          // 'product_detail.btn_buy_single'.tr() 和 'product_detail.btn_buy_group'.tr()
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
      // 简单处理，实际可加 ErrorWidget
      loading: () => const ProductDetailSkeleton(),
    );
  }
}