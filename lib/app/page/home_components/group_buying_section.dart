import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:visibility_detector/visibility_detector.dart';

// 假设引用 (保持你的原有引用)
import 'package:flutter_app/common.dart'; // 包含颜色定义
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/components/skeleton.dart';

/// ---------------------------------------------------------
/// 团购/正在进行模块 (Type 5 - 旗舰视觉升级版)
/// ---------------------------------------------------------
class GroupBuyingSection extends StatelessWidget {
  final List<ProductListItem>? list;
  final String title;

  const GroupBuyingSection({super.key, required this.list, required this.title});

  @override
  Widget build(BuildContext context) {
    if (list == null || list!.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 标题区域：增加 ICON 和 副标题，提升精致度
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
          child: Row(
            children: [
              // 装饰性竖条
              Container(
                width: 4.w,
                height: 16.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D4F), // 火热红
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary900, // 假设这是白色或深黑色
                  height: 1.1,
                ),
              ),
              const Spacer(),
              // See All 按钮优化
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      'More',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.textQuaternary500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10.sp,
                      color: context.textQuaternary500,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. 列表区域
        SizedBox(
          height: 140.w, // 高度稍微收紧，显得更精致
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: list!.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final item = list![index];
              return GroupBuyingItemWrapper(
                uniqueKey: item.treasureId,
                index: index,
                child: GroupBuyingCard(item: item),
              );
            },
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}

/// ---------------------------------------------------------
/// 团购卡片 (视觉核心)
/// ---------------------------------------------------------
class GroupBuyingCard extends StatelessWidget {
  final ProductListItem item;

  const GroupBuyingCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // 模拟头像
    final mockAvatars = [
      'https://i.pravatar.cc/150?img=12',
      'https://i.pravatar.cc/150?img=23',
      'https://i.pravatar.cc/150?img=35',
    ];

    // 计算进度
    final double progress = item.buyQuantityRate;
    final int remainingPercent = (100 - progress * 100).toInt();

    return Container(
      width: 300.w, // 宽度加宽，像一张"门票"
      decoration: BoxDecoration(
        // ✨ 背景升级：使用微弱的渐变色，而不是纯色，更有质感
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.bgSecondary, // 深色背景
            context.bgSecondary.withValues(alpha: 0.8), // 稍微变一点
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        // ✨ 阴影：增加立体感
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 内容布局
          Padding(
            padding: EdgeInsets.all(10.w),
            child: Row(
              children: [
                // --- 左侧：商品图 ---
                _buildProductImage(context),

                SizedBox(width: 12.w),

                // --- 右侧：信息流 ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 1. 标题区域
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.treasureName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary900,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          // 进度条 + 文字
                          _buildProgressSection(context, progress, remainingPercent),
                        ],
                      ),

                      // 2. 底部区域 (头像 + 按钮)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // 社交证明
                          AvatarStack(avatars: mockAvatars, total: 128),

                          // 抢购按钮
                          _buildJoinButton(context),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ✨ 视觉标签：左上角的 "HOT"
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D4F), // 鲜艳红
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(12.r),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department, color: Colors.white, size: 10.sp),
                  SizedBox(width: 2.w),
                  Text(
                    'HOT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
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

  /// 构建商品图片 (带阴影和圆角)
  Widget _buildProductImage(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: CachedNetworkImage(
          imageUrl: item.treasureCoverImg ?? '',
          width: 90.w, // 图片稍微改小一点，给右边留空间
          height: 110.w, // 长方形构图更像海报
          fit: BoxFit.cover,
          placeholder: (_, __) => Skeleton.react(width: 90.w, height: 110.w),
        ),
      ),
    );
  }

  /// 构建进度条区域
  Widget _buildProgressSection(BuildContext context, double progress, int remaining) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 进度条背景
        Container(
          height: 6.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.bgPrimary, // 浅色底槽
            borderRadius: BorderRadius.circular(3.r),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3.r),
                // ✨ 渐变色进度条：从橙到红，更有活力
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7A45), Color(0xFFFF4D4F)],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 4.h),
        // 剩余百分比文字
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 10.sp, fontFamily: 'AppFont'), // 确保用你的字体
            children: [
              TextSpan(
                text: 'Only ',
                style: TextStyle(color: context.textQuaternary500),
              ),
              TextSpan(
                text: '$remaining%',
                style: TextStyle(
                  color: const Color(0xFFFF4D4F),
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: ' left',
                style: TextStyle(color: context.textQuaternary500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建抢购按钮
  Widget _buildJoinButton(BuildContext context) {
    return Container(
      height: 32.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        // ✨ 按钮渐变：高亮吸睛
        gradient: const LinearGradient(
          colors: [Color(0xFF722ED1), Color(0xFF9254DE)], // 紫色系 (或者换成主色调)
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF722ED1).withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'Join',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------
/// 头像堆叠组件 (更精致的边框处理)
/// ---------------------------------------------------------
class AvatarStack extends StatelessWidget {
  final List<String> avatars;
  final int total;

  const AvatarStack({super.key, required this.avatars, required this.total});

  @override
  Widget build(BuildContext context) {
    final displayAvatars = avatars.take(3).toList();
    const double size = 26.0;
    const double overlap = 10.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size * displayAvatars.length - (overlap * (displayAvatars.length - 1)),
          height: size,
          child: Stack(
            children: List.generate(displayAvatars.length, (index) {
              return Positioned(
                left: index * (size - overlap),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // ✨ 关键细节：边框颜色要和卡片背景色一致 (context.bgSecondary)
                    // 这样才能产生"切割"前一个头像的效果
                    border: Border.all(color: context.bgSecondary, width: 2),
                    image: DecorationImage(
                      image: NetworkImage(displayAvatars[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(width: 4.w),
        // 火热图标 + 人数
        Row(
          children: [
            Icon(Icons.bolt, size: 12.sp, color: Colors.amber),
            Text(
              '$total+',
              style: TextStyle(
                fontSize: 10.sp,
                color: context.textTertiary600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------
/// 动画包装器 (保持原样，无需改动)
/// ---------------------------------------------------------
class GroupBuyingItemWrapper extends StatefulWidget {
  final Widget child;
  final String uniqueKey;
  final int index;

  const GroupBuyingItemWrapper({
    super.key,
    required this.child,
    required this.index,
    required this.uniqueKey,
  });

  @override
  State<GroupBuyingItemWrapper> createState() => _GroupBuyingItemWrapperState();
}

class _GroupBuyingItemWrapperState extends State<GroupBuyingItemWrapper>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    if (widget.index == 0) _startAnimation(isFast: false, forceSync: true);
  }

  void _startAnimation({required bool isFast, bool forceSync = false}) {
    if (_hasStarted) return;
    _hasStarted = true;
    if (isFast) {
      _controller.value = 1.0;
    } else {
      final delayMs = 50 * (widget.index % 4);
      if (delayMs == 0 || forceSync) {
        _controller.forward();
      } else {
        Future.delayed(Duration(milliseconds: delayMs), () {
          if (mounted) _controller.forward();
        });
      }
    }
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
    return VisibilityDetector(
      key: Key('group_buy_${widget.uniqueKey}_${widget.index}'),
      onVisibilityChanged: (info) {
        if (_hasStarted) return;
        if (info.visibleFraction > 0.01) {
          bool isFast = widget.index >= 3 && (info.visibleFraction > 0.6);
          _startAnimation(isFast: isFast);
        }
      },
      child: widget.child
          .animate(controller: _controller, autoPlay: false)
          .fadeIn(duration: 400.ms)
          .slideX(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
    );
  }
}