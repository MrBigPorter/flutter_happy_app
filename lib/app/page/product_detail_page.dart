import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/safe_tab_bar_view.dart';
import 'package:flutter_app/components/swiper_banner.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/ui/bubble_progress.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/lucky_tab_bar_delegate.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nested_scroll_view_plus/nested_scroll_view_plus.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ProductDetailTab {
  final String title;

  ProductDetailTab({required this.title});
}

class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final List<ProductDetailTab> _tabs = [
    ProductDetailTab(title: 'common.details'.tr()),
    ProductDetailTab(title: 'raffle-rules'.tr()),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(productDetailProvider(widget.productId));
    print(detail.toString());

    return BaseScaffold(
      title: 'common.details'.tr(),
      body: NestedScrollViewPlus(
        headerSliverBuilder: (_, __) {
          return [
            detail.when(
              data: (detail) {
                return MultiSliver(
                  children: [
                    _BannerSection(banners: detail.mainImageList),
                    _TopTreasureSection(item: detail),
                    //_CouponSection(),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: LuckySliverTabBarDelegate(
                        height: 38,
                        labelStyle: TextStyle(
                          color: context.textBrandSecondary700,
                        ),
                        enableUnderLine: true,
                        showPersistentBg: true,
                        controller: _tabController,
                        tabs: _tabs,
                        renderItem: (item) => Tab(text: item.title),
                      ),
                    ),
                    _ProductInfoSection(
                      tabs: _tabs,
                      tabController: _tabController!,
                    ),
                    _JoinTreasureSection(),
                  ],
                );
              },
              error: (_, __) => SliverToBoxAdapter(
                child: Center(child: Text('Error loading product, details')),
              ),
              loading: () => SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ];
        },
        body: SafeTabBarView(
          controller: _tabController,
          children: _tabs.map((tab) {
            return Center(child: Text('Content for ${tab.title}'));
          }).toList(),
        ),
      ),
    );
  }
}

class _BannerSection extends StatelessWidget {
  final List<String>? banners;

  const _BannerSection({required this.banners});

  @override
  Widget build(BuildContext context) {
    if (banners == null || banners!.isEmpty) {
      return SizedBox.shrink();
    }
    return SwiperBanner(height: 250, borderRadius: 0, banners: banners!);
  }
}

class _TopTreasureSection extends StatelessWidget {
  final ProductListItem item;

  const _TopTreasureSection({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
      child: Container(
        width: double.infinity,
        height: 220.w,
        decoration: BoxDecoration(
          color: context.bgPrimary,
          border: Border.all(color: context.borderPrimary, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(context.radiusMd)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 8.w,
              right: 8.w,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: SvgPicture.asset(
                  'assets/images/product_detail/share.svg',
                  width: 20.w,
                  height: 20.w,
                  colorFilter: ColorFilter.mode(
                    context.fgPrimary900,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
              child: Column(
                children: [
                  Text(
                    item.treasureName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.textMd,
                      fontWeight: FontWeight.w800,
                      color: context.fgPrimary900,
                    ),
                  ),
                  SizedBox(height: 8.w),
                  Button(
                    height: 22.w,
                    radius: context.radiusXs,
                    noPressAnimation: true,
                    onPressed: () {},
                    child: Text(
                      FormatHelper.formatCurrency(item.unitAmount),
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  SizedBox(height: 16.w),
                  BubbleProgress(value: item.buyQuantityRate),
                  SizedBox(height: 2.w),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0',
                        style: TextStyle(
                          fontSize: context.text2xs,
                          color: context.textSecondary700,
                          height: context.leading2xs,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${item.seqBuyQuantity}${'entries-sold'.tr()}',
                        style: TextStyle(
                          fontSize: context.text2xs,
                          color: context.textSecondary700,
                          height: context.leading2xs,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${item.seqShelvesQuantity}',
                        style: TextStyle(
                          fontSize: context.text2xs,
                          color: context.textSecondary700,
                          height: context.leading2xs,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.w),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.person_circle,
                            size: 24.w,
                            color: context.fgPrimary900,
                          ),
                          SizedBox(height: 8.w),
                          Text(
                            '${item.maxPerBuyQuantity ?? 0}Max',
                            style: TextStyle(
                              fontSize: context.text2xs,
                              color: context.textSecondary700,
                              height: context.leading2xs,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4.w),
                          Text(
                            'common.persons'.tr(),
                            style: TextStyle(
                              fontSize: context.text2xs,
                              color: context.textSecondary700,
                              height: context.leading2xs,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.calendar,
                            size: 24.w,
                            color: context.fgPrimary900,
                          ),
                          SizedBox(height: 8.w),
                          Text(
                            '${item.maxPerBuyQuantity ?? 0}Max',
                            style: TextStyle(
                              fontSize: context.text2xs,
                              color: context.textSecondary700,
                              height: context.leading2xs,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4.w),
                          Text(
                            'common.persons'.tr(),
                            style: TextStyle(
                              fontSize: context.text2xs,
                              color: context.textSecondary700,
                              height: context.leading2xs,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/images/product_detail/wallet.svg',
                            width: 24.w,
                            height: 24.w,
                            colorFilter: ColorFilter.mode(
                              context.fgPrimary900,
                              BlendMode.srcIn,
                            ),
                          ),
                          SizedBox(height: 8.w),
                          Text(
                              FormatHelper.formatCurrency(item.costAmount ?? 0),
                            style: TextStyle(
                              fontSize: context.text2xs,
                              color: context.textSecondary700,
                              height: context.leading2xs,
                              fontWeight: FontWeight.w600,
                            )
                          ),
                          SizedBox(height: 4.w),
                          Text(
                            'common.cash.value'.tr(),
                            style: TextStyle(
                              fontSize: context.text2xs,
                              color: context.textSecondary700,
                              height: context.leading2xs,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(
                              FontAwesomeIcons.handHoldingHeart,
                              size: 24,
                             color: context.fgPrimary900,
                          ),
                          SizedBox(height: 8.w),
                          Text(
                            'common.charity.value'.tr(),
                            style: TextStyle(
                              fontSize: context.text2xs,
                              color: context.textSecondary700,
                              height: context.leading2xs,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4.w),
                          Text(
                            FormatHelper.formatCurrency(num.parse(item.charityAmount??'0')),
                            style: TextStyle(
                              fontSize: context.text2xs,
                              color: context.textSecondary700,
                              height: context.leading2xs,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.grey[200],
      child: Center(child: Text('Coupon Section')),
    );
  }
}

class _ProductInfoSection extends StatelessWidget {
  final List<ProductDetailTab> tabs;
  final TabController tabController;

  const _ProductInfoSection({required this.tabs, required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      color: Colors.grey[300],
      child: Center(child: Text('Product Info Section')),
    );
  }
}

class _JoinTreasureSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.grey[200],
      child: Center(child: Text('Join Treasure Section')),
    );
  }
}
