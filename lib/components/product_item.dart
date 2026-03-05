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

class ProductItem extends StatelessWidget {
  final ProductListItem data;
  final int? cardWidth;
  final int? imgWidth;
  final int? imgHeight;

  const ProductItem({
    super.key,
    required this.data,
    this.cardWidth = 157, // 虽然保留参数防报错，但内部已不再使用硬编码宽度
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
      //  核心优化：去掉了 width: cardWidth!.w，让外界来决定大小
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
          // 1. 顶部正方形图片
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
                  child: AppCachedImage(
                    RemoteUrlBuilder.fitAbsoluteUrl(data.treasureCoverImg ?? ''),
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

          // 2. 底部信息区 (魔法等比缩放盒)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                //  神奇的防拥挤魔法：如果在 iPad 上装不下，整个内容自动等比例微缩！
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth, // 必须限制宽度，确保标题能自动换行
                    ),
                    child: Padding(
                      // 完美的呼吸感间距，在手机上完美复刻 UI，在 iPad 上等比微缩
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            data.treasureName ?? '',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary900,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 8.w),
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
                          SizedBox(height: 8.w),
                          BubbleProgress(
                            value: rate,
                            showTip: false,
                            color: context.utilityBrand500,
                            trackHeight: 4,
                          ),
                          SizedBox(height: 4.w),
                          Text(
                            'common.sold.upperCase'.tr(namedArgs: {'number': (rate ?? 0).toStringAsFixed(0)}),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10.sp, color: context.textPrimary900),
                          ),
                          SizedBox(height: 8.w),
                          _buildCountdownSection(context, isWaitingSale, isSoldOut, isExpired, salesStart, salesEnd),
                          SizedBox(height: 12.w),
                          SizedBox(
                            height: 32.h, // 恢复成胶囊形大按钮
                            child: Button(
                              paddingY: 0,
                              paddingX: 0,
                              backgroundColor: (isWaitingSale || isSoldOut || isExpired) ? context.buttonSecondaryBg : context.utilityBrand500,
                              foregroundColor: (isWaitingSale || isSoldOut || isExpired) ? context.textPrimary900 : context.textWhite,
                              onPressed: () {
                                appRouter.pushNamed('productDetail', pathParameters: {'id': data.treasureId ?? ''});
                              },
                              child: Text(
                                isWaitingSale ? 'common.pre_sale'.tr() : 'common.enter.now'.tr(),
                                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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

  Widget _statusText(String label, String value, {bool isError = false}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10.sp, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            color: isError ? Colors.redAccent : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(color: color.withOpacity(0.9), borderRadius: BorderRadius.circular(4.r)),
      child: Text(text, style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold)),
    );
  }
}

// 骨架屏也同步去掉了写死的宽度
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Skeleton.react(width: double.infinity, height: double.infinity, borderRadius: BorderRadius.vertical(top: Radius.circular(8.r))),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Skeleton.react(width: double.infinity, height: 12.h, borderRadius: BorderRadius.circular(2.r)),
                  Skeleton.react(width: 80.w, height: 16.h, borderRadius: BorderRadius.circular(4.r)),
                  Skeleton.react(width: double.infinity, height: 6.h, borderRadius: BorderRadius.circular(3.r)),
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