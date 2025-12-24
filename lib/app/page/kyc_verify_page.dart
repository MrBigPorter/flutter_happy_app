import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class KycVerifyPage extends ConsumerWidget {
  const KycVerifyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BaseScaffold(
      title: 'kyc-verify'.tr(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: _StepList(),
      ),
      bottomNavigationBar: _BottomNavigationBar(),
    );
  }
}

class _BottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: context.bgPrimary,
        padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 12.h, ),
        child: SizedBox(
            width: double.infinity,
            child: Button(
              width: double.infinity,
              height: 40.h,
              child: Text(
                'start-now'.tr(),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
        ),
      ),
    );
  }
}


class _StepList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h),
        Text(
          'verify-process'.tr(),
          style: TextStyle(
            fontSize: 14.sp,
            color: context.textPrimary900,
            fontWeight: FontWeight.w600,
          ),
        ),
        Divider(height: 40.h, color: context.fgSecondary700),
        _StepItem(
          title: '${'common.step'.tr()} 1',
          subTitle: 'upload-id-photo'.tr(),
          description: '',
          detail: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h,),
              Text(
                'make-id'.tr(),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.textPrimary900,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.circle,
                    color: context.textBrandPrimary900,
                    size: 8.w,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'full-name'.tr(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.textSecondary700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.circle,
                    color: context.textBrandPrimary900,
                    size: 8.w,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'id-photo'.tr(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.textSecondary700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.circle,
                    color: context.textBrandPrimary900,
                    size: 8.w,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'date-o'.tr(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.textSecondary700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          completed: false,
          img: 'assets/images/verify/step1.png',
        ),
        SizedBox(height: 20.h),
        _StepItem(
          title: '${'common.step'.tr()} 2',
          subTitle: 'information-confirm'.tr(),
          description: 'double-id'.tr(),
          completed: false,
          img: 'assets/images/verify/step2.png',
        ),
        SizedBox(height: 20.h),
        _StepItem(
          title: '${'common.step'.tr()} 2',
          subTitle: 'upload-selfie'.tr(),
          description: 'upload-verification'.tr(),
          completed: false,
          img: 'assets/images/verify/step3.png',
        ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  final String title;
  final String description;
  final String? subTitle;
  final bool completed;
  final String img;
  final Widget? detail;

  const _StepItem({
    required this.title,
    required this.description,
    this.completed = false,
    this.subTitle,
    required this.img,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              completed ? CupertinoIcons.check_mark_circled_solid : Icons.error,
              color: context.textBrandPrimary900,
              size: 20.w,
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                color: context.textBrandPrimary900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          subTitle!,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: context.textSecondary700,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            if (detail != null)
              Expanded(child: detail!)
            else
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.textSecondary700,
                  ),
                ),
              ),
            Image.asset(img, width: 112.w, height: 70.h, fit: BoxFit.contain,cacheWidth: (112.w * MediaQuery.of(context).devicePixelRatio).round() ,),
          ],
        ),
      ],
    );
  }
}
