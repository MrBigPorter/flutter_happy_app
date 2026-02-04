//  必须引入
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:flutter_app/core/models/product_list_item.dart';

import '../../../theme/design_tokens.g.dart';
import '../../routes/app_router.dart';

// ==============================================================================
// 1. 主组件: GroupBuyingSection (首页调用的入口)
// ==============================================================================
class GroupBuyingSection extends StatelessWidget {
  final List<ProductListItem>? list;
  final String title;

  const GroupBuyingSection({
    super.key,
    required this.list,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (list == null || list!.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 标题栏 ---
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
          child: Row(
            children: [
              // 红色竖线装饰
              Container(
                width: 4.w,
                height: 16.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D4F),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 8.w),
              // 标题文字 (title 通常由外部传入，如果外部传的是 key，记得在外部 .tr()，或者在这里 .tr())
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary900,
                  height: 1.1,
                ),
              ),
              const Spacer(),
              // "更多"按钮
              GestureDetector(
                onTap: () {
                  appRouter.pushNamed('groups');
                },
                child: Row(
                  children: [
                    Text(
                      // 🌐 国际化：More
                      'home_group.btn_more'.tr(),
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

        // --- 横向滚动列表 ---
        SizedBox(
          height: 140.w,
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

        // 底部留一点白，防止卡片阴影被切掉
        SizedBox(height: 16.h),
      ],
    );
  }
}

// ==============================================================================
// 2. 单个卡片组件: GroupBuyingCard
// ==============================================================================
class GroupBuyingCard extends StatelessWidget {
  final ProductListItem item;

  const GroupBuyingCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // --- 🛠️ 数据处理与容错 (Data Mapping) ---

    // 1. 进度条 (空安全处理，默认为 0)
    final double progress = item.buyQuantityRate ?? 0.0;

    // 2. 剩余百分比 (防止计算出负数)
    final int remainingPercent = ((1.0 - progress) * 100).toInt().clamp(1, 100);

    // 3. 参与人数 (优先用 seqBuyQuantity，没有则用 betCount，再没有就是 0)
    final int totalJoins = item.seqBuyQuantity ?? 0;

    // 4. 用户是否已加入 (需确保 Model 里有 isJoined 字段)
    final bool isJoined = item.isJoined ?? false;

    // 5. 头像列表 (如果有真实数据就用，没有就用假数据兜底，或者显示空列表)
    final List<String> displayAvatars = (item.recentJoinAvatars != null && item.recentJoinAvatars!.isNotEmpty)
        ? item.recentJoinAvatars!
        : [
      // 兜底假头像，为了让 UI 好看点

    ];

    return GestureDetector(
      onTap: () {
        //  点击跳转详情页
        context.pushNamed(
          'productDetail',
          pathParameters: {'id': item.treasureId},
          // 如果已经加入了，就不自动打开拼团弹窗了
          queryParameters: {'autoOpenGroup': isJoined ? 'false' : 'true'},
        );
            },
      child: Container(
        width: 300.w, // 卡片宽度
        decoration: BoxDecoration(
          color: context.bgPrimary,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(10.w),
              child: Row(
                children: [
                  // 左侧商品图
                  _buildProductImage(context),

                  SizedBox(width: 12.w),

                  // 右侧信息栏
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 上半部分：标题 + 进度
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              // 🌐 国际化：商品名 fallback
                              item.treasureName ?? 'home_group.fallback_product_name'.tr(),
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
                            _buildProgressSection(context, progress, remainingPercent),
                          ],
                        ),

                        // 下半部分：头像 + 按钮
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AvatarStack(avatars: displayAvatars, total: totalJoins),
                            //  传入加入状态
                            _buildJoinButton(context, isJoined),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 左上角 "HOT" 标签
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D4F),
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
                      // 🌐 国际化：HOT / Sikat
                      'home_group.label_hot'.tr(),
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
      ),
    );
  }

  // --- 子组件提取 ---

  Widget _buildProductImage(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: CachedNetworkImage(
          imageUrl: item.treasureCoverImg ?? '',
          width: 90.w,
          height: 110.w,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: Colors.grey[200],
            width: 90.w,
            height: 110.w,
          ),
          errorWidget: (_, __, ___) => Container(
            color: Colors.grey[200],
            width: 90.w,
            height: 110.w,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, double progress, int remaining) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 进度条轨道
        Container(
          height: 6.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFF8A00).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3.r),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3.r),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A00), Color(0xFFFF4D4F)],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 4.h),
        // 进度文字
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 10.sp, fontFamily: 'Roboto'),
            children: [
              // 🌐 国际化：前缀 "Only "
              TextSpan(
                text: 'home_group.progress_prefix'.tr(),
                style: TextStyle(color: context.textQuaternary500),
              ),
              // 数字 (保持红色高亮)
              TextSpan(
                text: '$remaining%',
                style: TextStyle(
                  color: const Color(0xFFFF4D4F),
                  fontWeight: FontWeight.bold,
                ),
              ),
              // 🌐 国际化：后缀 " left"
              TextSpan(
                text: 'home_group.progress_suffix'.tr(),
                style: TextStyle(color: context.textQuaternary500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJoinButton(BuildContext context, bool isJoined) {
    return Container(
      height: 32.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        // 如果已加入，移除渐变，使用纯色（绿色）；未加入则显示紫色渐变
        gradient: isJoined
            ? null
            : const LinearGradient(
          colors: [Color(0xFF722ED1), Color(0xFF9254DE)],
        ),
        color: isJoined ? const Color(0xFF52C41A) : null, // 绿色代表已加入
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          // 未加入时才显示阴影
          if (!isJoined)
            BoxShadow(
              color: const Color(0xFF722ED1).withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isJoined) ...[
            Icon(Icons.check, size: 12.sp, color: Colors.white),
            SizedBox(width: 4.w),
          ],
          Text(
            // 🌐 国际化：根据状态切换文案 (Joined vs Join)
            isJoined ? 'home_group.btn_joined'.tr() : 'home_group.btn_join'.tr(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// 3. 辅助组件: AvatarStack (头像堆叠)
// ==============================================================================
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
                    border: Border.all(color: Colors.white, width: 2),
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
        if (total > 0) ...[
          SizedBox(width: 4.w),
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
        ]
      ],
    );
  }
}

// ==============================================================================
// 4. 辅助组件: GroupBuyingItemWrapper (入场动画)
// ==============================================================================
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