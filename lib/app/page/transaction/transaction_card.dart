import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/transaction/transaction_ui_model.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/utils/date_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TransactionCard extends StatelessWidget {
  final TransactionUiModel item;
  const TransactionCard({super.key,required this.item});

  @override
  Widget build(BuildContext context) {
    

    final isDeposit = item.type == UiTransactionType.deposit;

    // 状态颜色逻辑
    Color statusColor;
    Color statusBg;

    if (item.statusCode == 1) { // Pending
      statusColor = const Color(0xFFEF6C00);
      statusBg = const Color(0xFFFFF3E0);
    } else if (item.statusCode == 3) { // Failed/Rejected
      statusColor = const Color(0xFFC62828);
      statusBg = const Color(0xFFFFEBEE);
    } else { // Success
      statusColor = const Color(0xFF2E7D32);
      statusBg = const Color(0xFFE8F5E9);
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(12.r),
        // 阴影
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // 1. 图标
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: isDeposit ? const Color(0xFFE8F5E9) : const Color(0xFFF3E5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDeposit ? Icons.account_balance_wallet : Icons.local_atm,
              color: isDeposit ? Colors.green : Colors.purple,
              size: 22.w,
            ),
          ),
          SizedBox(width: 12.w),

          // 2. 标题和时间
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: context.textPrimary900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  DateFormatHelper.format(item.time,'yyyy-MM-dd HH:mm'),
                  style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                ),
              ],
            ),
          ),

          // 3. 金额和状态
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${isDeposit ? '+' : '-'}${item.amount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16.sp,
                  color: isDeposit ? Colors.green : Colors.black,
                ),
              ),
              SizedBox(height: 6.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  item.statusText,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

// 骨架屏组件
class TransactionSkeleton extends StatelessWidget {
  const TransactionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 8.h,
        bottom: 8.h,
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Skeleton.react(width: 44.w, height: 44.w, ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton.react(width: 120.w, height: 16.h,),
                  SizedBox(height: 8.h),
                  Skeleton.react(width: 80.w, height: 12.h, ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Skeleton.react(width: 60.w, height: 20.h,),
          ],
        ),
      ),
    );
  }
}