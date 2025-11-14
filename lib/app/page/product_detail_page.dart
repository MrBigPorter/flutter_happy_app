import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/page/product_components/share_sheet.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/anime_count.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/components/swiper_banner.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/core/providers/purchase_state_provider.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_app/features/share/index.dart';
import 'package:flutter_app/ui/bubble_progress.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/ui/modal/index.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bottomBarController;
  late final Animation<Offset> _offsetBarAnimation;
  late final Animation<double> _opacityBarAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _bottomBarController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _opacityBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bottomBarController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    // Define offset animation,set to slide in from bottom
    _offsetBarAnimation = Tween<Offset>(begin: Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _bottomBarController,
            curve: Curves.elasticInOut,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    // Start the animation
    _bottomBarController.forward();
  }

  @override
  void dispose() {
    _bottomBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // login status
    final isAuthenticated = ref.watch(
      authProvider.select((select) => select.isAuthenticated),
    );
    // exchange rate
    final exchangeRate = ref.watch(
      luckyProvider.select((select) => select.sysConfig.exChangeRate),
    );
    // user coin balance
    final coinBalance = ref.watch(
      luckyProvider.select((select) => select.balance.coinBalance),
    );
    // product detail
    final detail = ref.watch(productDetailProvider(widget.productId));
    final webBaseUrl = ref.watch(
      luckyProvider.select((select) => select.sysConfig.webBaseUrl),
    );

    final PurchaseArgs args = (
      unitPrice: detail.value?.unitAmount ?? 0,
      maxUnitCoins: detail.value?.maxUnitCoins ?? 0,
      exchangeRate: exchangeRate,
      maxPerBuy: detail.value?.maxPerBuyQuantity ?? 999999,
      minPerBuy: detail.value?.minBuyQuantity ?? 1,
      stockLeft:
          (detail.value?.seqShelvesQuantity ?? 0) -
          (detail.value?.seqBuyQuantity ?? 0),
      isLoggedIn: isAuthenticated,
      balanceCoins: coinBalance,
      coinAmountCap: null,
      entries: detail.value?.minBuyQuantity ?? 1,
    );

    final desc =
        "\u003cp\u003e\u003cimg src=\"https://prod-pesolucky.s3.ap-east-1.amazonaws.com/rule/20250819154125141c3746-11dd-48cd-bc3b-0c10294513ab.png\" width=\"750\" height=\"500\"\u003erealme Buds T300（Global Version）：\u003cbr\u003ePort charge\u003c/p\u003e\u003cul\u003e\u003cli\u003eUSB Type-C\u003c/li\u003e\u003c/ul\u003e\u003cp\u003eCharging\u003c/p\u003e\u003cul\u003e\u003cli\u003eUSB Type C wired charging\u003c/li\u003e\u003c/ul\u003e\u003cp\u003eBluetooth Version\u003c/p\u003e\u003cul\u003e\u003cli\u003eBluetooth 5.3\u003c/li\u003e\u003c/ul\u003e\u003cp\u003e\u003cbr\u003eAudio codecs\u003c/p\u003e\u003cul\u003e\u003cli\u003eAAC, SBC\u003c/li\u003e\u003c/ul\u003e\u003cp\u003eWireless Range\u003c/p\u003e\u003cul\u003e\u003cli\u003e10m\u003c/li\u003e\u003c/ul\u003e\u003cp\u003eSize of sound\u003c/p\u003e\u003cul\u003e\u003cli\u003e12,4mm\u003c/li\u003e\u003c/ul\u003e\u003cp\u003eBattery capacity\u003c/p\u003e\u003cul\u003e\u003cli\u003eCharging case:460mAh; Single earbud: 43mAh\u003cbr\u003eCharging Time\u003c/li\u003e\u003cli\u003eCharging Case + Buds:10mins Charging for 7hrs Playback (50% Volume,ANC OFF)\u003c/li\u003e\u003c/ul\u003e\u003cp\u003eWaterproof Rating\u003c/p\u003e\u003cul\u003e\u003cli\u003eIP55 (earphones only)\u003c/li\u003e\u003c/ul\u003e\u003cp\u003eNoise Cancelling Features\u003c/p\u003e\u003cul\u003e\u003cli\u003e30dB Active Noise Cancelling, Environment Noise Cancelling\u003c/li\u003e\u003c/ul\u003e\u003cp\u003eBattery (Charging case + Buds)\u003c/p\u003e\u003cul\u003e\u003cli\u003eMusic playback 40hrs (50% Volume,ANC OFF); Music playback 30hrs (50% Volume,ANC ON)\u003c/li\u003e\u003c/ul\u003e\u003cp\u003eBattery (Earbuds Alone)\u003c/p\u003e\u003cul\u003e\u003cli\u003e8hrs Music Playback (50% Volume,ANC OFF); 6hrs Music Playback (50% Volume,ANC ON); 4hrs Calling Time (50% Volume,ANC OFF/ON)\u003c/li\u003e\u003c/ul\u003e\u003cp\u003eInside the box\u003c/p\u003e\u003cul\u003e\u003cli\u003eRealme Buds T300 x 1\u003c/li\u003e\u003cli\u003eCharging Cable Type C x 1\u003c/li\u003e\u003cli\u003eInformation Card x1/\u003c/li\u003e\u003cli\u003eS/M/L Silicone Eartips x 2\u003c/li\u003e\u003c/ul\u003e";

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 250,
            title: null,
            backgroundColor: context.bgPrimary,
            surfaceTintColor: Colors.transparent,
            shadowColor: context.bgBrandPrimaryAlt,
            elevation: 0,
            scrolledUnderElevation: 1,
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(
                CupertinoIcons.back,
                color: context.fgPrimary900,
                size: 24.w,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _BannerSection(banners: detail.value?.mainImageList),
            ),
          ),
          SliverToBoxAdapter(
            child: _TopTreasureSection(item: detail.value, url: webBaseUrl),
          ),
          SliverToBoxAdapter(child: _GroupSection()),
          SliverToBoxAdapter(child: SizedBox(height: 8.w)),
          SliverToBoxAdapter(child: _DetailContentSection(content: desc)),
        ],
      ),
      bottomNavigationBar: FadeTransition(
        opacity: _opacityBarAnimation,
        child: SlideTransition(
          position: _offsetBarAnimation,
          child: _JoinTreasureSection(
              treasureId: detail.value?.treasureId,
              groupId: null,//todo
              args: args
          ),
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

/// 详情内容区 state
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
            BorderSide(color: context.borderPrimary, width: 1.w),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
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
            AnimatedBuilder(
              animation: _tabController,
              builder: (_, __) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: KeyedSubtree(
                    key: ValueKey(_tabController.index),
                    child: HtmlWidget(tabs[_tabController.index].content ?? ''),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 轮播图区域 banner section
class _BannerSection extends StatelessWidget {
  final List<String>? banners;

  const _BannerSection({required this.banners});

  @override
  Widget build(BuildContext context) {
    if (banners == null || banners!.isEmpty) {
      return Skeleton.react(width: double.infinity, height: 250, borderRadius: BorderRadius.zero);
    }
    return SwiperBanner(height: 250, borderRadius: 0, banners: banners!);
  }
}

/// 头部宝藏区 top treasure section skeleton
class _TopTreasureSectionSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
      child: Skeleton.react(
        width: double.infinity,
        height: 220.w,
        borderRadius: BorderRadius.circular(8.w),
      ),
    );
  }
}

/// 头部宝藏区 top treasure section
class _TopTreasureSection extends StatefulWidget {
  final ProductListItem? item;
  final String? url;

  const _TopTreasureSection({this.item, this.url});

  @override
  State<_TopTreasureSection> createState() => _TopTreasureSectionState();
}

class _TopTreasureSectionState extends State<_TopTreasureSection> {
  final sharePosterKey = GlobalKey<SharePostState>();

  void openShareSheet(BuildContext context, ShareData data) {
    ShareService.openSystemOrSheet(
      ShareData(
        title: data.title,
        url: data.url,
        text: data.title,
        imageUrl: data.imageUrl,
      ),
      () async {
        RadixSheet.show(
          headerBuilder: (context) => Padding(
            padding: EdgeInsets.only(bottom: 20.w),
            child: SharePost(
              key: sharePosterKey,
              data: ShareData(
                title: data.title,
                url: data.url,
                imageUrl: data.imageUrl,
                text: data.text,
                subTitle: data.subTitle,
              ),
            ),
          ),
          builder: (context, close) {
            return ShareSheet(
              data: ShareData(title: data.title, url: data.url),
              onDownloadPoster: () async {
                sharePosterKey.currentState?.saveToGallery();
                close();
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item.isNullOrEmpty) {
      return _TopTreasureSectionSkeleton();
    }

    final data = widget.item!;

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
                onTap: () {
                  openShareSheet(
                    context,
                    ShareData(
                      title: data.treasureName,
                      url: '${widget.url}/product/${data.treasureId}',
                      imageUrl: data.treasureCoverImg,
                      text: FormatHelper.formatCurrency(data.unitAmount),
                      subTitle: 'common.cash.value'.tr(
                        namedArgs: {
                          'number': FormatHelper.formatCurrency(
                            data.costAmount,
                          ),
                        },
                      ),
                    ),
                  );
                },
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
                    data.treasureName,
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
                      FormatHelper.formatCurrency(data.unitAmount),
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  SizedBox(height: 16.w),
                  BubbleProgress(value: data.buyQuantityRate),
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
                        '${data.seqBuyQuantity}${'entries-sold'.tr()}',
                        style: TextStyle(
                          fontSize: context.text2xs,
                          color: context.textSecondary700,
                          height: context.leading2xs,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${data.seqShelvesQuantity}',
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
                            '${data.maxPerBuyQuantity ?? 0}Max',
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
                            '${data.maxPerBuyQuantity ?? 0}Max',
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
                            FormatHelper.formatCurrency(data.costAmount ?? 0),
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
                              num.parse(data.charityAmount ?? '0'),
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

/// 组队区 group section
class _GroupSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.w,
                      ),
                      decoration: BoxDecoration(
                        color: context.utilityBrand50,
                        borderRadius: BorderRadius.all(
                          Radius.circular(context.radiusFull),
                        ),
                        border: Border.fromBorderSide(
                          BorderSide(
                            color: context.utilityBrand200,
                            width: 1.w,
                          ),
                        ),
                      ),
                      child: Text(
                        'common.users'.tr(namedArgs: {'number': '1234'}),
                        style: TextStyle(
                          fontSize: context.text2xs,
                          color: context.utilityBrand700,
                          fontWeight: FontWeight.w500,
                          height: context.leadingXs,
                        ),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: SvgPicture.asset(
                    'assets/images/product_detail/goto.svg',
                    width: 16.w,
                    height: 16.w,
                    colorFilter: ColorFilter.mode(
                      context.fgPrimary900,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 参与宝藏区 join treasure section
class _JoinTreasureSection extends ConsumerWidget {
  final String? treasureId;
  final String? groupId;
  final PurchaseArgs? args;

  const _JoinTreasureSection({this.args, this.treasureId, this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (args.isNullOrEmpty) return SizedBox.shrink();

    final purchase = ref.watch(purchaseProvider(args!));
    final action = ref.read(purchaseProvider(args!).notifier);

    return Container(
      padding: EdgeInsets.only(bottom: ViewUtils.bottomBarHeight),
      decoration: BoxDecoration(color: context.bgPrimary),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
            decoration: BoxDecoration(
              color: context.bgSecondary,
              border: Border(
                top: BorderSide(color: context.borderSecondary, width: 1.w),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'common.treasure.coin'.tr(),
                      style: TextStyle(
                        fontSize: context.textSm,
                        color: context.textSecondary700,
                        height: context.leadingSm,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        text: 'common.node.use.up.prefix'.tr(),
                        style: TextStyle(
                          fontSize: context.textSm,
                          color: context.textTertiary600,
                          height: context.leadingSm,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: '${purchase.coinsToUse}',
                            style: TextStyle(
                              color: context.textErrorPrimary600,
                            ),
                          ),
                          TextSpan(text: 'common.node.use.up.suffix'.tr()),
                        ],
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Text(
                  '-${FormatHelper.formatCurrency(purchase.coinAmount)}',
                  style: TextStyle(
                    fontSize: context.textXs,
                    color: context.textBrandSecondary700,
                    height: context.leadingXs,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
            decoration: BoxDecoration(
              color: context.bgPrimary,
              border: Border(
                top: BorderSide(color: context.borderSecondary, width: 1.w),
              ),
            ),
            child: _Stepper(
              treasureId: treasureId ?? '',
              groupId: groupId,
              args: args!,
            ),
          ),
        ],
      ),
    );
  }
}

/// 数量步进器 stepper
class _Stepper extends ConsumerStatefulWidget {
  final String treasureId;
  final String? groupId;
  final PurchaseArgs args;

  const _Stepper({
    required this.treasureId,
    this.groupId,
    required this.args,
  });

  @override
  ConsumerState<_Stepper> createState() => _StepperState();
}

/// 数量步进器 state
class _StepperState extends ConsumerState<_Stepper> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final purchase = ref.read(purchaseProvider(widget.args));
    _controller = TextEditingController(text: '${purchase.entries}');
  }

  @override
  void didUpdateWidget(covariant _Stepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // when parent args change, update controller text
    if (oldWidget.args != widget.args) {
      final purchase = ref.read(purchaseProvider(widget.args));
      _controller.value = TextEditingValue(
        text: '${purchase.entries}',
        selection: TextSelection.collapsed(offset: '${purchase.entries}'.length),
      );
    }
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchase = ref.watch(purchaseProvider(widget.args));
    final expectedText = '${purchase.entries}';
    // keep controller text in sync with state
    if (_controller.text != expectedText) {
      _controller.value = TextEditingValue(
        text: expectedText,
        selection: TextSelection.collapsed(offset: expectedText.length),
      );
    }


    final action = ref.read(purchaseProvider(widget.args).notifier);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Button(
              disabled: purchase.entries <= math.max(0, widget.args.minPerBuy),
              width: 44.w,
              height: 44.w,
              variant: ButtonVariant.outline,
              onPressed: action.dec,
              child: Icon(Icons.remove, size: 24.w),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                height: 44.w,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.w),
                decoration: BoxDecoration(
                  color: context.buttonSecondaryBg,
                  border: Border.all(
                    color: context.borderSecondary,
                    width: 1.w,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(context.radiusSm),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.bgDisabled,
                      offset: Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) {
                    if (v.isEmpty) {
                      action.setEntriesFromText(math.max(0, purchase.minPerBuy).toString());
                      return;
                    }

                    final raw = int.tryParse(v);
                    if (raw == null) {
                      final fixed = purchase.entries;
                      _controller.value = TextEditingValue(
                        text: '$fixed',
                        selection: TextSelection.collapsed(
                          offset: '$fixed'.length,
                        ),
                      );
                      return;
                    }

                    int clamped = raw.clamp(0, purchase.stockLeft);

                    if (clamped != raw) {
                      _controller.value = TextEditingValue(
                        text: '$clamped',
                        selection: TextSelection.collapsed(
                          offset: '$clamped'.length,
                        ),
                      );
                    }
                    action.setEntriesFromText('$clamped');
                  },
                  style: TextStyle(
                    fontSize: context.textMd,
                    color: context.fgPrimary900,
                    height: context.leadingMd,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Button(
              disabled: purchase.entries >= purchase.stockLeft,
              width: 44.w,
              height: 44.w,
              variant: ButtonVariant.outline,
              onPressed: action.inc,
              child: Icon(Icons.add, size: 24.w),
            ),
          ],
        ),
        // todo <span>{group_id ? `${t('common.join.group')}` : `${t('common.form.group')}`}</span>
        SizedBox(height: 20.w),
        Button(
          disabled: purchase.entries <= 0,
          width: double.infinity,
          paddingX: 18.w,
          alignment: MainAxisAlignment.spaceBetween,
          onPressed: () {
              appRouter.pushNamed(
                'payment',
                queryParameters: {
                  'entries': '${purchase.entries}',
                   'treasureId': widget.treasureId,
                    if (widget.groupId != null) 'groupId': widget.groupId!,
                }
              );
          },
          trailing: AnimeCount.odo(
            value: purchase.entries,
            textStyle: TextStyle(
              fontSize: context.textMd,
              color: context.fgPrimary900,
              height: context.leadingMd,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: Text('common.join.group'.tr()),
        ),
      ],
    );
  }
}
