import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/render_countdown.dart';
import 'package:flutter_app/ui/bubble_progress.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/ui/img/app_image.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/utils/media/remote_url_builder.dart';

/// Special Area / Highlighted Products Section
/// Optimized: Removed VisibilityDetector, utilizing loop index for staggered animations
class SpecialArea extends StatelessWidget {
  final List<ProductListItem>? list;
  final String title;

  const SpecialArea({super.key, required this.list, required this.title});

  @override
  Widget build(BuildContext context) {
    if (list == null || list!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Section Title
        Padding(
          padding: EdgeInsets.only(left: 16.w, top: 8.h),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: context.textPrimary900,
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),

        // 2. List Container
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(children: _buildListItems(context)),
        ),

        SizedBox(height: 20.h),
      ],
    );
  }

  /// Manually build list items with dynamic border radiuses and dividers
  List<Widget> _buildListItems(BuildContext context) {
    final items = <Widget>[];
    final count = list!.length;

    for (int i = 0; i < count; i++) {
      final item = list![i];

      final isFirst = i == 0;
      final isLast = i == count - 1;

      // Handle corner radiuses based on item position
      BorderRadius borderRadius = BorderRadius.zero;
      if (count == 1) {
        borderRadius = BorderRadius.circular(8.r);
      } else if (isFirst) {
        borderRadius = BorderRadius.only(
          topLeft: Radius.circular(8.r),
          topRight: Radius.circular(8.r),
        );
      } else if (isLast) {
        borderRadius = BorderRadius.only(
          bottomLeft: Radius.circular(8.r),
          bottomRight: Radius.circular(8.r),
        );
      }

      items.add(
        GestureDetector(
          onTap: () => appRouter.push('/product/${item.treasureId}'),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: EdgeInsets.only(left: 12.w, right: 12.w, top: 12.h),
            decoration: BoxDecoration(
              color: context.bgPrimary,
              borderRadius: borderRadius,
            ),
            child: Column(
              children: [
                //  Core Optimization: Staggered animation using loop index
                _buildSingleItemContent(context, item)
                    .animate(delay: ((i % 5) * 50).ms) // 50ms stagger
                    .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                    .slideX(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutCubic)
                // Note: Use withOpacity for color transparency
                    .shimmer(duration: 1000.ms, color: Colors.white.withOpacity(0.4)),

                // Uniform bottom spacing to balance top padding
                SizedBox(height: 12.h),

                // Static divider (excluded on the last item)
                if (!isLast)
                  Divider(height: 1.h, color: context.borderSecondary),
              ],
            ),
          ),
        ),
      );
    }
    return items;
  }

  /// Builds the inner content of a single product item
  Widget _buildSingleItemContent(BuildContext context, ProductListItem item) {
    return Column(
      children: [
        // Top Section: Image + Title + Progress Bar
        Row(
          children: [
            AppCachedImage(
              RemoteUrlBuilder.fitAbsoluteUrl(item.treasureCoverImg ?? ''),
              width: 80.w,
              height: 80.w,
              fit: BoxFit.cover,
              radius: BorderRadius.circular(8.r),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.treasureName ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.textSm,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary900,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  BubbleProgress(
                    value: item.buyQuantityRate,
                    showTipBg: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        // Bottom Section: Price + Countdown + Action Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Price Column
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'common.ticket.price'.tr(),
                  style: TextStyle(
                    fontSize: context.textXs,
                    color: context.textQuaternary500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  FormatHelper.formatCurrency(item.unitAmount),
                  style: TextStyle(
                    fontSize: context.textXs,
                    color: context.textPrimary900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),

            // Countdown Column
            Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: RenderCountdown(
                  lotteryTime: item.lotteryTime,
                  renderSoldOut: () => _buildStatusColumn(
                    context,
                    'common.draw_once'.tr(),
                    'common.sold'.tr(),
                    isError: true,
                  ),
                  renderEnd: (days) => _buildStatusColumn(
                    context,
                    'common.refile_end'.tr(),
                    'common.days'.tr(namedArgs: {'days': days.toString()}),
                    isError: true,
                  ),
                  renderCountdown: (time) => _buildStatusColumn(
                    context,
                    'common.countdown'.tr(),
                    time,
                    isError: true,
                  ),
                ),
              ),
            ),

            // Action Button (Visual only, interaction handled by parent wrapper)
            IgnorePointer(
              ignoring: true,
              child: Button(
                height: 46.h,
                child: Text('common.enter.now'.tr()),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Helper to build consistent status text layouts
  Widget _buildStatusColumn(
      BuildContext context,
      String topLabel,
      String bottomValue, {
        bool isError = false,
      }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          topLabel,
          style: TextStyle(
            fontSize: context.textXs,
            color: context.textQuaternary500,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          bottomValue,
          style: TextStyle(
            fontSize: context.textXs,
            color: isError
                ? context.textErrorPrimary600
                : context.textPrimary900,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}