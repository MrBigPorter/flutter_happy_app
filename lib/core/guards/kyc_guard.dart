import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_app/core/store/user_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/components/kyc_modal.dart';
import 'package:flutter_app/theme/design_tokens.g.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/modal/dialog/radix_modal.dart';
import 'package:flutter_app/ui/modal/sheet/radix_sheet.dart';

class KycGuard {
  /// 核心方法：确保已认证
  /// [context] 用于弹窗
  /// [ref] 用于读取用户状态
  /// [onApproved] 只有状态为 Approved 时才会执行的回调

  static void ensure({
    required BuildContext context,
    required WidgetRef ref,
    required VoidCallback onApproved,
  }) {
    // 1. 获取状态
    final kycStatus = ref.read(
      userProvider.select((state) => state?.kycStatus ?? 0),
    );

    final statusEnum = KycStatusEnum.fromStatus(kycStatus);

    // 2. 根据状态执行不同逻辑
    switch (statusEnum) {
      case KycStatusEnum.approved:
        // 已认证，直接执行回调
        onApproved();
        break;
      case KycStatusEnum.reviewing:
        // 审核中，提示用户等待
        _showPendingSheet(context);
        break;
      default:
        //  未认证/失败：弹去认证窗
        _showVerifyModal(context);
        break;
    }
  }

  /// 私有方法：显示审核中弹窗
  static void _showPendingSheet(BuildContext context) {
    RadixSheet.show(
      builder: (context, close) {
        return Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.time,
                size: 48.w,
                color: context.utilityWarning500,
              ),
              SizedBox(height: 16.h),
              Text(
                'Verification in Progress', // 建议放入多语言 key
                style: TextStyle(
                  fontSize: context.textLg,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary900,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Your documents are currently under review. Please wait patiently.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.textMd,
                  color: context.textSecondary700,
                ),
              ),
              SizedBox(height: 24.h),
              Button(
                width: double.infinity,
                onPressed: close,
                child: Text('OK'), // common.okay
              ),
            ],
          ),
        );
      },
    );
  }

  /// 私有方法：显示去认证弹窗
  static void _showVerifyModal(BuildContext context) {
    RadixModal.show(
      // title: 'common.modal.kyc.title'.tr(), // 如果 KycModal 没标题就放这里
      confirmText: 'common.modal.kyc.button'.tr(),
      onConfirm: (close) {
        close();
        appRouter.push('/me/kyc/verify');
      },
      cancelText: '', // 空字符串隐藏取消按钮，或者根据需求显示
      builder: (context, close) {
        return const KycModal();
      },
    );
  }
}
