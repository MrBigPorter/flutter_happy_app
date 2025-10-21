import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/coupon_threshold_data.dart';
import 'package:flutter_app/core/providers/me_provider.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// voucher list component
/// - show title area
/// - show horizontal scrollable coupon list
/// - each coupon item show coupon content and button area
/// - coupon content show rewardAmount, thresholdStart, header
/// - button area show different button based
/// - on getCoupons value
/// - if getCoupons == 2 show "Collect" button
/// - if getCoupons == 3 show "Collected" button
/// - else show "Spend ₱{buyThresholdStart} to get" button
/// - [showRuleLink] whether show rule link, default true
/// - if false, show "More" text instead
/// - on clicking the link, navigate to voucher rules page
class VoucherList extends ConsumerStatefulWidget {
  final bool showRuleLink;

  const VoucherList({super.key, this.showRuleLink = true});

  @override
  ConsumerState<VoucherList> createState() => _VoucherListState();
}

class _VoucherListState extends ConsumerState<VoucherList> {
  @override
  Widget build(BuildContext context) {
    final couponList = ref.watch(thresholdListProvider);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 8.w),
      padding: EdgeInsets.only(bottom: 4.w),
      decoration: BoxDecoration(
        color: context.bgPrimaryAlt,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.w)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: (){
              if(widget.showRuleLink){
                AppRouter.router.push('/me/voucher/rules');
              }else{
                AppRouter.router.push('/me/voucher');
              }
            },
            child: Padding(
              padding: EdgeInsets.only(top: 12.w, left: 16.w, right: 12.w, bottom: 12.w),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'coupon.win.amount'.tr(namedArgs: {'number': '5'}),
                    style: TextStyle(
                      fontSize: context.textSm,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary900,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.showRuleLink ? "Rules" : "More",
                        style: TextStyle(
                          fontSize: context.textSm,
                          fontWeight: FontWeight.w500,
                          color: context.textPrimary900,
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 16.w,
                        color: context.textPrimary900,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          couponList.when(
            data: (data) => _CouponListView(list: data.couponThreshold),
            error: (error, stackTrace) => Text('Error: $error'),
            loading: () => Padding(
              padding: EdgeInsets.symmetric(vertical: 24.w),
              child: Center(child: CupertinoActivityIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}


/// coupon list view
/// - horizontal scrollable
/// - each item show coupon content and button area
/// - coupon content show rewardAmount, thresholdStart, header
/// - button area show different button based on getCoupons value
///  - if getCoupons == 2 show "Collect" button
///  - if getCoupons == 3 show "Collected" button
///  - else show "Spend ₱{buyThresholdStart} to get" button
class _CouponListView extends StatelessWidget {
  final List<CouponThresholdData> list;

  const _CouponListView({required this.list});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(list.length, (index) {
          final item = list[index];
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
                        // backGroud
                        Positioned(
                          top: 5.w,
                          left: -2.w,
                          bottom: 0,
                          child: Container(
                            width: 100.w,
                            height: 72.w,
                            decoration: BoxDecoration(
                              color: context.fgBrandPrimary.withValues(
                                alpha: 0.6,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        // backGroud
                        Positioned(
                          top: 10.w,
                          left: -4.w,
                          child: Container(
                            width: 104.w,
                            height: 66.w,
                            decoration: BoxDecoration(
                              color: context.fgBrandPrimary.withValues(
                                alpha: 0.4,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(4.w),
                              ),
                            ),
                          ),
                        ),
                        // inner content
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
        }),
      ),
    );
  }
}

/// coupon content area
/// - rewardAmount
/// - thresholdStart
/// - header
class _CouponContent extends StatelessWidget {
  final CouponThresholdData item;

  const _CouponContent({required this.item});

  @override
  Widget build(BuildContext context) {
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
            // header
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
                      'luck Voucher',
                      style: TextStyle(
                          fontSize: 12.w,
                          color: context.textWhite,
                          height: context.leadingMd
                      ),
                    ),
                  ),
              ),
            ),
            SizedBox(height: 5.w,),
            // rewardAmount
            Text(
                '₱${item.rewardAmount}',
                style: TextStyle(
                  color: context.textBrandPrimary900,
                  fontSize: context.textXs,
                  fontWeight: FontWeight.w800
                ),
            ),
            SizedBox(height: 2.w,),
            // dsc
            Column(
              children: [
                Text(
                    'coupon.min.spend'.tr(),
                    style: TextStyle(
                      color: context.textBrandPrimary900,
                      fontSize: context.text2xs,
                      fontWeight: FontWeight.w800
                    ),
                ),
                SizedBox(height: 2.w,),
                Text(
                  FormatHelper.formatCurrency(item.thresholdStart),
                  style: TextStyle(
                      color: context.textBrandPrimary900,
                      fontSize: context.text2xs,
                      fontWeight: FontWeight.w800
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

/// button area
/// - if getCoupons == 2 show "Collect" button
/// - if getCoupons == 3 show "Collected" button
/// - else show "Spend ₱{buyThresholdStart} to get" button
class _ButtonArea extends StatelessWidget {
  final CouponThresholdData item;

  const _ButtonArea({required this.item});

  @override
  Widget build(BuildContext context) {
    final isCollectable = item.getCoupons == 2;

    final backgroundColor = isCollectable
        ? context.utilityBrand500
        : context.bgPrimary;

    final foregroundColor = isCollectable
        ? context.textPrimaryOnBrand
        : context.textBrandPrimary900;

    final text = switch(item.getCoupons){
      2 => Text('coupon.collect').tr(),
      3 => Text('coupon.collected').tr(),
      _ => Text('coupon.threshold').tr(
            namedArgs: {'number': '${item.buyThresholdStart}'},
          ),
    };

    return Button(
      width: 96.w,
      height: 22.w,
      borderColor: context.borderBrand,
      radius: context.radiusXs,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      paddingX: 3.w,
      textStyle: TextStyle(
        fontSize: context.textXs,
      ),
      onPressed: () {},
      child: text,
    );
  }
}
