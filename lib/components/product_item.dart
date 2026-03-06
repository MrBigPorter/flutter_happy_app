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
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/utils/media/remote_url_builder.dart';

//  矢量级商品卡片：完全脱离 flutter_screenutil 依赖！
// 采用 166 x 365 绝对尺寸 + FittedBox 等比缩放
// 保证在任何 iPad/手机 上都 100% 还原设计稿的完美间距！
class ProductItem extends StatelessWidget {
  final ProductListItem data;
  final int? cardWidth;
  final int? imgWidth;
  final int? imgHeight;

  const ProductItem({
    super.key,
    required this.data,
    this.cardWidth,
    this.imgWidth,
    this.imgHeight,
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

    //  核心魔法：把整个 166x365 的卡片当成图片一样等比缩放进任何容器
    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.topCenter,
      child: Container(
        key: ValueKey(data.treasureId),
        width: 166,
        // 绝对设计稿宽度
        height: 365,
        // 绝对设计稿高度
        decoration: BoxDecoration(
          color: context.bgPrimary,
          borderRadius: BorderRadius.circular(8),
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
            // --- 1. 图片区域 (166 x 166) ---
            SizedBox(
              width: 166,
              height: 166,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    child: AppCachedImage(
                      RemoteUrlBuilder.fitAbsoluteUrl(
                        data.treasureCoverImg ?? '',
                      ),
                      fit: BoxFit.cover,

                      //  核心修复 1：骨架屏无缝接力！
                      // 在图片下载的那几百毫秒里，继续显示骨架屏动画，消灭死白空隙！
                      placeholder: Skeleton.react(
                        width: 166,
                        height: 166,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),

                      //  核心修复 2：错误兜底
                      // 如果图片 URL 挂了，显示一个灰色的破损图标，而不是整块白掉
                      error: Container(
                        color: Colors.grey[100],
                        child: Icon(Icons.broken_image, color: Colors.grey[300], size: 40),
                      ),
                    ),
                  ),
                  if (data.groupSize != null && data.groupSize! > 1)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildTag(
                        '${data.groupSize}P Group',
                        Colors.orange,
                      ),
                    ),
                ],
              ),
            ),

            // --- 2. 信息区域 (166 x 199 剩余高度) ---
            SizedBox(
              height: 199,
              child: Padding(
                padding: const EdgeInsets.all(8.0), // 原汁原味的 8 像素间距
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 标题
                    SizedBox(
                      height: 34,
                      child: Text(
                        data.treasureName ?? '',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13, // 纯数值
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary900,
                          height: 1.2,
                        ),
                      ),
                    ),

                    // 价格
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        FormatHelper.formatCurrency(
                          data.unitAmount,
                          symbol: "₱",
                        ),
                        style: TextStyle(
                          fontSize: 16, // 纯数值
                          fontWeight: FontWeight.w900,
                          color: context.utilityBrand500,
                        ),
                      ),
                    ),

                    // 进度条
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BubbleProgress(
                          value: rate,
                          showTip: false,
                          color: context.utilityBrand500,
                          trackHeight: 4,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'common.sold.upperCase'.tr(
                            namedArgs: {
                              'number': (rate ?? 0).toStringAsFixed(0),
                            },
                          ),
                          style: TextStyle(
                            fontSize: 10,
                            color: context.textPrimary900,
                          ),
                        ),
                      ],
                    ),

                    // 倒计时
                    _buildCountdownSection(
                      context,
                      isWaitingSale,
                      isSoldOut,
                      isExpired,
                      salesStart,
                      salesEnd,
                    ),

                    // 按钮
                    SizedBox(
                      height: 36, // 纯数值
                      width: double.infinity,
                      child: Button(
                        paddingX: 0,
                        // 覆写默认 padding，防止内部文字被挤压
                        paddingY: 0,
                        radius: 8,
                        // 纯数值圆角
                        backgroundColor:
                        (isWaitingSale || isSoldOut || isExpired)
                            ? context.buttonSecondaryBg
                            : context.utilityBrand500,
                        foregroundColor:
                        (isWaitingSale || isSoldOut || isExpired)
                            ? context.textPrimary900
                            : context.textWhite,
                        onPressed: () {
                          appRouter.pushNamed(
                            'productDetail',
                            pathParameters: {'id': data.treasureId ?? ''},
                          );
                        },
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              isWaitingSale
                                  ? 'common.pre_sale'.tr()
                                  : 'common.enter.now'.tr(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
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
      ),
    );
  }

  Widget _buildCountdownSection(
      BuildContext context,
      bool isWaitingSale,
      bool isSoldOut,
      bool isExpired,
      int start,
      int end,
      ) {
    if (isSoldOut)
      return _statusText('common.status'.tr(), 'common.sold_out'.tr());
    if (isExpired)
      return _statusText(
        'common.status'.tr(),
        'common.activity_ended'.tr(),
        isError: true,
      );

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
      renderSoldOut: () =>
          _statusText('common.status'.tr(), 'common.activity_ended'.tr()),
    );
  }

  Widget _statusText(String label, String value, {bool isError = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isError ? Colors.redAccent : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// 骨架屏也同步成纯矢量缩放！
class ProductItemSkeleton extends StatelessWidget {
  const ProductItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: Container(
        width: 166,
        height: 365,
        decoration: BoxDecoration(
          color: context.bgPrimary,
          borderRadius: BorderRadius.circular(8),
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
            SizedBox(
              width: 166,
              height: 166,
              child: Skeleton.react(
                width: 166,
                height: 166,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ),
            SizedBox(
              height: 199,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Skeleton.react(
                      width: double.infinity,
                      height: 14,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    Skeleton.react(
                      width: 80,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    Skeleton.react(
                      width: double.infinity,
                      height: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    Column(
                      children: [
                        Skeleton.react(
                          width: 60,
                          height: 8,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        const SizedBox(height: 4),
                        Skeleton.react(
                          width: 80,
                          height: 8,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                    Skeleton.react(
                      width: double.infinity,
                      height: 36,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}