import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/user_coupon.dart';
import 'package:flutter_app/core/providers/coupon_provider.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VoucherList extends ConsumerStatefulWidget {
  const VoucherList({super.key});

  @override
  ConsumerState<VoucherList> createState() => _VoucherListState();
}

class _VoucherListState extends ConsumerState<VoucherList> {
  @override
  Widget build(BuildContext context) {
    final couponListAsync = ref.watch(myValidCouponsProvider);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 8.w),
      padding: EdgeInsets.symmetric(vertical: 12.w), // 调整了上下 padding 让卡片居中更美观
      decoration: BoxDecoration(
        color: context.bgPrimaryAlt,
        borderRadius: BorderRadius.all(Radius.circular(12.w)), // 改为全圆角更协调
      ),
      child: couponListAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 24.w),
              child: Center(
                child: Text(
                  "No available vouchers",
                  style: TextStyle(color: context.textSecondary700),
                ),
              ),
            );
          }
          return _CouponListView(list: list);
        },
        error: (error, stackTrace) => Padding(
          padding: EdgeInsets.all(16.w),
          child: Text('Error loading vouchers', style: const TextStyle(color: Colors.red)),
        ),
        loading: () => const _SkeletonListView(),
      ),
    );
  }
}

class _CouponListView extends StatelessWidget {
  final List<UserCoupon> list;

  const _CouponListView({required this.list});

  @override
  Widget build(BuildContext context) {
    final double itemExtent = 112.w;

    final displayList = list.take(5).toList();
    final showViewMore = list.length > 5;
    final itemCount = displayList.length + (showViewMore ? 1 : 0);

    return SizedBox(
      height: 120.w,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        itemCount: itemCount,
        itemExtent: itemExtent,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        addSemanticIndexes: false,
        itemBuilder: (context, index) {
          //  渲染“查看全部”卡片
          if (showViewMore && index == displayList.length) {
            return _ViewMoreTile(totalCount: list.length);
          }

          // 渲染真实优惠券
          final item = displayList[index];
          return _CouponTile(item: item);
        },
      ),
    );
  }
}

// =========================================================================
// UI精装修：“查看全部” 引导卡片 (带堆叠阴影，和真券完美对齐)
// =========================================================================
class _ViewMoreTile extends StatelessWidget {
  final int totalCount;

  const _ViewMoreTile({required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 跳转到独立的优惠券管理页面
        appRouter.push('/me/voucher');
      },
      child: SizedBox(
        height: 120.w, // 和真券总高度保持一致
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: SizedBox(
                width: 96.w,
                height: 82.w,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 背景阴影层 1 (使用浅灰色，区别于真券的品牌色，暗示这是功能卡片)
                    Positioned(
                      top: 5.w,
                      left: -2.w,
                      bottom: 0,
                      child: Container(
                        width: 100.w,
                        height: 72.w,
                        decoration: BoxDecoration(
                          color: context.borderPrimary,
                          borderRadius: const BorderRadius.all(Radius.circular(4)),
                        ),
                      ),
                    ),
                    // 背景阴影层 2
                    Positioned(
                      top: 10.w,
                      left: -4.w,
                      child: Container(
                        width: 104.w,
                        height: 66.w,
                        decoration: BoxDecoration(
                          color: context.alphaBlack5,
                          borderRadius: BorderRadius.all(Radius.circular(4.w)),
                        ),
                      ),
                    ),
                    // 真实内容主体
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.bgPrimary,
                          border: Border.all(color: context.borderPrimary, width: 1.w),
                          borderRadius: BorderRadius.all(Radius.circular(4.w)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 细化图标背景和尺寸
                            Container(
                              width: 36.w,
                              height: 36.w,
                              decoration: BoxDecoration(
                                color: context.bgPrimaryAlt,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CupertinoIcons.arrow_right,
                                size: 18.w,
                                color: context.textPrimary900,
                              ),
                            ),
                            SizedBox(height: 8.w),
                            Text(
                              'View All',
                              style: TextStyle(
                                fontSize: context.textXs,
                                color: context.textPrimary900,
                                fontWeight: FontWeight.w800, // 加粗标题
                                height: 1.0,
                              ),
                            ),
                            SizedBox(height: 4.w),
                            Text(
                              '$totalCount Vouchers',
                              style: TextStyle(
                                fontSize: 10.sp, // 比标题小一号
                                color: context.textSecondary700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.w),
            //  这里非常重要：用一个透明的 SizedBox 占位，替代真券的 Button
            // 这样能保证外层的 ViewAll 卡片和左边的真券在同一水平线上，不会塌陷！
            SizedBox(
              height: 22.w,
              width: 85.w,
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponTile extends StatelessWidget {
  final UserCoupon item;

  const _CouponTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: SizedBox(
              width: 96.w,
              height: 82.w,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 背景阴影层 1
                  Positioned(
                    top: 5.w,
                    left: -2.w,
                    bottom: 0,
                    child: Container(
                      width: 100.w,
                      height: 72.w,
                      decoration: BoxDecoration(
                        color: context.fgBrandPrimary.withValues(alpha: 0.6),
                        borderRadius: const BorderRadius.all(Radius.circular(4)),
                      ),
                    ),
                  ),
                  // 背景阴影层 2
                  Positioned(
                    top: 10.w,
                    left: -4.w,
                    child: Container(
                      width: 104.w,
                      height: 66.w,
                      decoration: BoxDecoration(
                        color: context.fgBrandPrimary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.all(Radius.circular(4.w)),
                      ),
                    ),
                  ),
                  // 真实内容
                  _CouponContent(item: item),
                ],
              ),
            ),
          ),
          SizedBox(height: 4.w),
          _ButtonArea(item: item),
        ],
      ),
    );
  }
}

class _CouponContent extends StatelessWidget {
  final UserCoupon item;

  const _CouponContent({required this.item});

  @override
  Widget build(BuildContext context) {
    final isPercentage = item.couponType == 2;
    final rewardText = isPercentage
        ? '${double.tryParse(item.discountValue)?.toInt() ?? 0}% OFF'
        : '₱${item.discountValue}';

    return Positioned.fill(
      child: Container(
        width: 96.w,
        height: 82.w,
        decoration: BoxDecoration(
          color: context.bgPrimary,
          border: Border.all(color: context.borderBrand, width: 1.w),
          borderRadius: BorderRadius.all(Radius.circular(4.w)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 券标题头 (截取一部分防止超长)
            Container(
              width: 80.w,
              height: 14.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.fgBrandPrimary.withValues(alpha: 0.8),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(4.w),
                  bottomRight: Radius.circular(4.w),
                ),
              ),
              child: Transform.translate(
                offset: Offset(0, -2.w),
                child: Transform.scale(
                  scale: 0.8,
                  child: Text(
                    item.couponName.length > 10 ? '${item.couponName.substring(0, 10)}...' : item.couponName,
                    style: TextStyle(
                      fontSize: 12.w,
                      color: context.textWhite,
                      height: context.leadingMd,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 5.w),
            // 面值 (金额或折扣)
            Text(
              rewardText,
              style: TextStyle(
                color: context.textBrandPrimary900,
                fontSize: context.textXs,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2.w),
            // 最低消费描述
            Column(
              children: [
                Text(
                  'coupon.min.spend'.tr(),
                  style: TextStyle(
                    color: context.textBrandPrimary900,
                    fontSize: context.text2xs,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2.w),
                Text(
                  '₱${item.minPurchase}',
                  style: TextStyle(
                    color: context.textBrandPrimary900,
                    fontSize: context.text2xs,
                    fontWeight: FontWeight.w800,
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

class _ButtonArea extends StatelessWidget {
  final UserCoupon item;

  const _ButtonArea({required this.item});

  @override
  Widget build(BuildContext context) {
    return Button(
      width: 85.w,
      height: 22.w,
      borderColor: context.borderBrand,
      radius: context.radiusXs,
      backgroundColor: context.utilityBrand500,
      foregroundColor: context.textPrimaryOnBrand,
      paddingX: 3.w,
      textStyle: TextStyle(fontSize: context.textXs),
      onPressed: () {
        // 点击 Use Now，跳回首页去买东西
        appRouter.go('/');
      },
      child: const Text('Use Now'),
    );
  }
}

// =========================================================================
//  体验优化：骨架屏组件 (Placeholder)
// =========================================================================
class _SkeletonListView extends StatelessWidget {
  const _SkeletonListView();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120.w, // 和真实列表高度一致
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        itemCount: 4, // 默认假装有 4 张券，填满屏幕
        itemExtent: 112.w, // 和真实卡片宽度一致
        physics: const NeverScrollableScrollPhysics(), // 加载时禁止滑动
        itemBuilder: (context, index) {
          return SizedBox(
            height: 120.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Container(
                    width: 96.w,
                    height: 82.w,
                    decoration: BoxDecoration(
                      color: context.bgPrimaryAlt.withValues(alpha: 0.5),
                      border: Border.all(color: context.borderPrimary, width: 1.w),
                      borderRadius: BorderRadius.all(Radius.circular(4.w)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 60.w, height: 10.w, color: context.alphaBlack5),
                        SizedBox(height: 10.w),
                        Container(width: 40.w, height: 20.w, color: context.alphaBlack5),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 4.w),
                // 假按钮
                Container(
                  width: 85.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    color: context.alphaBlack5,
                    borderRadius: BorderRadius.circular(context.radiusXs),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}