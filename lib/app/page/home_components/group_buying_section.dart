import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/ui/img/app_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_app/core/models/product_list_item.dart';
import 'package:flutter_app/theme/design_tokens.g.dart';
import 'package:flutter_app/utils/media/remote_url_builder.dart';
import 'package:flutter_app/app/routes/app_router.dart';

// ==============================================================================
// 1. Main Component: GroupBuyingSection
// Optimized: Removed VisibilityDetector, utilizing native lazy-loading for animation
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
        // --- Header Section ---
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
          child: Row(
            children: [
              // Red vertical decorative line
              Container(
                width: 4.w,
                height: 16.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D4F),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 8.w),
              // Title text
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
              // "More" Button
              GestureDetector(
                onTap: () {
                  appRouter.pushNamed('groups');
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

        // --- Horizontal Scrolling List ---
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

              //  Core Optimization: Staggered animation using modulo
              final animationDelay = ((index % 4) * 50).ms;

              return GroupBuyingCard(item: item)
                  .animate(delay: animationDelay) // Trigger instantly upon build
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
            },
          ),
        ),

        // Bottom spacing to prevent shadow clipping
        SizedBox(height: 16.h),
      ],
    );
  }
}

// ==============================================================================
// 2. Individual Card Component: GroupBuyingCard
// ==============================================================================
class GroupBuyingCard extends StatelessWidget {
  final ProductListItem item;

  const GroupBuyingCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // ---  Data Processing & Fallbacks ---

    // 1. Progress (Null-safe, defaults to 0.0)
    final double progress = item.buyQuantityRate ?? 0.0;

    // 2. Remaining percentage (Prevent negative values)
    final int remainingPercent = ((1.0 - progress) * 100).toInt().clamp(1, 100);

    // 3. Total participants (Fallback priority: seqBuyQuantity -> betCount -> 0)
    final int totalJoins = item.seqBuyQuantity ?? 0;

    // 4. User joined status
    final bool isJoined = item.isJoined ?? false;

    // 5. Display avatars list
    final List<String> displayAvatars =
    (item.recentJoinAvatars != null && item.recentJoinAvatars!.isNotEmpty)
        ? item.recentJoinAvatars!
        : []; // Fallback empty list

    return GestureDetector(
      onTap: () {
        // Navigate to product detail page
        context.pushNamed(
          'productDetail',
          pathParameters: {'id': item.treasureId},
          // Do not auto-open group modal if already joined
          queryParameters: {'autoOpenGroup': isJoined ? 'false' : 'true'},
        );
      },
      child: Container(
        width: 300.w, // Fixed card width
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
                  // Left side: Product Image
                  _buildProductImage(context),

                  SizedBox(width: 12.w),

                  // Right side: Info Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Half: Title + Progress
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

                        // Bottom Half: Avatars + Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AvatarStack(avatars: displayAvatars, total: totalJoins),
                            _buildJoinButton(context, isJoined),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Top-left "HOT" Tag
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

  // --- Sub-components ---

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
        // Progress Bar Track
        Container(
          height: 6.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFF8A00).withOpacity(0.2), // Fixed withOpacity
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
        // Progress Text
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

  Widget _buildJoinButton(BuildContext context, bool isJoined) {
    return Container(
      height: 32.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        // Solid green if joined, otherwise purple gradient
        gradient: isJoined
            ? null
            : const LinearGradient(
          colors: [Color(0xFF722ED1), Color(0xFF9254DE)],
        ),
        color: isJoined ? const Color(0xFF52C41A) : null,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
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
// 3. Helper Component: AvatarStack
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