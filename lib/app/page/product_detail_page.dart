import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/components/share_sheet.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/components/swiper_banner.dart';
import 'package:flutter_app/core/models/groups.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/core/providers/purchase_state_provider.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_app/features/share/index.dart';
import 'package:flutter_app/ui/animations/rolling_number.dart';
import 'package:flutter_app/ui/bubble_progress.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/ui/modal/index.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Product Detail Page
/// ------------------------------------------------------------------
/// Displays detailed information about a product
/// Features:
/// - Banner carousel
/// - Coupon section
/// - Top treasure section with share functionality
/// - Group section
/// - Detail content with tabs
/// - Animated bottom bar for joining treasure
/// ------------------------------------------------------------------
/// Usage:
/// dart
/// Navigator.pushNamed(context, AppRouter.productDetail, arguments: {'productId': '12345'});
/// ------------------------------------------------------------------
/// Parameters:
/// - productId: String - ID of the product to display
/// ------------------------------------------------------------------
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

  // stable key for banner storage
  late final PageStorageKey _bannerStorageKey;
  late final PageStorageKey _pageStorageKey;

  @override
  void initState() {
    super.initState();

    _bannerStorageKey = PageStorageKey(
      'product_detail_banner_${widget.productId}',
    );
    _pageStorageKey = PageStorageKey('product_detail_page_${widget.productId}');

    // Initialize animation controller
    _bottomBarController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _opacityBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bottomBarController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    // Define offset animation,set to slide in from bottom
    _offsetBarAnimation = Tween<Offset>(begin: Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _bottomBarController,
            curve: Curves.easeOutCubic,
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
    // product detail
    final detail = ref.watch(productDetailProvider(widget.productId));
    final webBaseUrl = ref.watch(
      luckyProvider.select((select) => select.sysConfig.webBaseUrl),
    );

    final expandedHeight = 250.w;
    
    return detail.when(
      data: (detail) {
        return Scaffold(
          body: CustomScrollView(
            key: _pageStorageKey,
            slivers: [
              // Banner section
              SliverAppBar(
                pinned: true,
                floating: false,
                expandedHeight: expandedHeight,
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
                flexibleSpace: LayoutBuilder(
                  builder: (context, constrain) {
                    final currentHeight = constrain.biggest.height;
                    final minHeight =
                        MediaQuery.of(context).padding.top + kToolbarHeight;

                    // Calculate the interpolation factor t
                    // use currentHeight, minHeight, expandedHeight to calculate t
                    final t =
                        ((currentHeight - minHeight) /
                                (expandedHeight - minHeight))
                            .clamp(0.0, 1.0);
                    final titleOpacity = (1.0 - t) >= 0.9 ? 1.0 : 0.0;

                    return Stack(
                      // tell children who don't use positioned to expand to fill the stack
                      fit: StackFit.expand,
                      children: [
                        Opacity(
                          opacity: t,
                          child: _BannerSection(
                            banners: detail.mainImageList,
                            storageKey: _bannerStorageKey,
                            height: expandedHeight,
                          ),
                        ),
                        titleOpacity > 0
                            ? Positioned(
                                left: 56.w,
                                right: 16.w,
                                top:
                                    MediaQuery.of(context).padding.top +
                                    (kToolbarHeight - 25.w) / 2,
                                child: Opacity(
                                  opacity: titleOpacity,
                                  child: Text(
                                    detail.treasureName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: context.textMd,
                                      fontWeight: FontWeight.w700,
                                      color: context.fgPrimary900,
                                    ),
                                  ),
                                ),
                              )
                            : SizedBox.shrink(),
                      ],
                    );
                  },
                ),
              ),
              // Coupon section
              SliverToBoxAdapter(child: _CouponSection()),
              // Top treasure section
              SliverToBoxAdapter(
                child: _TopTreasureSection(item: detail, url: webBaseUrl),
              ),
              // Group section
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: _GroupSection(treasureId: detail.treasureId),
                ),
              ),
              // Detail content section
              SliverToBoxAdapter(child: SizedBox(height: 8.w)),
              // Detail content section，rules and details
              SliverToBoxAdapter(
                child: _DetailContentSection(ruleContent: detail.ruleContent, desc: detail.desc),
              ),
            ],
          ),
          bottomNavigationBar: AnimatedPadding(
            padding: EdgeInsets.only(
              // Adapt to keyboard height
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            curve: Curves.easeOut,
            duration: Duration(milliseconds: 200),
            child: FadeTransition(
              opacity: _opacityBarAnimation,
              child: SlideTransition(
                position: _offsetBarAnimation,
                child: _JoinTreasureSection(
                  treasureId: detail.treasureId,
                  groupId: widget.queryParams['groupId'] ?? '',
                ),
              ),
            ),
          ),
        );
      },
      error: (_, __) {
        return _ProductDetailSkeleton();
      },
      loading: () {
        return _ProductDetailSkeleton();
      },
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
  final String? ruleContent;
  final String? desc;

  const _DetailContentSection({this.ruleContent, this.desc});

  @override
  State<_DetailContentSection> createState() => _DetailContentSectionState();
}

/// 详情内容区 state
class _DetailContentSectionState extends State<_DetailContentSection>
    with SingleTickerProviderStateMixin {
  List<TabItem> get tabs => [
    TabItem(text: 'common.details', content: widget.desc),
    TabItem(text: 'raffle-rules', content: widget.ruleContent),
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
  final PageStorageKey? storageKey;
  final double? height;

  const _BannerSection({
    required this.banners,
    this.storageKey,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (banners == null || banners!.isEmpty) {
      return Skeleton.react(
        width: double.infinity,
        height: 250,
        borderRadius: BorderRadius.zero,
      );
    }
    return SwiperBanner(
      height: height ?? 250.w,
      borderRadius: 0,
      banners: banners!,
      storageKey: storageKey,
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

class _TopTreasureSectionState extends State<_TopTreasureSection>
    with SingleTickerProviderStateMixin {
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
                HapticFeedback.mediumImpact();
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
                      subTitle:
                          '${'common.cash.value'.tr()}：${FormatHelper.formatCurrency(data.costAmount)}',
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
                            FormatHelper.formatCurrency(data.charityAmount),
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
    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 20.w),
      child: SizedBox(
        height: 22.w,
        child: Row(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(2, (index) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.w),
                    border: Border.fromBorderSide(
                      BorderSide(color: context.utilityBrand200, width: 1.w),
                    ),
                    color: context.utilityBrand50,
                  ),
                  child: Text(
                    'new user coming',
                    style: TextStyle(
                      fontSize: context.textXs,
                      color: context.utilityBrand700,
                      fontWeight: FontWeight.w500,
                      height: context.leadingXs,
                    ),
                  ),
                );
              }),
            ),
            Spacer(),
            Button(
              variant: ButtonVariant.text,
              paddingX: 0,
              onPressed: () {},
              child: Icon(
                Icons.chevron_right,
                size: 24.w,
                color: context.fgErrorPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupSection extends ConsumerStatefulWidget {
  final String treasureId;

  const _GroupSection({required this.treasureId});

  @override
  ConsumerState<_GroupSection> createState() => _GroupSectionState();
}

/// 组队区 group section
class _GroupSectionState extends ConsumerState<_GroupSection>
    with AutomaticKeepAliveClientMixin {
  int page = 1; // target page
  int showPage = 1; // currently displayed page
  final Map<int, PageResult<GroupForTreasureItem>> _cache = <int, PageResult<GroupForTreasureItem>>{};

  @override
  bool get wantKeepAlive => true;

  void next() {
    setState(() => page = page + 1);
  }

  void prev() {
    if (page <= 1) return;
    setState(() => page = page - 1);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final params = GroupsListRequestParams(
      page: page,
      treasureId: widget.treasureId,
    );
    final groups = ref.watch(groupsListProvider(params));
    groups.whenData((d) {
      _cache[d.page] = d;
      if (d.page == page && showPage != page && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              showPage = d.page;
            });
          }
        });
      }
    });

    final data = _cache[showPage];

    // first load
    if (data == null) {
      return _GroupSectionSkeleton();
    }


    // no data
    if(data.list.isEmpty){
      return SizedBox.shrink();
    }

    final total = totalPages(data.total, data.pageSize);
    final hasNext = hasMore(data.total, showPage, data.pageSize);
    final int startNo = (showPage - 1) * data.pageSize + 1;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        height: 590.w,
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.bgPrimary,
          border: Border.all(color: context.borderPrimary, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(context.radiusMd)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
              child: Row(
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
                          'common.users'.tr(namedArgs: {'number': data.total.toString()}),
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
                    onTap: () {
                      appRouter.push('/product/${widget.treasureId}/group');
                    },
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      alignment: Alignment.centerRight,
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
                  )
                ],
              ),
            ),
            Column(
              children: List.generate(data.list.length, (index){
                 final isEven = index % 2 == 0;
                final item = data.list[index];
                final no = startNo + index;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                   appRouter.push('/group-member?groupId=${item.groupId}');
                  },
                  child: Container(
                    width: double.infinity,
                    height: 72.w,
                    decoration: BoxDecoration(
                      color: context.bgPrimary,
                      border: Border(
                        bottom: BorderSide(
                          color: context.borderSecondary,
                          width: 1.w,
                        ),
                      ),
                      gradient: isEven
                          ? LinearGradient(
                        colors: [
                          context.alphaBlack2.withValues(alpha: 0.02),
                          context.alphaBlack2,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                          : null,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        children: [
                          Text(
                            '#$no',
                            style: TextStyle(
                              fontSize: context.textSm,
                              color: context.fgPrimary900,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 20.w),
                          CachedNetworkImage(
                            imageUrl: item.creator.avatar ?? '',
                            width: 40.w,
                            height: 40.w,
                            memCacheHeight: (40.w * ViewUtils.dpr).toInt(),
                            memCacheWidth: (40.w * ViewUtils.dpr).toInt(),
                            errorWidget: (context, url, error) => Container(
                              width: 40.w,
                              height: 40.w,
                              decoration: BoxDecoration(
                                color: context.bgSecondary,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.w),
                                ),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 24.w,
                                color: context.fgQuaternary500,
                              ),
                            ),
                            placeholder: (_, __) =>
                                Skeleton.circle(width: 40.w, height: 40.w),
                          ),
                          Text(
                            item.creator.nickname ?? '---',
                            style: TextStyle(
                              fontSize: context.textSm,
                              color: context.fgPrimary900,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.chevron_right,
                            size: 16.w,
                            color: context.fgQuinary400,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
              child: Row(
                children: [
                  Button(
                    height: 36.w,
                    alignment: MainAxisAlignment.center,
                    variant: ButtonVariant.outline,
                    onPressed: groups.isLoading || showPage <= 1 ? null : prev,
                    child: Icon(
                      Icons.arrow_back,
                      size: 20.w,
                      color: context.fgPrimary900,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Page $showPage of $total',
                    style: TextStyle(
                      fontSize: context.textSm,
                      color: context.fgPrimary900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Spacer(),
                  Button(
                    height: 36.w,
                    alignment: MainAxisAlignment.center,
                    variant: ButtonVariant.outline,
                    onPressed: groups.isLoading || !hasNext ? null : next,
                    child: Icon(
                      Icons.arrow_forward,
                      size: 20.w,
                      color: context.fgPrimary900,
                    ),
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

/// 参与宝藏区 join treasure section
class _JoinTreasureSection extends ConsumerWidget {
  final String treasureId;
  final String? groupId;

  const _JoinTreasureSection({required this.treasureId, this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
     ref.watch(purchaseProvider(treasureId));
    final notifier = ref.read(purchaseProvider(treasureId).notifier);

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
                            text: '${notifier.coinsCanUse}',
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
                  '-${FormatHelper.formatCurrency(notifier.coinAmount)}',
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
            child: _Stepper(treasureId: treasureId, groupId: groupId),
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

  const _Stepper({required this.treasureId, this.groupId});

  @override
  ConsumerState<_Stepper> createState() => _StepperState();
}

/// 数量步进器 state
class _StepperState extends ConsumerState<_Stepper> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    final purchase = ref.read(purchaseProvider(widget.treasureId));
    _controller = TextEditingController(text: '${purchase.entries}');
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _commitText();
    }
  }

  void _commitText() {
    final action = ref.read(purchaseProvider(widget.treasureId).notifier);
    final purchase = ref.read(purchaseProvider(widget.treasureId));

    var text = _controller.text.toString();

    if (text.isEmpty ||
        int.tryParse(text) == null ||
        int.parse(text) < purchase.minBuyQuantity) {
      text = purchase.minBuyQuantity.toString();
    }

    action.setEntriesFromText(text);
    final updated = ref.read(purchaseProvider(widget.treasureId)).entries;
    updateControllerText(updated);
  }

  void updateControllerText(int value) {
    final expected = '$value';
    _controller.value = TextEditingValue(
      text: expected,
      selection: TextSelection.collapsed(offset: expected.length),
    );
  }

  @override
  dispose() {
    _controller.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchase = ref.watch(purchaseProvider(widget.treasureId));

    final action = ref.read(purchaseProvider(widget.treasureId).notifier);

    if (!_focusNode.hasFocus) {
      final expected = '${purchase.entries}';
      if (_controller.text != expected) {
        _controller.value = TextEditingValue(
          text: expected,
          selection: TextSelection.collapsed(offset: expected.length),
        );
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Button(
              width: 44.w,
              height: 44.w,
              variant: ButtonVariant.outline,
              onPressed: () {
                action.dec(updateControllerText);
              },
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
                  focusNode: _focusNode,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    action.setEntriesFromText(value);
                  },
                  onTapOutside: (v) {
                    FocusScope.of(context).unfocus();
                  },
                  onEditingComplete: () {
                    FocusScope.of(context).unfocus();
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
              width: 44.w,
              height: 44.w,
              variant: ButtonVariant.outline,
              onPressed: () {
                action.inc(updateControllerText);
              },
              child: Icon(Icons.add, size: 24.w),
            ),
          ],
        ),
        // todo <span>{group_id ? `${t('common.join.group')}` : `${t('common.form.group')}`}</span>
        SizedBox(height: 20.w),
        Button(
          disabled: purchase.stockLeft <= 0,
          width: double.infinity,
          paddingX: 18.w,
          height: 44.w,
          alignment: MainAxisAlignment.spaceBetween,
          onPressed: () {
            appRouter.pushNamed(
              'payment',
              queryParameters: {
                'entries': '${purchase.entries}',
                'treasureId': widget.treasureId,
                'paymentMethod': '1',
                if (widget.groupId != null) 'groupId': widget.groupId!,
              },
            );
          },
          trailing: RollingNumber(
            value: purchase.subtotal,
            fractionDigits: 2,
            itemHeight: 24.w,
            enableComma: true,
            prefix: Text(
              '₱',
              style: TextStyle(
                fontSize: context.textSm,
                color: context.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          child: Text('common.join.group'.tr()),
        ),
      ],
    );
  }
}

class _ProductDetailSkeleton extends StatelessWidget {
  const _ProductDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BannerSectionSkeleton(),
                _CouponSectionSkeleton(),
                _TopSectionSkeleton(),
                _GroupSectionSkeleton(),
                _DetailContentSectionSkeleton(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _JoinTreasureSectionSkeleton(),
    );
  }
}

class _BannerSectionSkeleton extends StatelessWidget {
  const _BannerSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton.react(
      width: double.infinity,
      height: 276.w,
      borderRadius: BorderRadius.circular(8.w),
    );
  }
}

class _CouponSectionSkeleton extends StatelessWidget {
  const _CouponSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 20.w),
      child: SizedBox(
        height: 22.w,
        child: Row(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(4, (index) {
                return Container(
                  width: 60.w,
                  height: 22.w,
                  margin: EdgeInsets.only(right: 8.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.w),
                  ),
                  child: Skeleton.react(
                    width: 60.w,
                    height: 22.w,
                    borderRadius: BorderRadius.circular(6.w),
                  ),
                );
              }),
            ),
            Spacer(),
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.w),
              ),
              child: Skeleton.react(
                width: 24.w,
                height: 24.w,
                borderRadius: BorderRadius.circular(12.w),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopSectionSkeleton extends StatelessWidget {
  const _TopSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.w),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.bgPrimary,
          border: Border.all(color: context.borderPrimary, width: 1.w),
          borderRadius: BorderRadius.all(Radius.circular(context.radiusMd)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Skeleton.react(
                    width: double.infinity,
                    height: 24.w,
                    borderRadius: BorderRadius.circular(4.w),
                  ),
                  SizedBox(height: 8.w),
                  Skeleton.react(
                    width: 100.w,
                    height: 20.w,
                    borderRadius: BorderRadius.circular(4.w),
                  ),
                  SizedBox(height: 16.w),
                  Skeleton.react(
                    width: double.infinity,
                    height: 16.w,
                    borderRadius: BorderRadius.circular(4.w),
                  ),
                  SizedBox(height: 10.w),
                  Skeleton.react(
                    width: 100.w,
                    height: 10.w,
                    borderRadius: BorderRadius.circular(4.w),
                  ),
                  SizedBox(height: 20.w),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Skeleton.circle(width: 24.w, height: 24.w),
                          SizedBox(height: 8.w),
                          Skeleton.react(
                            width: 40.w,
                            height: 14.w,
                            borderRadius: BorderRadius.circular(4.w),
                          ),
                          SizedBox(height: 4.w),
                          Skeleton.react(
                            width: 40.w,
                            height: 14.w,
                            borderRadius: BorderRadius.circular(4.w),
                          ),
                        ],
                      );
                    }),
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

class _GroupSectionSkeleton extends StatelessWidget {
  const _GroupSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.w),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.bgPrimary,
          border: Border.all(color: context.borderPrimary, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(context.radiusMd)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Skeleton.react(
                    width: 120.w,
                    height: 20.w,
                    borderRadius: BorderRadius.circular(4.w),
                  ),
                  Skeleton.react(
                    width: 16.w,
                    height: 16.w,
                    borderRadius: BorderRadius.circular(8.w),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 72.w * 6,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemExtent: 72.w,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      children: [
                        Skeleton.react(
                          width: 40.w,
                          height: 20.w,
                          borderRadius: BorderRadius.circular(4.w),
                        ),
                        SizedBox(width: 20.w),
                        Skeleton.circle(width: 40.w, height: 40.w),
                        Spacer(),
                        Skeleton.react(
                          width: 80.w,
                          height: 20.w,
                          borderRadius: BorderRadius.circular(4.w),
                        ),
                        Spacer(),
                        Skeleton.react(
                          width: 16.w,
                          height: 16.w,
                          borderRadius: BorderRadius.circular(8.w),
                        ),
                      ],
                    ),
                  );
                },
                itemCount: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailContentSectionSkeleton extends StatelessWidget {
  const _DetailContentSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.bgPrimary,
          border: Border.all(color: context.borderPrimary, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(context.radiusMd)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Skeleton.react(
                    width: 120.w,
                    height: 20.w,
                    borderRadius: BorderRadius.circular(0),
                  ),
                  Skeleton.react(
                    width: 120.w,
                    height: 20.w,
                    borderRadius: BorderRadius.circular(0),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Skeleton.react(
                width: double.infinity,
                height: 200.w,
                borderRadius: BorderRadius.circular(4.w),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: List.generate(5, (index) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.w),
                    child: Skeleton.react(
                      width: double.infinity,
                      height: 16.w,
                      borderRadius: BorderRadius.circular(4.w),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinTreasureSectionSkeleton extends StatelessWidget {
  const _JoinTreasureSectionSkeleton();

  @override
  Widget build(BuildContext context) {
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
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Skeleton.react(
                  width: 40.w,
                  height: 40.w,
                  borderRadius: BorderRadius.circular(4.w),
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: Skeleton.react(
                    width: double.infinity,
                    height: 40.w,
                    borderRadius: BorderRadius.circular(4.w),
                  ),
                ),
                SizedBox(width: 20.w),
                Skeleton.react(
                  width: 40.w,
                  height: 40.w,
                  borderRadius: BorderRadius.circular(4.w),
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
            child: Skeleton.react(
              width: double.infinity,
              height: 44.w,
              borderRadius: BorderRadius.circular(8.w),
            ),
          ),
        ],
      ),
    );
  }
}
