import 'dart:async';

import 'package:easy_localization/easy_localization.dart'; // 🔥 必须引入
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/img/app_image.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// --- 核心依赖 ---
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/components/swiper_banner.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/ui/bubble_progress.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/utils/format_helper.dart';

import '../../../core/models/groups.dart';

// ==========================================
// 1. Banner Section (轮播图)
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
// 2. Coupon Section (优惠券)
// ==========================================
class CouponSection extends StatelessWidget {
  const CouponSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: SizedBox(
        height: 24.h,
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
                color: Colors.red.withOpacity(0.05),
              ),
              child: Text(
                // 🌐 国际化：新人礼
                'product_detail.label_new_user_gift'.tr(),
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 20.w, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. Top Treasure Info Section (核心信息区)
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
    // 1. 划线价逻辑
    final double marketPrice = item.marketAmount ?? double.tryParse(item.costAmount ?? '0') ?? 0;

    // 2. 当前售价
    final double currentPrice = realTimeItem?.price ?? item.unitAmount ?? 0;

    // 3. 库存逻辑
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
            // --- 标题与分享 ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    // 🌐 国际化：商品名 Fallback
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

            // --- 价格展示区域 ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 现价
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

                // 拼团人数标签
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4D4F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    // 🌐 国际化：5人团 (5p Group)
                    '${item.groupSize ?? 5}${'product_detail.group_size_suffix'.tr()}',
                    style: TextStyle(
                        fontSize: 10.sp,
                        color: const Color(0xFFFF4D4F),
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),

                const Spacer(),

                // 划线价
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

            // --- 进度条 ---
            BubbleProgress(value: item.buyQuantityRate ?? 0),

            SizedBox(height: 8.h),

            // --- 销量信息 ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 🌐 国际化：100 sold
                Text(
                  '$sold${'product_detail.suffix_sold'.tr()}',
                  style: TextStyle(fontSize: 11.sp, color: context.textSecondary700),
                ),
                // 🌐 国际化：Only 10 left / 10 na lang
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
// 4. Group Section (拼团列表区) - 带自动刷新
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
                // 头部 - 点击跳转全部
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
                        // 🌐 国际化：5 people joining
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
                            // 🌐 国际化：View all
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
      loading: () {
        return const SizedBox.shrink();
      },
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
          // 头像
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

          // 名字 + 差几人
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // 🌐 国际化：用户名 fallback
                  item.creator.nickname ?? 'group_lobby.default_user'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                ),
                // 🌐 国际化：Short of X people
                Text(
                  '${'product_detail.short_of_prefix'.tr()}${item.maxMembers - item.currentMembers}${'product_detail.short_of_suffix'.tr()}',
                  style: TextStyle(fontSize: 10.sp, color: const Color(0xFFFF4D4F)),
                ),
              ],
            ),
          ),

          // 倒计时 + 按钮
          Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CountdownTimer(
                  endTime: endTime,
                  widgetBuilder: (_, time) {
                    // 🌐 国际化：Ended
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

                // Join 按钮
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
                      // 🌐 国际化：Join
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
// 5. Content Details (详情/规则 Tab)
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
                // 🌐 国际化：Details
                Tab(text: 'product_detail.tab_desc'.tr()),
                // 🌐 国际化：Rules
                Tab(text: 'product_detail.tab_rules'.tr())
              ],
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 400.h,
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: HtmlWidget(
                        // 🌐 国际化：No data
                          widget.desc ?? 'common.no_data'.tr(),
                          textStyle: TextStyle(fontSize: 13.sp)
                      )
                  ),
                  SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: HtmlWidget(
                        // 🌐 国际化：No data
                          widget.ruleContent ?? 'common.no_data'.tr(),
                          textStyle: TextStyle(fontSize: 13.sp)
                      )
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