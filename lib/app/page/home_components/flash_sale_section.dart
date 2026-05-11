import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/render_countdown.dart';
import 'package:flutter_app/core/models/flash_sale.dart';
import 'package:flutter_app/core/providers/flash_sale_provider.dart';
import 'package:flutter_app/ui/img/optimized_image.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ---------------------------------------------------------------------------
// Home Flash Sale Entry Section
// Shows: header with session countdown + horizontal product scroll
// Hidden automatically when no active sessions
// ---------------------------------------------------------------------------
class FlashSaleSection extends ConsumerWidget {
  const FlashSaleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(flashSaleActiveSessionsProvider);

    return sessionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (sessions) {
        if (sessions.isEmpty) return const SizedBox.shrink();
        // Show section for the first active session (most prominent)
        return _SessionBanner(session: sessions.first);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Single session banner with countdown + product horizontal list
// ---------------------------------------------------------------------------
class _SessionBanner extends ConsumerWidget {
  final FlashSaleSession session;

  const _SessionBanner({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(flashSaleSessionProductsProvider(session.id));

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.utilityBrand600, context.utilityOrange500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: context.shadowLg01,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + countdown + "See All" link
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 8.h),
            child: Row(
              children: [
                Icon(Icons.bolt, color: context.textWhite, size: 20.w),
                SizedBox(width: 4.w),
                Text(
                  'Flash Sale',
                  style: TextStyle(
                    color: context.textWhite,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 10.w),
                _HomeCountdown(remainingMs: session.remainingMs),
                const Spacer(),
                GestureDetector(
                  onTap: () => appRouter.push('/flash-sale'),
                  child: Row(
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          color: context.textPrimary900,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: context.textPrimary900,
                        size: 16.w,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Products horizontal scroll
          productsAsync.when(
            loading: () => SizedBox(
              height: 140.h,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: context.textWhite,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
            error: (error, stackTrace) => SizedBox(
              height: 80.h,
              child: Center(
                child: Text(
                  'Could not load products',
                  style: TextStyle(
                    color: context.textSecondaryOnBrand,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ),
            data: (data) {
              if (data.list.isEmpty) return const SizedBox.shrink();
              final isEnded = session.remainingMs <= 0;
              return SizedBox(
                height: 155.h,
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
                  scrollDirection: Axis.horizontal,
                  itemCount: data.list.length,
                  separatorBuilder: (context, index) => SizedBox(width: 10.w),
                  itemBuilder: (ctx, i) => _MiniProductCard(
                    item: data.list[i],
                    sessionEnded: isEnded,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact countdown widget for home header
// 【修复 P2】改订 globalCountdownTick（全局单例心跳），
// 不再独立创建 Timer.periodic，全页面所有倒计时共享同一个底层 Timer。
// ---------------------------------------------------------------------------
class _HomeCountdown extends StatefulWidget {
  final int remainingMs;

  const _HomeCountdown({required this.remainingMs});

  @override
  State<_HomeCountdown> createState() => _HomeCountdownState();
}

class _HomeCountdownState extends State<_HomeCountdown> {
  late Duration _remaining;
  StreamSubscription<DateTime>? _sub;

  @override
  void initState() {
    super.initState();
    _remaining = Duration(milliseconds: math.max(0, widget.remainingMs));
    if (_remaining.inSeconds > 0) {
      // 订阅全局心跳，与所有 RenderCountdown 共用同一个 Timer
      _sub = globalCountdownTick.listen((_) {
        if (!mounted) return;
        setState(() {
          if (_remaining.inSeconds > 0) {
            _remaining -= const Duration(seconds: 1);
          } else {
            _sub?.cancel();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.inSeconds <= 0) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          'Ended',
          style: TextStyle(
            color: context.textWhite,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        '$h:$m:$s',
        style: TextStyle(
          color: context.textWhite,
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini product card for horizontal scroll in home section
// ---------------------------------------------------------------------------
class _MiniProductCard extends ConsumerWidget {
  final FlashSaleProductItem item;
  final bool sessionEnded;

  const _MiniProductCard({required this.item, required this.sessionEnded});

  void _prefetchAndNavigate(BuildContext context, WidgetRef ref) {
    ref.read(flashSaleProductDetailProvider(item.id));
    final coverUrl = item.product.treasureCoverImg;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      precacheImage(NetworkImage(coverUrl), context);
    }
    appRouter.push('/flash-sale/products/${item.id}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSoldOut = item.isSoldOut;
    final isUnavailable = isSoldOut || sessionEnded;
    final flashPrice = double.tryParse(item.flashPrice) ?? 0.0;
    final originalPrice = double.tryParse(item.product.unitAmount) ?? 0.0;

    return GestureDetector(
      onTap: isUnavailable
          ? null
          : () => _prefetchAndNavigate(context, ref),
      child: Container(
        width: 115.w,
        decoration: BoxDecoration(
          color: context.bgPrimary,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: context.borderSecondary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlay
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
                    child: OptimizedImageFactory.product(
                      url: item.product.treasureCoverImg ?? '',
                      width: 115.w,
                      height: 115.w, // 正方形图片
                      borderRadius:  BorderRadius.vertical(top: Radius.circular(10.r)),
                      blurhash: item.product.blurhash,
                    ),
                  ),
                  if (isUnavailable)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.36),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
                      ),
                      child: Center(
                        child: Text(
                          isSoldOut ? 'Sold Out' : 'Ended',
                          style: TextStyle(
                            color: context.textWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Price row
            Padding(
              padding: EdgeInsets.all(6.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.treasureName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary900,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Icon(
                        Icons.bolt,
                        color: context.textErrorPrimary600,
                        size: 11.w,
                      ),
                      Flexible(
                        child: Text(
                          FormatHelper.formatCurrency(flashPrice),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: context.textErrorPrimary600,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (originalPrice > flashPrice)
                    Text(
                      FormatHelper.formatCurrency(originalPrice),
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: context.textDisabled,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: context.textDisabled,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}