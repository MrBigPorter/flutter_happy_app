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

class SpecialArea extends StatelessWidget {
  final List<ProductListItem>? list;
  final String title;

  const SpecialArea({super.key, required this.list, required this.title});

  @override
  Widget build(BuildContext context) {
    if (list == null || list!.isEmpty) return const SizedBox.shrink();

    return Center(
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(children: _buildListItems(context)),
          ),
          SizedBox(height: 20.h),
        ],
      )
    );
  }

  List<Widget> _buildListItems(BuildContext context) {
    final items = <Widget>[];
    final count = list!.length;

    for (int i = 0; i < count; i++) {
      final item = list![i];
      final isFirst = i == 0;
      final isLast = i == count - 1;

      BorderRadius borderRadius = BorderRadius.zero;
      if (count == 1) {
        borderRadius = BorderRadius.circular(8.r);
      } else if (isFirst) {
        borderRadius = BorderRadius.vertical(top: Radius.circular(8.r));
      } else if (isLast) {
        borderRadius = BorderRadius.vertical(bottom: Radius.circular(8.r));
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
                _buildSingleItemContent(context, item)
                    .animate(delay: ((i % 5) * 50).ms)
                    .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                    .slideX(
                      begin: 0.1,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    ),
                SizedBox(height: 12.h),
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

  Widget _buildSingleItemContent(BuildContext context, ProductListItem item) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCachedImage(
              RemoteUrlBuilder.fitAbsoluteUrl(item.treasureCoverImg ?? ''),
              width: 80.w,
              height: 80.w,
              fit: BoxFit.cover,
              radius: BorderRadius.circular(8.r),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.treasureName ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary900,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  BubbleProgress(value: item.buyQuantityRate, showTipBg: true),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 取消强行 Expanded，让价格正常显示
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'common.ticket.price'.tr(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: context.textQuaternary500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  FormatHelper.formatCurrency(item.unitAmount),
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: context.textPrimary900,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            //  核心：倒计时区域用 Expanded 占据剩下的所有空间，把左右推开
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
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
            // 取消强行 Expanded，让按钮恢复小巧的胶囊形状
            IgnorePointer(
              ignoring: true,
              child: Button(
                height: 32.h,
                paddingX: 16.w,
                child: Text(
                  'common.enter.now'.tr(),
                  style: TextStyle(fontSize: 12.sp),
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusColumn(
    BuildContext context,
    String topLabel,
    String bottomValue, {
    bool isError = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            topLabel,
            style: TextStyle(
              fontSize: 10.sp,
              color: context.textQuaternary500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            bottomValue,
            style: TextStyle(
              fontSize: 12.sp,
              color: isError
                  ? context.textErrorPrimary600
                  : context.textPrimary900,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
