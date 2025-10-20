import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Voucher extends StatelessWidget {
  const Voucher({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 34.w,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(left: 8.w,right: 12.w),
      margin: EdgeInsets.only(top: 12.w),
      decoration: BoxDecoration(
        color: context.bgPrimaryAlt,
        borderRadius: BorderRadius.all(Radius.circular(8.w)),
      ),
      child: GestureDetector(
        onTap: (){
          AppRouter.router.push('/me/voucher');
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
                SizedBox(width: 2.w,),
                Text(
                  'common.my.vouchers'.tr(
                    namedArgs: {'number': '0'},
                  ),
                  style: TextStyle(
                    fontSize: context.textXs,
                    fontWeight: FontWeight.w800,
                    color: context.textBrandPrimary900,
                  ),
                ),
              ],
            ),
            Spacer(),
            Container(
              width: 16.w,
              height: 16.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.bgBrandSolid,
                shape: BoxShape.circle
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