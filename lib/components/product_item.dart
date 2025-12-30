import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/render_countdown.dart';
import 'package:flutter_app/ui/bubble_progress.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/ui/img/app_image.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/core/models/index.dart';

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
    // 1. 时间逻辑处理
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int salesStart = data.salesStartAt ?? 0;
    final int salesEnd = data.salesEndAt ?? 0;

    final bool isWaitingSale = salesStart > now;
    final bool isExpired = salesEnd != 0 && now >= salesEnd;
    final bool isSoldOut = data.buyQuantityRate >= 100;

    // 获取购买比率
    final double rate = data.buyQuantityRate.toDouble();

    return Container(
      key: ValueKey(data.treasureId),
      width: cardWidth!.w,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(8.w),
        // 添加轻微阴影提升质感
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- 图片区域 ---
          Stack(
            clipBehavior: Clip.none,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8.w)),
                  child: AppCachedImage(
                    data.treasureCoverImg!,
                    width: imgWidth!.w,
                    height: imgHeight!.w,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // 业务标签 (如 5P Group)
              if (data.groupSize != null && data.groupSize! > 1)
                Positioned(
                  top: 8.w,
                  left: 8.w,
                  child: _buildTag('${data.groupSize}P Group', Colors.orange),
                ),
            ],
          ),

          // --- 信息区域 ---
          Padding(
            padding: EdgeInsets.all(8.w),
            child: Column(
              children: [
                // 标题
                SizedBox(
                  height: 36.w,
                  child: Text(
                    data.treasureName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.w,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary900,
                      height: 1.2,
                    ),
                  ),
                ),
                SizedBox(height: 8.w),

                // 价格
                Text(
                  FormatHelper.formatCurrency(data.unitAmount, symbol: "₱"),
                  style: TextStyle(
                    fontSize: 16.w,
                    fontWeight: FontWeight.w900,
                    color: context.utilityBrand500,
                  ),
                ),
                SizedBox(height: 8.w),

                // 进度条
                BubbleProgress(
                  value: rate,
                  showTip: false,
                  color: context.utilityBrand500,
                  trackHeight: 4,
                  // 进度条描述
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.w),
                  child: Text(
                    'common.sold.upperCase'.tr(namedArgs: {'number': rate.toStringAsFixed(0)}),
                    style: TextStyle(fontSize: 10.w, color: context.textPrimary900),
                  ),
                ),

                // --- 倒计时逻辑区 ---
                _buildCountdownSection(context, isWaitingSale, isSoldOut, isExpired, salesStart, salesEnd),

                SizedBox(height: 10.w),

                // 按钮
                Button(
                  height: 36.w,
                  backgroundColor: (isWaitingSale || isSoldOut || isExpired) ? context.bgTertiary : null,
                  onPressed: () {
                    appRouter.pushNamed('productDetail', pathParameters: {'id': data.treasureId});
                  },
                  child: Text(
                    isWaitingSale ? 'common.pre_sale'.tr() : 'common.enter.now'.tr(),
                    style: TextStyle(fontSize: 12.w, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建状态文字/倒计时
  Widget _buildCountdownSection(BuildContext context, bool isWaitingSale, bool isSoldOut, bool isExpired, int start, int end) {
    if (isSoldOut) return _statusText('common.status'.tr(), 'common.sold_out'.tr());
    if (isExpired) return _statusText('common.status'.tr(), 'common.activity_ended'.tr(), isError: true);

    return RenderCountdown(
      // 动态目标：预售期看开始时间，热卖期看结束时间
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
        Text(
          label,
          style: TextStyle(fontSize: 10.w, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10.w,
            fontWeight: FontWeight.w800,
            color: isError ? Colors.redAccent : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4.w),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: 9.w, fontWeight: FontWeight.bold),
      ),
    );
  }
}