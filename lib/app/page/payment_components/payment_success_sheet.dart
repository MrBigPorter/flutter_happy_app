import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/share_sheet.dart';
import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_app/core/store/lucky_store.dart';

import 'package:flutter_app/features/share/models/share_data.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentSuccessSheet extends ConsumerWidget {
  final OrderCheckoutResponse purchaseResponse;
  final String title;
  const PaymentSuccessSheet({super.key, required this.purchaseResponse, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseUrl = ref.watch(luckyProvider.select((select)=>select.sysConfig.webBaseUrl));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          CupertinoIcons.check_mark_circled_solid,
          color: CupertinoColors.activeGreen,
          size: 64.0,
        ),
        const SizedBox(height: 16.0),
         Text(
          'order.wait.draw'.tr(),
           style: TextStyle(
               fontSize: context.textLg,
               fontWeight: FontWeight.w600,
               color: context.textPrimary900,
               height: context.leadingSm
           ),
        ),
        const SizedBox(height: 8.0),
         Text(
          'order.wait.draw.soon'.tr(),
          style: TextStyle(
            fontSize: context.textLg,
            fontWeight: FontWeight.w600,
            color: context.textPrimary900,
            height: context.leadingSm
          ),
        ),
        const SizedBox(height: 24.0),
        ShareSheet(
          data: ShareData(title: title, url: '$baseUrl/product/${purchaseResponse.treasureId}?groupId=${purchaseResponse.groupId}'),
        ),
        Button(
          width: double.infinity,
          onPressed: () {
            appRouter.go('/me/order/$purchaseResponse.orderId');
          },
          child: const Text('common.view.details').tr(),
        ),
        const SizedBox(height: 12),
        Button(
          variant: ButtonVariant.outline,
          width: double.infinity,
          onPressed: () {
            appRouter.go('/home');
          },
          child: const Text('common.back.home').tr(),
        ),
      ],
    );
  }
}
