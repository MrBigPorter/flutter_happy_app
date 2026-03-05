import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/ui/img/app_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_app/core/models/product_list_item.dart';
import 'package:flutter_app/theme/design_tokens.g.dart';
import 'package:flutter_app/utils/media/remote_url_builder.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/core/providers/index.dart';

import '../../../features/share/models/share_content.dart';
import '../../../features/share/services/app_share_manager.dart';

// ==============================================================================
// 1. 主区域组件: GroupBuyingSection 
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
        // --- 头部标题栏 ---
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
          child: Row(
            children: [
              // 红色装饰线
              Container(
                width: 4.w,
                height: 16.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D4F),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 8.w),
              // 标题
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
              // 更多按钮
              GestureDetector(
                onTap: () {
                  appRouter.pushNamed('product-groups-detail');
                },
                child: Row(
                  children: [
                    Text(
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

        // --- 横向滑动列表 ---
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

              // 轻量级入场动画：取余实现阶梯延迟
              final animationDelay = ((index % 4) * 50).ms;

              return GroupBuyingCard(item: item)
                  .animate(delay: animationDelay)
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
            },
          ),
        ),

        SizedBox(height: 16.h),
      ],
    );
  }
}

// ==============================================================================
// 2. 单个卡片组件: GroupBuyingCard ( 已升级为 ConsumerWidget)
// ==============================================================================
class GroupBuyingCard extends ConsumerWidget {
  final ProductListItem item;

  const GroupBuyingCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- 数据处理与兜底 ---
    final double progress = item.buyQuantityRate ?? 0.0;
    final int remainingPercent = ((1.0 - progress) * 100).toInt().clamp(1, 100);
    final int totalJoins = item.seqBuyQuantity ?? 0;
    final bool isJoined = item.isJoined ?? false;
    final List<String> displayAvatars =
    (item.recentJoinAvatars != null && item.recentJoinAvatars!.isNotEmpty)
        ? item.recentJoinAvatars!
        : [];

    return GestureDetector(
      //  核心优化：外层点击卡片跳转时，增加 await 等待路由返回
      onTap: () async {
        await appRouter.pushNamed(
          'productDetail',
          pathParameters: {'id': item.treasureId ?? ''},
          queryParameters: {'autoOpenGroup': isJoined ? 'false' : 'true'},
        );

        //  用户返回首页后，静默触发刷新
        ref.read(homeGroupBuyingProvider.notifier).forceRefresh();
        ref.read(homeTreasuresProvider.notifier).forceRefresh();
      },
      child: Container(
        width: 300.w, // 固定卡片宽度
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

                  // 右侧信息区
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 上半部分：标题 + 进度条
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
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

                        // 下半部分：头像堆叠 + 按钮
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            //AvatarStack(avatars: displayAvatars, total: totalJoins),
                            //  传入 ref 供按钮的点击事件使用
                            _buildJoinButton(context, ref, item, isJoined),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 左上角 HOT 标签
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
        child: AppCachedImage(
          RemoteUrlBuilder.fitAbsoluteUrl(item.treasureCoverImg ?? ''),
          width: 90.w,
          height: 110.w,
          fit: BoxFit.cover,
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
            color: const Color(0xFFFF8A00).withOpacity(0.2),
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
              TextSpan(
                text: 'home_group.progress_prefix'.tr(),
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
                text: 'home_group.progress_suffix'.tr(),
                style: TextStyle(color: context.textQuaternary500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  //  带裂变和等待刷新逻辑的按钮
  Widget _buildJoinButton(BuildContext context, WidgetRef ref, ProductListItem item, bool isJoined) {
    return GestureDetector(
      onTap: () async {
        if (isJoined && item.groupId != null) {
          // --- 状态A：已加入 -> 瞬间拉起分享面板，极速裂变 ---
          ShareManager.startShare(
            context,
            ShareContent.group(
              id: item.treasureId ?? '',
              groupId: item.groupId!,
              title: item.treasureName ?? '',
              imageUrl: item.treasureCoverImg ?? '',
              desc: "I just joined this group! We need more people, let's win together!",
            ),
          );
        } else {
          // --- 状态B：未加入 -> 拦截等待跳转详情页 ---
          await appRouter.pushNamed(
            'productDetail',
            pathParameters: {'id': item.treasureId ?? ''},
            queryParameters: {'autoOpenGroup': 'true'},
          );

          //  从详情页返回后，静默触发刷新
          ref.read(homeGroupBuyingProvider.notifier).forceRefresh();
        }
      },
      child: Container(
        height: 32.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          // 视觉优化：已参团用高亮橙红渐变刺激分享
          gradient: isJoined
              ? const LinearGradient(colors: [Color(0xFFFF8A00), Color(0xFFFF4D4F)])
              : const LinearGradient(colors: [Color(0xFF722ED1), Color(0xFF9254DE)]),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: (isJoined ? const Color(0xFFFF4D4F) : const Color(0xFF722ED1)).withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isJoined ? Icons.ios_share_rounded : Icons.group_add_rounded,
              size: 14.sp,
              color: Colors.white,
            ),
            SizedBox(width: 4.w),
            Text(
              // 动态文案
              isJoined ? 'Invite' : 'home_group.btn_join'.tr(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// 3. 辅助组件: AvatarStack (用于渲染左下角的头像堆叠)
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