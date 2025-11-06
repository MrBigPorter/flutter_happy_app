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
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nested_scroll_view_plus/nested_scroll_view_plus.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ProductDetailTab {
  final String title;
  final String tabId;

  ProductDetailTab({required this.title, required this.tabId});
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
    ProductDetailTab(title: 'common.details'.tr(), tabId: 'details'),
    ProductDetailTab(title: 'raffle-rules'.tr(), tabId: 'rules'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(productDetailProvider(widget.productId));

    final desc =
        "\u003cp\u003e\u003cimg src=\"https://prod-pesolucky.s3.ap-east-1.amazonaws.com/rule/20250819154125141c3746-11dd-48cd-bc3b-0c10294513ab.png\" width=\"750\" height=\"500\"\u003erealme Buds T300（Global Version）：\u003cbr\u003ePort charge\u003c/p\u003e\u003cul\u003e\u003cli\u003eUSB Type-C\u003c/li\u003e\u003c/ul\u003e\u003cp\u003eCharging\u003c/p\u003e\u003cul\u003e\u003cli\u003eUSB Type C wired charging\u003c/li\u003e\u003c/ul\u003e\u003cp\u003eBluetooth Version\u003c/p\u003e\u003cul\u003e\u003cli\u003eBluetooth 5.3\u003c/li\u003e\u003c/ul\u003e\u003cp\u003e\u003cbr\u003eAudio codecs\u003c/p\u003e\u003cul\u003e\u003cli\u003eAAC, SBC\u003c/li\u003e\u003c/ul\u003e\u003cp\u003eWireless Range\u003c/p\u003e\u003cul\u003e\u003cli\u003e10m\u003c/li\u003e\u003c/ul\u003e\u003cp\u003eSize of sound\u003c/p\u003e\u003cul\u003e\u003cli\u003e12,4mm\u003c/li\u003e\u003c/ul\u003e\u003cp\u003eBattery capacity\u003c/p\u003e\u003cul\u003e\u003cli\u003eCharging case:460mAh; Single earbud: 43mAh\u003cbr\u003eCharging Time\u003c/li\u003e\u003cli\u003eCharging Case + Buds:10mins Charging for 7hrs Playback (50% Volume,ANC OFF)\u003c/li\u003e\u003c/ul\u003e\u003cp\u003eWaterproof Rating\u003c/p\u003e\u003cul\u003e\u003cli\u003eIP55 (earphones only)\u003c/li\u003e\u003c/ul\u003e\u003cp\u003eNoise Cancelling Features\u003c/p\u003e\u003cul\u003e\u003cli\u003e30dB Active Noise Cancelling, Environment Noise Cancelling\u003c/li\u003e\u003c/ul\u003e\u003cp\u003eBattery (Charging case + Buds)\u003c/p\u003e\u003cul\u003e\u003cli\u003eMusic playback 40hrs (50% Volume,ANC OFF); Music playback 30hrs (50% Volume,ANC ON)\u003c/li\u003e\u003c/ul\u003e\u003cp\u003eBattery (Earbuds Alone)\u003c/p\u003e\u003cul\u003e\u003cli\u003e8hrs Music Playback (50% Volume,ANC OFF); 6hrs Music Playback (50% Volume,ANC ON); 4hrs Calling Time (50% Volume,ANC OFF/ON)\u003c/li\u003e\u003c/ul\u003e\u003cp\u003eInside the box\u003c/p\u003e\u003cul\u003e\u003cli\u003eRealme Buds T300 x 1\u003c/li\u003e\u003cli\u003eCharging Cable Type C x 1\u003c/li\u003e\u003cli\u003eInformation Card x1/\u003c/li\u003e\u003cli\u003eS/M/L Silicone Eartips x 2\u003c/li\u003e\u003c/ul\u003e";

    return BaseScaffold(
      title: 'common.details'.tr(),
      body: DefaultTabController(
        length: 2,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _BannerSection(banners: detail.value?.mainImageList),
            ),
             SliverToBoxAdapter(child: _TopTreasureSection(item: detail.value!)),
            SliverToBoxAdapter(child: _GroupSection()),
            SliverFillRemaining(child: _DetailContentSection(content: desc)),
            SliverToBoxAdapter(child: _JoinTreasureSection()),
            SliverToBoxAdapter(child: SizedBox(height: 50.w)),
          ],
        ),
      ),
    );
  }
}

/// 选项卡项 tab item
class TabItem {
  final String text;
  final String? content;

  TabItem({required this.text, this.content});
}

/// 详情内容区 detail content section
class _DetailContentSection extends StatefulWidget {
  final String? content;

  const _DetailContentSection({this.content});

  @override
  State<_DetailContentSection> createState() => _DetailContentSectionState();
}

class _DetailContentSectionState extends State<_DetailContentSection>
    with SingleTickerProviderStateMixin {
  List<TabItem> get tabs => [
    TabItem(text: 'common.details', content: widget.content),
    TabItem(text: 'raffle-rules', content: widget.content),
  ];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
        decoration: BoxDecoration(
          color: context.bgPrimary,
          borderRadius: BorderRadius.all(Radius.circular(context.radiusMd)),
          border: Border.fromBorderSide(
            BorderSide(
              color: context.borderPrimary,
              width: 1.w,
            ),
          ),
        ),
        child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: context.textBrandSecondary700,
                  unselectedLabelColor: context.textQuaternary500,
                  indicatorColor: context.buttonPrimaryBg,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 2.w,
                  dividerColor: context.borderSecondary,
                  tabs: tabs.map((tab) {
                    return Tab(text: tab.text.tr());
                  }).toList(),
                ),
                SizedBox(height: 8.w),
                Expanded(
                    child: TabBarView(
                      children: tabs.map((tab) {
                        return SingleChildScrollView(
                          physics: NeverScrollableScrollPhysics(),
                          child: HtmlWidget(
                            tab.content ?? '',
                          ),
                        );
                      }).toList(
                      ),
                    )
                )
              ],
            )
        ),
      ),
    );
    /*return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      sliver: MultiSliver(
        children: [
          // tabBar 和 tabBarView 结合使用时，需要加固定高度的容器包裹 tabBarView，或者使用 SliverFillRemaining
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: context.bgPrimary,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(context.radiusMd),
                  bottom: Radius.circular(0),
                ),
                border: Border(
                  top: BorderSide(
                    color: context.borderPrimary,
                    width: 1.w,
                  ),
                  left: BorderSide(
                    color: context.borderPrimary,
                    width: 1.w,
                  ),
                  right: BorderSide(
                    color: context.borderPrimary,
                    width: 1.w,
                  ),
                )
              ),
              child: TabBar(
                labelColor: context.textBrandSecondary700,
                unselectedLabelColor: context.textQuaternary500,
                indicatorColor: context.buttonPrimaryBg,
               indicatorSize: TabBarIndicatorSize.tab,
               indicatorWeight: 2.w,
               dividerColor: Colors.transparent,
               dividerHeight: 1.w,
                tabs: tabs.map((tab) {
                  return Tab(text: tab.text.tr());
                }).toList(),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
            decoration: BoxDecoration(
                color: context.bgPrimary,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(context.radiusMd),
                  top: Radius.circular(0),
                ),
                border: Border.fromBorderSide(
                  BorderSide(
                    color: context.borderPrimary,
                    width: 1.w,
                  ),
                )
            ),
            child: TabBarView(
              children: tabs.map((tab) {
                return SingleChildScrollView(
                  physics: NeverScrollableScrollPhysics(),
                  child: HtmlWidget(
                    tab.content ?? '',

                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );*/
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
                            ),
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
                            FormatHelper.formatCurrency(
                              num.parse(item.charityAmount ?? '0'),
                            ),
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

class _GroupSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w,vertical: 16.w),
        decoration: BoxDecoration(
          color: context.bgPrimary,
          border: Border.all(color: context.borderPrimary, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(context.radiusMd)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'common.group.for.treasures'.tr(),
                        style: TextStyle(
                          fontSize: context.textMd,
                          fontWeight: FontWeight.w800,
                          color: context.fgPrimary900,
                          height: context.leadingMd,
                        ),
                      ),
                      SizedBox(height: 10.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.w),
                        decoration: BoxDecoration(
                          color: context.utilityBrand50,
                          borderRadius: BorderRadius.all(Radius.circular(context.radiusFull)),
                          border: Border.fromBorderSide(
                            BorderSide(
                              color: context.utilityBrand200,
                              width: 1.w,
                            ),
                          ),
                        ),
                        child: Text(
                          'common.users'.tr(
                            namedArgs: {
                              'number': '1234',
                            }
                          ),
                          style: TextStyle(
                            fontSize: context.text2xs,
                            color: context.utilityBrand700,
                            fontWeight: FontWeight.w500,
                            height: context.leadingXs,
                          ),
                        ),
                      )
                    ],
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    child:  SvgPicture.asset(
                        'assets/images/product_detail/goto.svg',
                        width: 16.w,
                        height: 16.w,
                        colorFilter: ColorFilter.mode(
                          context.fgPrimary900,
                          BlendMode.srcIn,
                        )
                    ),
                  )
                ],
              )
          ],
        ),
      ),
    );
  }
}

class _JoinTreasureSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('1111');
  }
}
