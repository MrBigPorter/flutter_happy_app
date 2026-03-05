import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/render_countdown.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/bubble_progress.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/ui/img/app_image.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/core/models/index.dart';

import 'package:flutter_app/utils/media/remote_url_builder.dart';

/// Product Item Card
/// 增加了 FittedBox 防爆盾，完美解决多端设备上的 Right Overflow 问题
class ProductItem extends StatelessWidget {
  final ProductListItem data;
  final int? cardWidth;
  final int? imgWidth;
  final int? imgHeight;

  const ProductItem({
    super.key,
    required this.data,
    this.cardWidth = 157,
    this.imgWidth = 157,
    this.imgHeight = 157,
  });

  @override
  Widget build(BuildContext context) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int salesStart = data.salesStartAt ?? 0;
    final int salesEnd = data.salesEndAt ?? 0;

    final bool isWaitingSale = salesStart > now;
    final bool isExpired = salesEnd != 0 && now >= salesEnd;
    final bool isSoldOut = data.buyQuantityRate! >= 100;
    final double? rate = data.buyQuantityRate?.toDouble();

    return Container(
      key: ValueKey(data.treasureId),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- 1. 图片区域 (严防死守 1:1) ---
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
                  child: AppCachedImage(
                    RemoteUrlBuilder.fitAbsoluteUrl(data.treasureCoverImg!),
                    fit: BoxFit.cover,
                  ),
                ),
                if (data.groupSize != null && data.groupSize! > 1)
                  Positioned(
                    top: 8.w,
                    left: 8.w,
                    child: _buildTag('${data.groupSize}P Group', Colors.orange),
                  ),
              ],
            ),
          ),

          // --- 2. 信息区域 ---
          Expanded(
            child: Padding(
              // 稍微调小一点左右 Padding，给文字留足呼吸空间
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 标题 (原生支持换行和省略号，不用包 FittedBox)
                  Text(
                    data.treasureName ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp, // 稍微缩小一点基准字号
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary900,
                      height: 1.2,
                    ),
                  ),

                  // 价格 (防爆盾 1 号)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      FormatHelper.formatCurrency(data.unitAmount, symbol: "₱"),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: context.utilityBrand500,
                      ),
                    ),
                  ),

                  // 进度条及文字 (防爆盾 2 号)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BubbleProgress(
                        value: rate,
                        showTip: false,
                        color: context.utilityBrand500,
                        trackHeight: 4,
                      ),
                      SizedBox(height: 2.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'common.sold.upperCase'.tr(namedArgs: {'number': (rate ?? 0).toStringAsFixed(0)}),
                          style: TextStyle(fontSize: 10.sp, color: context.textPrimary900),
                        ),
                      ),
                    ],
                  ),

                  // 倒计时
                  _buildCountdownSection(context, isWaitingSale, isSoldOut, isExpired, salesStart, salesEnd),

                  // 按钮 (防爆盾 3 号)
                  SizedBox(
                    height: 28.h,
                    width: double.infinity,
                    child: Button(
                      backgroundColor: (isWaitingSale || isSoldOut || isExpired) ? context.buttonSecondaryBg : context.utilityBrand500,
                      foregroundColor: (isWaitingSale || isSoldOut || isExpired) ? context.textPrimary900 : context.textWhite,
                      onPressed: () {
                        appRouter.pushNamed('productDetail', pathParameters: {'id': data.treasureId});
                      },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Text(
                            isWaitingSale ? 'common.pre_sale'.tr() : 'common.enter.now'.tr(),
                            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownSection(BuildContext context, bool isWaitingSale, bool isSoldOut, bool isExpired, int start, int end) {
    if (isSoldOut) return _statusText('common.status'.tr(), 'common.sold_out'.tr());
    if (isExpired) return _statusText('common.status'.tr(), 'common.activity_ended'.tr(), isError: true);

    return RenderCountdown(
      lotteryTime: isWaitingSale ? start : end,
      renderCountdown: (time) => _statusText(
        isWaitingSale ? 'common.starts_in'.tr() : 'common.countdown'.tr(),
        time,
        isError: true,
      ),
      renderEnd: (days) => _statusText(
        isWaitingSale ? 'common.starts_in'.tr() : 'common.countdown'.tr(),
        'common.days_left'.tr(namedArgs: {'days': days}),
        isError: true,
      ),
      renderSoldOut: () => _statusText('common.status'.tr(), 'common.activity_ended'.tr()),
    );
  }

  // 状态文字 (防爆盾 4 号)
  Widget _statusText(String label, String value, {bool isError = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: isError ? Colors.redAccent : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class ProductItemSkeleton extends StatelessWidget {
  final int? cardWidth;
  final int? imgWidth;
  final int? imgHeight;

  const ProductItemSkeleton({
    super.key,
    this.cardWidth = 157,
    this.imgWidth = 157,
    this.imgHeight = 157,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Skeleton.react(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Skeleton.react(width: double.infinity, height: 12.h, borderRadius: BorderRadius.circular(2.r)),
                      SizedBox(height: 6.h),
                      Skeleton.react(width: 100.w, height: 12.h, borderRadius: BorderRadius.circular(2.r)),
                    ],
                  ),
                  Skeleton.react(width: 80.w, height: 16.h, borderRadius: BorderRadius.circular(4.r)),
                  Column(
                    children: [
                      Skeleton.react(width: double.infinity, height: 6.h, borderRadius: BorderRadius.circular(3.r)),
                      SizedBox(height: 6.h),
                      Skeleton.react(width: 40.w, height: 8.h, borderRadius: BorderRadius.circular(2.r)),
                    ],
                  ),
                  Column(
                    children: [
                      Skeleton.react(width: 60.w, height: 8.h, borderRadius: BorderRadius.circular(2.r)),
                      SizedBox(height: 4.h),
                      Skeleton.react(width: 80.w, height: 8.h, borderRadius: BorderRadius.circular(2.r)),
                    ],
                  ),
                  Skeleton.react(width: double.infinity, height: 32.h, borderRadius: BorderRadius.circular(8.r)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}