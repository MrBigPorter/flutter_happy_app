import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/providers/coupon_provider.dart';

class Voucher extends ConsumerWidget {
  const Voucher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponListAsync = ref.watch(myValidCouponsProvider);

    final int couponCount = couponListAsync.valueOrNull?.length ?? 0;

    return Container(
      width: double.infinity,
      height: 34.w,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(left: 8.w, right: 12.w),
      margin: EdgeInsets.only(top: 12.w),
      decoration: BoxDecoration(
        color: context.bgPrimaryAlt,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8.w)),
      ),
      child: GestureDetector(
        onTap: () {
          appRouter.push('/me/voucher');
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/coupon.png',
                  width: 16.w,
                  height: 16.w,
                  fit: BoxFit.cover,
                ),
                SizedBox(width: 4.w),
                Text(
                  'common.my.vouchers'.tr(
                    namedArgs: {'number': couponCount.toString()},
                  ),
                  style: TextStyle(
                    fontSize: context.textXs,
                    fontWeight: FontWeight.w800,
                    color: context.textBrandPrimary900,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: 16.w,
              height: 16.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.bgBrandSolid,
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.chevron_right,
                size: 12.w,
                color: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }
}