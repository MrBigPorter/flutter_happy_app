import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/render_countdown.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/bubble_progress.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_app/core/models/index.dart';

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
        /// 标题 title
        Padding(
          padding: EdgeInsets.only(left: 16.w, top: 8.w),
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
        SizedBox(height: 8.w),

        ///列表容器 content list
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: context.bgPrimary,
            borderRadius: BorderRadius.circular(8.w),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            // 只占用必要高度 only take necessary height
            physics: const NeverScrollableScrollPhysics(),
            // 禁止滚动 disable scrolling
            separatorBuilder: (_, __) =>
                Divider(color: context.borderSecondary, height: 2.w),
            itemCount: list!.length,
            itemBuilder: (context, index) {
              final item = list![index];
              return AnimatedListItem(
                id: index,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.2),
                  child: Column(
                    children: [
                      /// 商品项 图片 标题 进度条 item with image, title, progress bar
                      Row(
                        children: [
                          /// image 图片
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: CachedNetworkImage(
                              imageUrl: item.treasureCoverImg!,
                              width: 80.w,
                              height: 80.w,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  Skeleton.react(width: 80.w, height: 80.w),
                              errorWidget: (_, __, ___) =>
                                  Skeleton.react(width: 80.w, height: 80.w),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// title 标题
                                Text(
                                  item.treasureName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: context.textSm,
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary900,
                                  ),
                                ),

                                /// and progress bar 以及 进度条
                                BubbleProgress(
                                  // value: item.buyQuantityRate,
                                  value: 0,
                                  showTipBg: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),

                      /// price countdown button 价格 倒计时 按钮
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
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
                              SizedBox(height: 12.h),
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
                          Spacer(),
                          RenderCountdown(
                            lotteryTime: item.lotteryTime,
                            renderSoldOut: () => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Draw once',style: TextStyle(
                                  fontSize: context.textXs,
                                  color: context.textQuaternary500,
                                  fontWeight: FontWeight.w600,
                                  height: 1,
                                ),),
                                SizedBox(height: 12.h),
                                Text('sold out',style: TextStyle(
                                  fontSize: context.textXs,
                                  color: context.textErrorPrimary600,
                                  fontWeight: FontWeight.w600,
                                  height: 1,
                                ),),
                              ],
                            ),
                            renderEnd: (days) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'refile end',
                                  style: TextStyle(
                                    fontSize: context.textXs,
                                    color: context.textQuaternary500,
                                    fontWeight: FontWeight.w600,
                                    height: 1,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  '$days days',
                                  style: TextStyle(
                                    fontSize: context.textXs,
                                    color: context.textErrorPrimary600,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                            renderCountdown: (time) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'common.countdown'.tr(),
                                  style: TextStyle(
                                    fontSize: context.textXs,
                                    color: context.textQuaternary500,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: context.textXs,
                                    color: context.textErrorPrimary600,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Spacer(),
                          Button(
                            height: 46.w,
                            child: Text('common.enter.now'.tr()),
                            onPressed: () => {
                              appRouter.push(
                                '/product/${item.treasureId}',
                              ),
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 20.w,)
      ],
    );
  }
}

class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int id;

  const AnimatedListItem({super.key, required this.child, required this.id});

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.id.toString()),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0 && !_visible) {
          setState(() {
            _visible = true;
          });
        }
      },
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0.8,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: _visible ? 1 : 0.95,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 300),
          child: widget.child,
        ),
      ),
    );
  }
}
