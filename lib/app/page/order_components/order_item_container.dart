import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/ui/img/app_image.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter_app/app/page/order_detail_page.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/ui/animations/transparent_fade_route.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/ui/modal/sheet/radix_sheet.dart';
import 'package:flutter_app/utils/date_helper.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_app/core/providers/order_provider.dart';
import 'package:flutter_app/utils/media/remote_url_builder.dart';
import 'package:flutter_app/core/services/customer_service/customer_service_helper.dart';
import 'refund_request_sheet.dart';

part 'order_item_container_ui.dart';
part 'order_item_container_logic.dart';

class OrderItemContainer extends ConsumerWidget {
  final OrderItem item;
  final bool isLast;
  final VoidCallback? onRefresh;

  const OrderItemContainer({
    super.key,
    required this.item,
    required this.isLast,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String heroTag = 'order_card_${item.orderId}';
    final isWinning = item.isWon;

    Widget cardContent = Padding(
      padding: EdgeInsets.only(bottom: isLast ? 32.h : 12.h),
      child: Hero(
        tag: heroTag,
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: isWinning
                  ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFBEB), Colors.white],
              )
                  : null,
              color: isWinning ? null : context.bgPrimary,
              borderRadius: BorderRadius.circular(16.w),
              border: isWinning
                  ? Border.all(color: const Color(0xFFFFD700), width: 1.2)
                  : Border.all(color: context.borderSecondary, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: isWinning
                      ? const Color(0xFFFFD700).withOpacity(0.15)
                      : context.fgPrimary900.withOpacity(0.04),
                  blurRadius: 20.w,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部状态栏
                _OrderItemStatusHeader(item: item),

                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      _OrderItemHeader(item: item),
                      SizedBox(height: 16.h),
                      _DashedSeparator(color: context.borderSecondary),
                      SizedBox(height: 16.h),
                      _OrderItemInfo(item: item),
                      _OrderItemGroupSuccess(item: item),

                      if (item.refundStatus > 0) ...[
                        SizedBox(height: 12.h),
                        _OrderItemRefundInfo(item: item),
                      ],

                      SizedBox(height: 20.h),
                      //  核心：在这里把事件代理给 Logic 类处理
                      _OrderItemActions(
                        item: item,
                        onRequestRefund: () => OrderItemLogic.handleRequestRefund(context, ref, item, onRefresh),
                        onViewFriends: () => OrderItemLogic.handleViewFriends(item),
                        onViewRewardDetails: () => OrderItemLogic.handleViewRewardDetails(context, item),
                        onTeamUp: () => OrderItemLogic.handleTeamUp(item),
                        onClaimPrize: () => OrderItemLogic.handleClaimPrize(item),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return cardContent
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOutQuad)
        .slideY(begin: 0.1, end: 0.0, duration: 400.ms, curve: Curves.easeOutQuad)
        .then(delay: 200.ms)
        .shimmer(
      duration: 1500.ms,
      color: isWinning ? const Color(0xFFFFD700).withOpacity(0.4) : Colors.transparent,
      angle: 0.8,
    );
  }
}