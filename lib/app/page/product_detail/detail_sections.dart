import 'dart:async';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/img/app_image.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// --- Core Dependencies ---
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/components/swiper_banner.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/ui/bubble_progress.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/utils/format_helper.dart';

import 'package:flutter_app/core/models/groups.dart';
import 'package:flutter_app/core/providers/coupon_provider.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/button/variant.dart';
import 'package:flutter_app/ui/modal/sheet/radix_sheet.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';

// ==========================================
// 1. Banner Section (Image Carousel)
// ==========================================
class BannerSection extends StatelessWidget {
  final List<String>? banners;
  final PageStorageKey? storageKey;
  final double? height;

  const BannerSection({
    super.key,
    required this.banners,
    this.storageKey,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (banners == null || banners!.isEmpty) {
      return Skeleton.react(
        width: double.infinity,
        height: 250.h,
        borderRadius: BorderRadius.zero,
      );
    }
    return SwiperBanner(
      width: 375.w,
      height: height ?? 250.h,
      borderRadius: 0,
      banners: banners!,
      storageKey: storageKey,
    );
  }
}

// ==========================================
// 2. Coupon Section (Entry point for claiming)
// ==========================================
class CouponSection extends ConsumerWidget {
  const CouponSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimableAsync = ref.watch(claimableCouponsProvider);

    return claimableAsync.when(
      // Banners 核心优化：防闪烁
      skipLoadingOnRefresh: true,
      data: (coupons) {
        if (coupons.isEmpty) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            RadixSheet.show(
              title: 'Available Coupons',
              builder: (context, close) => _ClaimCouponBottomSheet(
                coupons: coupons,
                onClose: close,
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.only(top: 8.w),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
            color: context.bgPrimary,
            child: Row(
              children: [
                Text(
                  'product_detail.section_coupon'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondary700,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Wrap(
                    spacing: 8.w,
                    runSpacing: 4.w,
                    children: coupons.take(2).map((c) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
                      decoration: BoxDecoration(
                        color: Colors.pink[50],
                        borderRadius: BorderRadius.circular(4.w),
                        border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Save ₱${c.discountValue ?? 0}',
                        style: TextStyle(fontSize: 10.sp, color: Colors.pinkAccent, fontWeight: FontWeight.bold),
                      ),
                    )).toList(),
                  ),
                ),
                Icon(CupertinoIcons.chevron_right, size: 16.w, color: context.textQuaternary500),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// =========================================================================
// 2.1 UI: Bottom Sheet for Claiming Coupons
// =========================================================================
class _ClaimCouponBottomSheet extends ConsumerStatefulWidget {
  final List<dynamic> coupons;
  final VoidCallback onClose;

  const _ClaimCouponBottomSheet({
    required this.coupons,
    required this.onClose,
  });

  @override
  ConsumerState<_ClaimCouponBottomSheet> createState() => _ClaimCouponBottomSheetState();
}

class _ClaimCouponBottomSheetState extends ConsumerState<_ClaimCouponBottomSheet> {
  String? _loadingCouponId;

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(couponActionProvider);
    final isActionLoading = actionState is AsyncLoading;
    final maxContentHeight = MediaQuery.of(context).size.height * 0.7;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxContentHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.coupons.length,
              itemBuilder: (context, index) {
                final item = widget.coupons[index];
                final bool isClaimed = item.hasReachedLimit == true;
                final bool isSoldOut = (item.canClaim == false) && (item.hasReachedLimit != true);

                String btnText = 'Claim';
                if (isSoldOut) btnText = 'Sold Out';
                else if (isClaimed) btnText = 'Claimed';

                final bool isThisLoading = _loadingCouponId == item.couponId;
                bool isBtnDisabled = isClaimed || isSoldOut || isActionLoading;

                return Container(
                  margin: EdgeInsets.only(bottom: 12.w),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: context.bgPrimary,
                    borderRadius: BorderRadius.circular(8.w),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.couponName ?? 'Platform Voucher',
                              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: context.textPrimary900),
                            ),
                            SizedBox(height: 4.w),
                            Text(
                              'Min. Spend ₱${item.minPurchase}',
                              style: TextStyle(fontSize: 12.sp, color: context.textSecondary700),
                            ),
                            SizedBox(height: 8.w),
                            Text(
                              '- ₱${item.discountValue}',
                              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: context.textBrandPrimary900),
                            ),
                            if (!isSoldOut) ...[
                              SizedBox(height: 8.w),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4.w),
                                child: LinearProgressIndicator(
                                  value: (double.tryParse('${item.progress ?? 0}') ?? 0) / 100,
                                  minHeight: 4.w,
                                  backgroundColor: Colors.pink[50],
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                                ),
                              ),
                              SizedBox(height: 4.w),
                              Text(
                                '${item.progress}% Claimed',
                                style: TextStyle(fontSize: 10.sp, color: Colors.pinkAccent),
                              ),
                            ]
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Button(
                        width: 80.w,
                        height: 32.h,
                        disabled: isBtnDisabled,
                        loading: isThisLoading,
                        variant: (isClaimed || isSoldOut) ? ButtonVariant.outline : ButtonVariant.primary,
                        onPressed: () async {
                          if (isBtnDisabled) return;
                          setState(() => _loadingCouponId = item.couponId);
                          try {
                            await ref.read(couponActionProvider.notifier).claim(item.couponId);
                            ref.invalidate(claimableCouponsProvider);
                            ref.invalidate(myValidCouponsProvider);
                            RadixToast.success('Claimed successfully!');
                          } catch (e) {
                            RadixToast.error('Failed to claim');
                          } finally {
                            if (mounted) setState(() => _loadingCouponId = null);
                          }
                        },
                        child: Text(
                          btnText,
                          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. Top Treasure Info Section (Core info area)
// ==========================================
class TopTreasureSection extends StatelessWidget {
  final ProductListItem item;
  final TreasureStatusModel? realTimeItem;
  final String? url;

  const TopTreasureSection({
    super.key,
    required this.item,
    this.realTimeItem,
    this.url,
  });

  @override
  Widget build(BuildContext context) {
    final double marketPrice = item.marketAmount ?? double.tryParse(item.costAmount ?? '0') ?? 0;
    final double currentPrice = realTimeItem?.price ?? item.unitAmount ?? 0;
    final int sold = item.seqBuyQuantity ?? 0;
    final int totalStock = item.seqShelvesQuantity ?? 0;
    final int left = realTimeItem?.stock ?? (totalStock - sold);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: context.bgPrimary,
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.treasureName ?? 'home_group.fallback_product_name'.tr(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary900,
                      height: 1.3,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () {},
                  child: Padding(
                    padding: EdgeInsets.only(top: 2.w),
                    child: SvgPicture.asset(
                      'assets/images/product_detail/share.svg',
                      width: 20.w,
                      colorFilter:  ColorFilter.mode(context.textPrimary900, BlendMode.srcIn),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  FormatHelper.formatCurrency(currentPrice),
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFFF4D4F),
                    height: 1.0,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4D4F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    '${item.groupSize ?? 5}${'product_detail.group_size_suffix'.tr()}',
                    style: TextStyle(
                        fontSize: 10.sp,
                        color: const Color(0xFFFF4D4F),
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                const Spacer(),
                if (marketPrice > currentPrice)
                  Text(
                    FormatHelper.formatCurrency(marketPrice),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.textErrorPrimary600,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            BubbleProgress(value: item.buyQuantityRate ?? 0),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$sold${'product_detail.suffix_sold'.tr()}',
                  style: TextStyle(fontSize: 11.sp, color: context.textSecondary700),
                ),
                Text(
                  '${'product_detail.prefix_only'.tr()}$left${'product_detail.suffix_left'.tr()}',
                  style: TextStyle(fontSize: 11.sp, color: const Color(0xFFFF4D4F), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. Group Section (Active Groups List)
// ==========================================
class GroupSection extends ConsumerStatefulWidget {
  final String treasureId;

  const GroupSection({super.key, required this.treasureId});

  @override
  ConsumerState<GroupSection> createState() => _GroupSectionState();
}

class _GroupSectionState extends ConsumerState<GroupSection> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      ref.invalidate(groupsPreviewProvider(widget.treasureId));
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsPreviewProvider(widget.treasureId));

    return groupsAsync.when(
      // Banners 核心优化 1：无痕静默刷新！彻底消灭 15 秒闪屏一次的恶心 Bug
      skipLoadingOnRefresh: true,
      data: (groups) {
        if (groups.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Container(
            decoration: BoxDecoration(
              color: context.bgPrimary,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (widget.treasureId.isNotEmpty) {
                      appRouter.pushNamed('product-groups-detail', queryParameters: {'treasureId': widget.treasureId});
                    } else {
                      appRouter.pushNamed('groups');
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${groups.length}${'product_detail.suffix_people_joining'.tr()}',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.sp,
                              color: context.textPrimary900
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                                'product_detail.btn_view_all'.tr(),
                                style: TextStyle(fontSize: 11.sp, color: context.textSecondary700)
                            ),
                            Icon(Icons.chevron_right, size: 16.w, color: context.textSecondary700),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                ...groups.take(2).map((item) => _buildActiveGroupItem(context, item)),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        );
      },
      error: (_, __) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }

  Widget _buildActiveGroupItem(BuildContext context, GroupForTreasureItem item) {
    final int endTime = item.expireAt;

    return Container(
      key: ValueKey(item.groupId),
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: context.bgSecondary,
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        children: [
          AppCachedImage(
            item.creator.avatar ?? '',
            width: 32.w,
            height: 32.w,
            radius: BorderRadius.circular(16.r),
            fit: BoxFit.cover,
            error: Icon(FontAwesomeIcons.user, size: 16.w, color: Colors.white),
            placeholder: Icon(FontAwesomeIcons.user, size: 16.w, color: Colors.white),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.creator.nickname ?? 'group_lobby.default_user'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${'product_detail.short_of_prefix'.tr()}${item.maxMembers - item.currentMembers}${'product_detail.short_of_suffix'.tr()}',
                  style: TextStyle(fontSize: 10.sp, color: const Color(0xFFFF4D4F)),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CountdownTimer(
                  endTime: endTime,
                  widgetBuilder: (_, time) {
                    if (time == null) return Text('product_detail.status_ended'.tr(), style: TextStyle(fontSize: 10.sp, color: context.textSecondary700));
                    String pad(int? n) => (n ?? 0).toString().padLeft(2, '0');
                    return Text(
                      '${pad(time.hours)}:${pad(time.min)}:${pad(time.sec)}',
                      style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey,
                          fontFeatures: const [FontFeature.tabularFigures()]
                      ),
                    );
                  },
                ),
                SizedBox(height: 2.h),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (DateTime.now().millisecondsSinceEpoch > item.expireAt) {
                      ref.invalidate(groupsPreviewProvider(widget.treasureId));
                      return;
                    }
                    appRouter.push('/payment?treasureId=${item.treasureId}&groupId=${item.groupId}&isGroupBuy=true');
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D4F),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Text(
                      'product_detail.btn_join'.tr(),
                      style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 5. Content Details (Details / Rules Tabs)
// ==========================================
class DetailContentSection extends StatefulWidget {
  final String? ruleContent;
  final String? desc;
  const DetailContentSection({super.key, this.ruleContent, this.desc});

  @override
  State<DetailContentSection> createState() => _DetailContentSectionState();
}

class _DetailContentSectionState extends State<DetailContentSection> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 监听 Tab 切换，动态控制下方 HTML 渲染
    _tabController.addListener(() {
      if (_tabController.index != _currentIndex) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
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
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: context.bgPrimary,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFF4D4F),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFFF4D4F),
              labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: 'product_detail.tab_desc'.tr()),
                Tab(text: 'product_detail.tab_rules'.tr())
              ],
            ),
            SizedBox(height: 16.h),

            // Banners 核心优化 2：彻底干掉高度写死的 SizedBox(height: 400) 和会截断内容的 TabBarView！
            // 使用 AnimatedSize，让巨型图文详情可以根据真实内容向下完美撑开，无需二次滚动嵌套
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: _currentIndex == 0
                  ? RepaintBoundary( // Banners 隔离昂贵的 HTML 图层
                child: HtmlWidget(
                  widget.desc ?? 'common.no_data'.tr(),
                  textStyle: TextStyle(fontSize: 13.sp),
                  buildAsync: true, // Banners 核心优化 3：开启异步解析，滑动切入详情页时绝对不会掉帧！
                ),
              )
                  : RepaintBoundary(
                child: HtmlWidget(
                  widget.ruleContent ?? 'common.no_data'.tr(),
                  textStyle: TextStyle(fontSize: 13.sp),
                  buildAsync: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}