import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/app/routes/app_router.dart';

class InsufficientBalanceSheet extends StatelessWidget {
  final VoidCallback close;

  const InsufficientBalanceSheet({super.key, required this.close});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300.w,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -20.w,
            left: 0,
            child: Image.asset(
              'assets/images/payment/rechargeBg.png',
              width: 375.w,
            ),
          ),
          Positioned(
            right: 0,
            child:  InkResponse(
              onTap: close,
              child: Container(
                width: 32.w,
                height: 32.w,
                alignment: Alignment.center,
                child:  Icon(Icons.close, size: 22.w, color: context.fgPrimary900),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 80),
              Text(
                'wallet.balance.insufficient'.tr(),
                style: TextStyle(
                  color: context.textPrimary900,
                  fontSize: context.textLg,
                  height: context.leadingLg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'wallet.balance.insufficient.tip'.tr(),
                style: TextStyle(
                  color: context.textSecondary700,
                  fontSize: context.textSm,
                  height: context.leadingSm,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 24,),
              Button(
                width: double.infinity,
                onPressed: () {
                  close();
                  appRouter.push('/me/wallet');
                },
                child: Text(
                  'common.to.recharge'.tr(),
                ),
              ),
              SizedBox(height: 16),
              Button(
                  width: double.infinity,
                  variant: ButtonVariant.outline,
                  onPressed: close,
                  child: Text(
                    'common.cancel'.tr(),
                    style: TextStyle(
                      color: context.textQuaternary500,
                      fontSize: context.textMd,
                      height: context.leadingMd,
                      fontWeight: FontWeight.w600,
                    ),
                  )
              )
            ],
          )
        ],
      ),
    );
  }
}