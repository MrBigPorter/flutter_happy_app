import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/share_sheet.dart';
import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_app/features/share/models/share_data.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PaymentSuccessSheet extends ConsumerWidget {
  final OrderCheckoutResponse purchaseResponse;
  final String title;

  const PaymentSuccessSheet({
    super.key,
    required this.purchaseResponse,
    required this.title
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseUrl = ref.watch(luckyProvider.select((s) => s.sysConfig.webBaseUrl));

    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight  * 0.8;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeight
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 成功图标
          const Icon(
            CupertinoIcons.check_mark_circled_solid,
            color: CupertinoColors.activeGreen,
            size: 64.0,
          ),
          SizedBox(height: 16.h),

          Text(
            'order.wait.draw'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: context.textPrimary900,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'order.wait.draw.soon'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: context.textSecondary700,
            ),
          ),

          // 3. 分享卡片 (这是电商转化的关键)
          // 重点：加上 groupId 邀请好友参与
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: ShareSheet(
              data: ShareData(
                  title: title,
                  url: '$baseUrl/product/${purchaseResponse.treasureId}?groupId=${purchaseResponse.groupId}'
              ),
            ),
          ),

          // 4. 操作按钮 (修正了跳转逻辑的 ${} 语法)
          Button(
            width: double.infinity,
            onPressed: () {
              // 统一使用 push 到详情，让用户能点返回
              appRouter.push('/me/order/${purchaseResponse.orderId}');
            },
            child: Text('common.view.details'.tr()),
          ),

          SizedBox(height: 12.h),

          Button(
            variant: ButtonVariant.outline,
            width: double.infinity,
            onPressed: () {
              appRouter.go('/home');
            },
            child: Text('common.back.home'.tr()),
          ),
        ],
      ),
    );
  }
}