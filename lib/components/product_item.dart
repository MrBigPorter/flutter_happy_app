import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/render_countdown.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/core/providers/network_status_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/ui/bubble_progress.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/ui/img/optimized_image.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/utils/image/product_detail_preloader.dart';

import '../utils/media/url_resolver.dart';

/// 矢量级商品卡片：完全脱离 flutter_screenutil 依赖！
/// 采用 166 x 365 绝对尺寸 + LayoutBuilder + FittedBox 等比缩放
class ProductItem extends StatelessWidget {
  final ProductListItem data;
  final int? cardWidth;
  final int? imgWidth;
  final int? imgHeight;
  final DeviceCategory deviceCategory;

  const ProductItem({
    super.key,
    required this.data,
    this.cardWidth,
    this.imgWidth,
    this.imgHeight,
    this.deviceCategory = DeviceCategory.phone,
  });

  /// 根据设备分类选择基础卡片尺寸
  double get _baseWidth {
    switch (deviceCategory) {
      case DeviceCategory.phone:
        return 166;
      case DeviceCategory.tablet:
        return 200;
      case DeviceCategory.desktop:
        return 240;
    }
  }

  double get _baseHeight {
    switch (deviceCategory) {
      case DeviceCategory.phone:
        return 365;
      case DeviceCategory.tablet:
        return 440;
      case DeviceCategory.desktop:
        return 528;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int salesStart = data.salesStartAt ?? 0;
    final int salesEnd = data.salesEndAt ?? 0;

    final bool isWaitingSale = salesStart > now;
    final bool isExpired = salesEnd != 0 && now >= salesEnd;
    final bool isSoldOut = data.buyQuantityRate! >= 100;
    final double? rate = data.buyQuantityRate?.toDouble();

    final double baseW = _baseWidth;
    final double baseH = _baseHeight;

    // 使用 LayoutBuilder 获取可用宽度，FittedBox 等比缩放
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: Container(
            key: ValueKey(data.treasureId),
            width: baseW,
            height: baseH,
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
                // --- 1. 图片区域 ---
                SizedBox(
                  width: baseW,
                  height: baseW, // 图片保持正方形
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        child: OptimizedImageFactory.product(
                          url: UrlResolver.resolveImage(
                              context,
                              data.treasureCoverImg,
                              logicalWidth: baseW
                          ),
                          width: baseW,
                          height: baseW,
                          blurhash: data.blurhash,
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

                // --- 2. 信息区域 (剩余高度) ---
                SizedBox(
                  height: baseH - baseW,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
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
                              fontSize: 13,
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
                              fontSize: 16,
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
                          height: 36,
                          width: double.infinity,
                          child: Button(
                            paddingX: 0,
                            paddingY: 0,
                            radius: 8,
                            backgroundColor:
                            (isWaitingSale || isSoldOut || isExpired)
                                ? context.buttonSecondaryBg
                                : context.utilityBrand500,
                            foregroundColor:
                            (isWaitingSale || isSoldOut || isExpired)
                                ? context.textPrimary900
                                : context.textWhite,
                            onPressed: () {
                              ProductDetailPreloader().preloadProductDetailImages(
                                context: context,
                                product: data,
                                groups: null,
                              );

                              // 🔥 Pre-warm the detail provider so the API call is in-flight during route transition
                              ProviderScope.containerOf(context, listen: false)
                                  .read(productDetailProvider(data.treasureId));

                              appRouter.pushNamed(
                                'productDetail',
                                pathParameters: {'id': data.treasureId},
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
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
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
      },
    );
  }
}
