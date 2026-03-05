import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/render_countdown.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/ui/bubble_progress.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/ui/img/app_image.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/utils/media/remote_url_builder.dart';

/// Home Featured / Future Section (Vertical Product List)
/// Optimized: Removed VisibilityDetector & GPU-heavy BackdropFilter
class HomeFuture extends StatelessWidget {
  final List<ProductListItem>? list;
  final String title;

  const HomeFuture({super.key, required this.list, required this.title});

  @override
  Widget build(BuildContext context) {
    if (list == null || list!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: context.textPrimary900,
            ),
          ),
        ),

        // Vertical List Container
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: List.generate(list!.length, (index) {
              final item = list![index];

              //  Core Optimization: Staggered animation using modulo
              final animationDelay = ((index % 5) * 50).ms;

              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: ProductCard(item: item)
                    .animate(
                      delay: animationDelay,
                    ) // Trigger instantly upon build
                    .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                    .slideY(
                      begin: 0.1,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOutQuart,
                    ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

/// Individual Product Card
class ProductCard extends StatelessWidget {
  final ProductListItem item;

  const ProductCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => appRouter.push('/product/${item.treasureId}'),
      child: Container(
        decoration: BoxDecoration(
          color: context.bgSecondary,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Stack(
            children: [
              // Main Product Image
              AppCachedImage(
                RemoteUrlBuilder.fitAbsoluteUrl(item.treasureCoverImg!),
                width: 343.w,
                height: 288.w,
                fit: BoxFit.cover,
              ),

              // Top-left business tags
              Positioned(
                top: 10.h,
                left: 10.w,
                child: Row(
                  children: [
                    if (item.groupSize != null && item.groupSize! > 1)
                      _buildTag(
                        context,
                        '${item.groupSize}P Group',
                        Colors.orange,
                      ),
                    if (item.shippingType == 2)
                      Padding(
                        padding: EdgeInsets.only(left: 4.w),
                        child: _buildTag(context, 'E-Voucher', Colors.blue),
                      ),
                  ],
                ),
              ),

              // Bottom Info Card (Title, Progress, Price, Action)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ProductInfoCard(item: item),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Floating Info Card at the bottom of the image
class ProductInfoCard extends StatelessWidget {
  final ProductListItem item;

  const ProductInfoCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(6.w),
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          //  Core Optimization: Replaced GPU-heavy BackdropFilter with a LinearGradient
          // Provides excellent readability over any image with zero performance cost
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(context.radiusXs),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Title
            Text(
              item.treasureName ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.textSm,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15.h),

            // Progress Bar
            BubbleProgress(
              value: item.buyQuantityRate,
              showTipBg: false,
              tipBuilder: (v) {
                final txt = FormatHelper.parseRate(v);
                return Text(
                  'common.sold.upperCase'.tr(namedArgs: {'number': '$txt%'}),
                  style: TextStyle(
                    fontSize: context.text2xs,
                    fontWeight: FontWeight.w600,
                    color: context.utilityBrand500,
                  ),
                );
              },
            ),
            SizedBox(height: 10.h),

            // Bottom Row (Price, Countdown, Button)
            ProductInfoCardBottom(item: item),
          ],
        ),
      ),
    );
  }
}

class ProductInfoCardBottom extends StatefulWidget {
  final ProductListItem item;

  const ProductInfoCardBottom({super.key, required this.item});

  @override
  State<ProductInfoCardBottom> createState() => _ProductInfoCardBottomState();
}

class _ProductInfoCardBottomState extends State<ProductInfoCardBottom> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final salesStart = widget.item.salesStartAt ?? 0;
    final salesEnd = widget.item.salesEndAt ?? 0;

    final bool isSoldOut = widget.item.buyQuantityRate! >= 100;
    final bool isWaitingSale = salesStart > now;
    final bool isExpired = salesEnd != 0 && now >= salesEnd;

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'common.ticket.price'.tr(),
              style: TextStyle(
                fontSize: context.textXs,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            Text(
              '₱${widget.item.costAmount}',
              style: TextStyle(
                fontSize: context.textXs,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (isSoldOut)
          _buildStatusText(
            context,
            'common.status'.tr(),
            'common.sold_out'.tr(),
          )
        else if (isExpired)
          _buildStatusText(
            context,
            'common.status'.tr(),
            'common.activity_ended'.tr(),
            isError: true,
          )
        else
          RenderCountdown(
            lotteryTime: isWaitingSale ? salesStart : salesEnd,
            onFinished: () {
              if (mounted) setState(() {});
            },
            renderCountdown: (time) => _buildStatusText(
              context,
              isWaitingSale ? 'common.starts_in'.tr() : 'common.countdown'.tr(),
              time,
            ),
            renderEnd: (days) => _buildStatusText(
              context,
              isWaitingSale ? 'common.pre_sale'.tr() : 'common.countdown'.tr(),
              'common.days_left'.tr(namedArgs: {'days': days}),
            ),
            renderSoldOut: () => _buildStatusText(
              context,
              'common.status'.tr(),
              'common.activity_ended'.tr(),
            ),
          ),
        const Spacer(),
        IgnorePointer(
          ignoring: true,
          child: Button(
            //  这里：缩小高度，增加内部边距，让它变成好看的胶囊按钮
            height: 32.h,
            paddingX: 14.w,
            backgroundColor: (isWaitingSale || isSoldOut || isExpired)
                ? context.buttonSecondaryBg
                : null,
            foregroundColor: (isWaitingSale || isSoldOut || isExpired)
                ? context.textPrimary900
                : context.textWhite,
            child: Text(
              isWaitingSale
                  ? 'common.pre_sale'.tr()
                  : (isSoldOut
                        ? 'common.sold_out'.tr()
                        : 'common.join_group'.tr()),
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusText(
    BuildContext context,
    String label,
    String value, {
    bool isError = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: isError ? context.textErrorPrimary600 : Colors.white,
          ),
        ),
      ],
    );
  }
}
