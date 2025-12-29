import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/render_countdown.dart';
import 'package:flutter_app/ui/bubble_progress.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/ui/img/app_image.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_app/core/models/index.dart';

class SpecialArea extends StatelessWidget {
  final List<ProductListItem>? list;
  final String title;

  const SpecialArea({super.key, required this.list, required this.title});

  @override
  Widget build(BuildContext context) {
    // 数据为空时不渲染任何内容
    if (list == null || list!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 1. 标题区域 Title Area
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

        /// 2. 列表容器 List Container
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(children: _buildListItems(context)),
        ),

        SizedBox(height: 20.h),
      ],
    );
  }

  /// 手动构建列表项与分割线
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

      // 添加商品卡片
      items.add(
        GestureDetector(
          onTap: () => appRouter.push('/product/${item.treasureId}'),
          behavior: HitTestBehavior.opaque, // 确保整个区域可点击
          child: Container(
            // 这里只设置 Top, Left, Right padding
            padding: EdgeInsets.only(left: 12.w, right: 12.w, top: 12.h),
            decoration: BoxDecoration(
              color: context.bgPrimary,
              borderRadius: borderRadius,
            ),
            child: Column(
              children: [
                AnimatedListItem(
                  uniqueKey: item.treasureId,
                  title: title,
                  index: i,
                  child: _buildSingleItemContent(context, item),
                ),

                // 统一的底部间距 (无论有无分割线，都需要这个间距来平衡顶部 padding)
                SizedBox(height: 12.h),

                // 分割线 (静态显示，不做动画)
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

  /// 构建单个商品的内部布局
  Widget _buildSingleItemContent(BuildContext context, ProductListItem item) {
    return Column(
      children: [
        /// 上半部分：图片 + 标题 + 进度条
        Row(
          children: [
            /// 商品图片
            AppCachedImage(
              item.treasureCoverImg ?? '',
              width: 80.w,
              height: 80.w, // 正方形保持 w
              fit: BoxFit.cover,
              radius: BorderRadius.circular(8.r),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 标题
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
                  SizedBox(height: 4.h), // 稍微增加一点间距
                  /// 进度条
                  BubbleProgress(
                    value: item.buyQuantityRate ?? 0.0, // 空安全
                    showTipBg: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        /// 下半部分：价格 + 倒计时 + 按钮
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 价格列
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
            Spacer(),

            // 倒计时列
            RenderCountdown(
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

            Spacer(),

            // 按钮 (仅作视觉展示，点击事件由父级 GestureDetector 接管)
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

  /// 提取公共状态文本样式
  Widget _buildStatusColumn(
    BuildContext context,
    String top,
    String bottom, {
    bool isError = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          top,
          style: TextStyle(
            fontSize: context.textXs,
            color: context.textQuaternary500,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          bottom,
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

/// ---------------------------------------------------------
/// 动画列表项组件
/// ---------------------------------------------------------
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final String uniqueKey;
  final int index;
  final String title;
  final VoidCallback? onTap;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    required this.uniqueKey,
    required this.title,
    this.onTap,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

//  1. 混入 SingleTickerProviderStateMixin 以支持手动控制器
class _AnimatedListItemState extends State<AnimatedListItem>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  //  2. 自己持有控制器，不再依赖库的回调，保证永远非空
  late final AnimationController _controller;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    // 初始化控制器，时长 400ms
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return  VisibilityDetector(
      key: Key(
        'special_area_item_${widget.uniqueKey}_${widget.index}_${widget.title}',
      ),
      onVisibilityChanged: (info) {
        // 如果动画已经跑过，就直接忽略，节省性能
        if (_hasStarted) return;

        // 只要露头 > 1% 就开始处理
        if (info.visibleFraction > 0.01) {
          _hasStarted = true;

          // 判定逻辑
          bool isTopItem = widget.index < 6;
          bool isFast =
              !isTopItem &&
                  (info.visibleFraction > 0.6 || info.visibleFraction == 1.0);

          if (isFast) {
            // ：直接拉到终点 (value = 1.0)
            _controller.value = 1.0;
          } else {
            //  慢滑/首屏：计算瀑布流延迟
            final delayMs = 30 * (widget.index % 5);

            if (delayMs == 0) {
              // 必须同步调用！不能用 Future！
              _controller.forward();
            } else {
              // 其他 Index：手动延迟
              Future.delayed(Duration(milliseconds: delayMs), () {
                if (mounted) {
                  _controller.forward();
                }
              });
            }
          }
        }
      },
      child: _buildAnimatedContent(),
    );
  }

  Widget _buildAnimatedContent() {
    return widget.child
        .animate(
          //  3. 把我们自己的控制器交给它
          controller: _controller,
          //  4. 必须关闭自动播放，否则它会自动开始
          autoPlay: false,
        )
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideX(
          begin: 0.1,
          end: 0,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        )
        .shimmer(duration: 1000.ms, color: Colors.white.withValues(alpha: 0.4));
  }
}
