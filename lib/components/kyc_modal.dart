import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class KycModal extends StatelessWidget {
  const KycModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 给一点内边距，防止贴边
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
      child: Column(
        // 统一居中对齐
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SecurityPulseIcon(),
          SizedBox(height: 16.w),

          // 2. 正文说明 (desc1) - 以前太粗了，现在改为正文样式
          Text(
            'common.modal.kyc.desc1'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textPrimary900,
              fontSize: context.textMd, // 16sp 左右
              height: 1.5, // 增加行高，阅读更舒服
              fontWeight: FontWeight.w500, // 适中字重
            ),
          ),

          SizedBox(height: 16.w),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.w),
            decoration: BoxDecoration(
              color: context.bgSecondary, // 浅灰色底
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  CupertinoIcons.lock_fill,
                  size: 14.w,
                  color: context.textSecondary700,
                ),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    'common.modal.kyc.desc2'.tr(),
                    style: TextStyle(
                      color: context.textSecondary700,
                      fontSize: context.textXs, // 小字号
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SecurityPulseIcon extends StatelessWidget {
  const SecurityPulseIcon({super.key});

  @override
  Widget build(BuildContext context) {

    final primaryColor = context.utilityBrand500;
    final lightBg = context.utilityBrand50;

    return SizedBox(
      width: 80.w,
      height: 80.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // --- 第一层：扩散波纹 (Ripple) ---
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.3),
              shape: BoxShape.circle
            ),
          )
          .animate(onPlay: (controller)=> controller.repeat())// 无限循环
          .scale(duration: 2.seconds,begin: const Offset(0.8, 0.8), end: const Offset(1.5, 1.5))// 放大
          .fadeOut(duration: 2.seconds,curve: Curves.easeInOut),// 渐隐

          // --- 第二层：静态底圆 ---
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: lightBg,
              shape: BoxShape.circle,
            ),
          ),

          // --- 第三层：呼吸盾牌 (Shield) ---
          Icon(
            CupertinoIcons.shield_fill,
            size: 32.w,
            color: primaryColor,
          )
          .animate(onPlay: (controller)=> controller.repeat(reverse: true))// 循环：放大后缩小 (Yoyo)
          .scaleX(duration: 1.seconds,begin: 1.0, end: 1.1, curve: Curves.easeInOut)// 呼吸感
        ],
      ),
    );
  }
}