import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/components/swiper_banner.dart';
import 'package:flutter_app/core/models/index.dart'; // ProductListItem, Group...
import 'package:flutter_app/core/providers/index.dart'; // groupsListProvider
import 'package:flutter_app/ui/bubble_progress.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/utils/format_helper.dart';

import '../../../core/models/groups.dart';

// 1. Banner Section
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
        height: 250,
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

// 2. Coupon Section
class CouponSection extends StatelessWidget {
  const CouponSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      child: SizedBox(
        height: 22.h,
        child: Row(
          children: [
            Row(
              children: List.generate(
                2,
                (index) => Container(
                  margin: EdgeInsets.only(right: 8.w),
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: context.utilityBrand200),
                    color: context.utilityBrand50,
                  ),
                  child: Text(
                    'New User Gift',
                    style: TextStyle(
                      fontSize: context.textXs,
                      color: context.utilityBrand700,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 24.w, color: context.fgQuinary400),
          ],
        ),
      ),
    );
  }
}


// 3. Top Treasure Info Section (电商重构版)
class TopTreasureSection extends StatelessWidget {
  final ProductListItem item;
  final String? url;

  const TopTreasureSection({super.key, required this.item, this.url});

  @override
  Widget build(BuildContext context) {
    // --- 1. 数据计算 ---
    // 价格相关
    final double marketPrice = double.tryParse(item.costAmount ?? '0') ?? 0;
    final double currentPrice = item.unitAmount;
    final double savedAmount = (marketPrice > currentPrice)
        ? (marketPrice - currentPrice)
        : 0;

    // 库存相关
    final int sold = item.seqBuyQuantity ?? 0;
    final int total = item.seqShelvesQuantity ?? 0;
    final int left = (total - sold).clamp(0, total);

    // 礼品相关 (优先读配置，没有配置则根据 lotteryMode 判断)
    // 假设 item.bonusConfig 是 Map<String, dynamic>
    final String? giftName =
        item.bonusConfig?['bonusItemName'] ??
        (item.lotteryMode == 1 ? "Mystery Grand Prize" : null);
    final bool hasGift = giftName != null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: context.bgPrimary,
          border: Border.all(color: context.borderPrimary),
          borderRadius: BorderRadius.circular(context.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // --- A. 标题与分享 ---
            Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Text(
                      item.treasureName,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.textMd,
                        fontWeight: FontWeight.w800,
                        color: context.fgPrimary900,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () {
                      // 调用分享逻辑
                    },
                    child: SvgPicture.asset(
                      'assets/images/product_detail/share.svg',
                      width: 20.w,
                      colorFilter: ColorFilter.mode(
                        context.fgPrimary900,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // --- B. 核心价格展示 ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 现价
                Text(
                  FormatHelper.formatCurrency(currentPrice),
                  style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w900,
                    color: context.fgBrandPrimary,
                    height: 1.0,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(width: 8.w),

                // 原价 + 节省标签
                if (marketPrice > currentPrice) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        FormatHelper.formatCurrency(marketPrice),
                        style: TextStyle(
                          fontSize: context.textXs,
                          color: context.textTertiary600,
                          decoration: TextDecoration.lineThrough,
                          height: 1.2,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.w,
                        ),
                        decoration: BoxDecoration(
                          color: context.fgErrorPrimary,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                        child: Text(
                          'SAVE ${FormatHelper.formatCurrency(savedAmount)}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            // --- C. 礼品抽奖横幅 (Bonus Banner) ---
            if (hasGift) ...[
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFF7E6), // 浅金
                      Color(0xFFFFF0D6), // 浅橙
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: const Color(0xFFFFD591)), // 金色边框
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orangeAccent,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        FontAwesomeIcons.gift,
                        size: 14.w,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "product.chance_to_win".tr(),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: context.utilityOrange600,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            "Win: $giftName",
                            style: TextStyle(
                              fontSize: context.textSm,
                              color: context.utilityBrand200,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 16.h),

            // --- D. 库存进度条 ---
            BubbleProgress(value: item.buyQuantityRate),
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.whatshot,
                      size: 12.w,
                      color: context.textSecondary700,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '$sold sold',
                      style: TextStyle(
                        fontSize: context.textXs,
                        color: context.textSecondary700,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Only $left left',
                  style: TextStyle(
                    fontSize: context.textXs,
                    color: context.fgBrandPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),
            Divider(height: 1, color: context.borderSecondary),
            SizedBox(height: 16.h),

            // --- E. 底部关键参数 (物流 + 限购) ---
            Row(
              children: [
                // 1. 物流
                Expanded(
                  child: _buildInfoItem(
                    context,
                    FontAwesomeIcons.truckFast,
                    item.shippingType == 2 ? 'Digital Item' : 'Free Shipping',
                    'Delivery',
                  ),
                ),

                Container(
                  width: 1,
                  height: 30.h,
                  color: context.borderSecondary,
                ),

                // 2. 限购
                Expanded(
                  child: _buildInfoItem(
                    context,
                    CupertinoIcons.cart_badge_plus,
                    (item.maxPerBuyQuantity != null &&
                            item.maxPerBuyQuantity! > 0)
                        ? '${item.maxPerBuyQuantity} Limit'
                        : 'No Limit',
                    'Per User',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String val,
    String label,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12.w, color: context.textTertiary600),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: context.text2xs,
                color: context.textSecondary700,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          val,
          style: TextStyle(
            fontSize: context.textSm,
            fontWeight: FontWeight.w700,
            color: context.fgPrimary900,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}


// 4. Group Section
class GroupSection extends ConsumerWidget {
  final String treasureId;

  const GroupSection({super.key, required this.treasureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 简化逻辑，仅展示第一页，若需要更复杂逻辑建议单独封装 Provider
    final groupsAsync = ref.watch(
      groupsListProvider(
        GroupsListRequestParams(page: 1, treasureId: treasureId),
      ),
    );

    return groupsAsync.when(
      data: (data) {
        if (data.list.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Container(
            decoration: BoxDecoration(
              color: context.bgPrimary,
              border: Border.all(color: context.borderPrimary),
              borderRadius: BorderRadius.circular(context.radiusMd),
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Groups',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: context.textMd,
                        ),
                      ),
                      Icon(Icons.chevron_right, color: context.fgPrimary900),
                    ],
                  ),
                ),
                ...data.list
                    .take(3)
                    .map((item) => _buildGroupItem(context, item)), // 只展示前3个
                SizedBox(height: 12.h),
              ],
            ),
          ),
        );
      },
      error: (_, __) => const SizedBox.shrink(),
      loading: () => Skeleton.react(width: double.infinity, height: 100.h),
    );
  }

  Widget _buildGroupItem(BuildContext context, GroupForTreasureItem item) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(item.creator.avatar ?? ''),
      ),
      title: Text(item.creator.nickname ?? 'User'),
      trailing: Icon(Icons.chevron_right, size: 16.w),
      onTap: () => appRouter.push('/group-member?groupId=${item.groupId}'),
    );
  }
}



// 5. Content Details
class DetailContentSection extends StatefulWidget {
  final String? ruleContent;
  final String? desc;

  const DetailContentSection({super.key, this.ruleContent, this.desc});

  @override
  State<DetailContentSection> createState() => _DetailContentSectionState();
}

class _DetailContentSectionState extends State<DetailContentSection>
    with SingleTickerProviderStateMixin {
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
          borderRadius: BorderRadius.circular(context.radiusMd),
          border: Border.all(color: context.borderPrimary),
        ),
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: context.textBrandSecondary700,
              unselectedLabelColor: context.textQuaternary500,
              indicatorColor: context.buttonPrimaryBg,
              tabs: [
                Tab(text: 'Details'.tr()),
                Tab(text: 'Rules'.tr()),
              ],
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 300.w, // 给个最小高度，或者使用 AutoHeight 方案
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: HtmlWidget(widget.desc ?? 'No description'),
                  ),
                  SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: HtmlWidget(widget.ruleContent ?? 'No rules'),
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

class DetailContentSectionSkeleton extends StatelessWidget {
  const DetailContentSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: context.bgPrimary,
          borderRadius: BorderRadius.circular(context.radiusMd),
          border: Border.all(color: context.borderPrimary),
        ),
        child: Column(
          children: [
            Skeleton.react(width: 100.w, height: 24.h),
            SizedBox(height: 16.h),
            Column(
              children: List.generate(
                5,
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Skeleton.react(
                    width: double.infinity,
                    height: 16.h,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
