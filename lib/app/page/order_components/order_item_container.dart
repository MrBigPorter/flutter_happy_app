import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/utils/date_helper.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OrderItemContainer extends StatelessWidget {
  final OrderItem item;
  final bool isLast;
  const OrderItemContainer({
    super.key,
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal:16.w,vertical: 12.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        border: isLast ? Border(
          bottom: BorderSide(
            color: context.borderTertiary,
            width: 1,
          )
        ): null,
      ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OrderItemHeader(item: item),
            SizedBox(height: 8.w),
            _OrderItemInfo(item: item,)
          ],
        )
    );
  }

}

class _OrderItemHeader extends StatelessWidget {
  final OrderItem item;
  const _OrderItemHeader({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          clipBehavior: Clip.hardEdge,
          borderRadius: BorderRadius.circular(8.w),
          child: CachedNetworkImage(
            imageUrl: proxied(item.treasureCoverImg),
            width: 80.w,
            height: 80.w,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: context.borderSecondary,
                borderRadius: BorderRadius.circular(8.w),
              ),
              child: Icon(CupertinoIcons.photo, size: 40.w, color: context.textTertiary600,),
            ),
            placeholder: (_,__) => Skeleton.react(
              width: 80.w,
              height: 80.w,
              borderRadius: BorderRadius.circular(8.w),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.treasureName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: context.textSm,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary900,
                      height: context.leadingSm
                  ),
                ),
                SizedBox(height: 9.w),
                RichText(
                  text: TextSpan(
                      style: TextStyle(
                          fontSize: context.textXs,
                          fontWeight: FontWeight.w400,
                          color: context.textTertiary600,
                          height: context.leadingXs
                      ),
                      children: [
                        TextSpan(
                          text: '${FormatHelper.formatWithCommas(item.purchaseCount)}/${FormatHelper.formatWithCommas(item.stockQuantity)}',
                        ),
                        TextSpan(
                          text: ' ',
                        ),
                        TextSpan(
                          text: 'common.sold.lowercase'.tr(),
                        )
                      ]
                  ),
                )
              ]
          ),
        )
      ],
    );
  }
}

class _OrderItemInfo extends StatelessWidget {
  final OrderItem item;
  const _OrderItemInfo({required this.item});

  @override
  Widget build(BuildContext context) {

    Widget line(String left, String right){
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            left,
            style: TextStyle(
              fontSize: context.textSm,
              fontWeight: FontWeight.w600,
              color: context.textPrimary900,
              height: context.leadingSm
            ),
          ),
          Text(
            right,
            style: TextStyle(
              fontSize: context.textSm,
              fontWeight: FontWeight.w800,
              color: context.textPrimary900,
              height: context.leadingSm
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       if(!item.lotteryTime.isNullOrEmpty)
         line('common.draw.date'.tr(), DateFormatHelper.formatFull(item.lotteryTime)),
        SizedBox(height: 12.w,),
        line('common.ticket.price'.tr(), FormatHelper.formatWithCommasAndDecimals(item.totalAmount/item.entries)),
        SizedBox(height: 12.w,),
        line('common.tickets.number'.tr(), '${item.entries}'),
        SizedBox(height: 12.w,),
        line(
            item.orderStatus == OrderStatus.groupSuccess ?
            'common.refund'.tr() : 'common.total.price'.tr(),
            '${item.totalAmount}'
        ),
        SizedBox(height: 12.w,),
      ],
    );
  }
}

class _OrderItemActions extends StatelessWidget {
  final OrderItem item;
  const _OrderItemActions({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class _OrderItemGroupSuccess extends StatelessWidget {
  final OrderItem item;
  const _OrderItemGroupSuccess({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class _OrderItemRefundInfo extends StatelessWidget {
  final OrderItem item;
  const _OrderItemRefundInfo({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}