import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/core/models/flash_sale.dart';
import 'package:flutter_app/core/providers/flash_sale_provider.dart';
import 'package:flutter_app/ui/img/optimized_image.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ---------------------------------------------------------------------------
// Flash Sale Sessions List Page
// Shows: active session header + countdown + product grid
// ---------------------------------------------------------------------------
class FlashSalePage extends ConsumerWidget {
  const FlashSalePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(flashSaleActiveSessionsProvider);

    return BaseScaffold(
      title: '⚡ Flash Sale',
      body: sessionsAsync.when(
        loading: () => const _FlashSaleListSkeleton(),
        error: (err, _) => _ErrorBody(
          message: err.toString(),
          onRetry: () => ref.invalidate(flashSaleActiveSessionsProvider),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const _EmptyFlashSale();
          }
          return ListView.builder(
            padding: EdgeInsets.only(top: 12.h, bottom: 32.h),
            itemCount: sessions.length,
            itemBuilder: (context, idx) {
              return _SessionSection(session: sessions[idx]);
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-session section: header countdown + product list
// Uses ConsumerStatefulWidget so _isEnded updates live via a one-shot timer.
// ---------------------------------------------------------------------------
class _SessionSection extends ConsumerStatefulWidget {
  final FlashSaleSession session;

  const _SessionSection({required this.session});

  @override
  ConsumerState<_SessionSection> createState() => _SessionSectionState();
}

class _SessionSectionState extends ConsumerState<_SessionSection> {
  late bool _isEnded;
  Timer? _endTimer;

  @override
  void initState() {
    super.initState();
    final remaining = widget.session.remainingMs;
    _isEnded = remaining <= 0;
    if (!_isEnded) {
      // Fire once when the session actually expires so product cards update.
      _endTimer = Timer(Duration(milliseconds: remaining), () {
        if (mounted) setState(() => _isEnded = true);
      });
    }
  }

  @override
  void dispose() {
    _endTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(flashSaleSessionProductsProvider(widget.session.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SessionHeader(session: widget.session),
        SizedBox(height: 8.h),
        productsAsync.when(
          loading: () => _ProductGridSkeleton(),
          error: (err, _) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text('Failed to load products', style: TextStyle(color: Colors.red, fontSize: 12.sp)),
          ),
          data: (data) {
            if (data.list.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Text('No products in this session.', style: TextStyle(color: context.textSecondary700, fontSize: 13.sp)),
              );
            }
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                  childAspectRatio: 0.72,
                ),
                itemCount: data.list.length,
                itemBuilder: (ctx, i) => _ProductCard(
                  item: data.list[i],
                  sessionEnded: _isEnded,
                ),
              ),
            );
          },
        ),
        SizedBox(height: 24.h),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Session header: title + countdown badge
// ---------------------------------------------------------------------------
class _SessionHeader extends StatefulWidget {
  final FlashSaleSession session;

  const _SessionHeader({required this.session});

  @override
  State<_SessionHeader> createState() => _SessionHeaderState();
}

class _SessionHeaderState extends State<_SessionHeader> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = Duration(milliseconds: math.max(0, widget.session.remainingMs));
    if (_remaining.inSeconds > 0) _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining -= const Duration(seconds: 1);
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final ended = _remaining.inSeconds <= 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: ended
            ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade600])
            : const LinearGradient(
                colors: [Color(0xFFFF4D4F), Color(0xFFFF7A45)],
              ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt, color: Colors.white, size: 22.w),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              widget.session.title.isNotEmpty ? widget.session.title : 'Flash Sale',
              style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (ended)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text('Ended', style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ends in', style: TextStyle(color: Colors.white70, fontSize: 10.sp)),
                _CountdownChips(duration: _remaining),
              ],
            ),
        ],
      ),
    );
  }
}

/// HH:MM:SS chips styled as individual digit blocks
class _CountdownChips extends StatelessWidget {
  final Duration duration;

  const _CountdownChips({required this.duration});

  @override
  Widget build(BuildContext context) {
    final h = (duration.inHours).toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip(h),
        _sep(),
        _chip(m),
        _sep(),
        _chip(s),
      ],
    );
  }

  Widget _chip(String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(val, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
    );
  }

  Widget _sep() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Text(':', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
  );
}

// ---------------------------------------------------------------------------
// Product card in the grid
// ConsumerWidget so we can pre-warm the detail provider on tap before the
// route transition begins — avoids the blank skeleton on slow connections.
// ---------------------------------------------------------------------------
class _ProductCard extends ConsumerWidget {
  final FlashSaleProductItem item;
  final bool sessionEnded;

  const _ProductCard({required this.item, required this.sessionEnded});

  void _prefetchAndNavigate(BuildContext context, WidgetRef ref) {
    // 1. Warm the detail provider so the API call is in-flight during route push.
    ref.read(flashSaleProductDetailProvider(item.id));
    // 2. Pre-warm cover image into the Flutter image cache.
    final coverUrl = item.product.treasureCoverImg;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      precacheImage(NetworkImage(coverUrl), context);
    }
    // 3. Navigate.
    appRouter.push('/flash-sale/products/${item.id}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSoldOut = item.isSoldOut;
    final isUnavailable = isSoldOut || sessionEnded;
    final flashPrice = double.tryParse(item.flashPrice) ?? 0.0;
    final originalPrice = double.tryParse(item.product.unitAmount) ?? 0.0;
    final int discountPct = (originalPrice > 0 && flashPrice < originalPrice)
        ? ((1 - flashPrice / originalPrice) * 100).round()
        : 0;

    return GestureDetector(
      onTap: isUnavailable
          ? null
          : () => _prefetchAndNavigate(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: context.bgPrimary,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with sold-out / ended overlay
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
                    child: OptimizedImageFactory.product(
                      url: item.product.treasureCoverImg ?? '',
                      width: (1.sw / 2) - 22.w,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
                      blurhash: item.product.blurhash,
                    ),
                  ),
                  if (isUnavailable)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
                      ),
                      child: Center(
                        child: Text(
                          isSoldOut ? 'Sold Out' : 'Ended',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
                        ),
                      ),
                    ),
                  // 折扣 badge
                  if (discountPct > 0 && !isUnavailable)
                    Positioned(
                      top: 6.h,
                      left: 6.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '$discountPct% OFF',
                          style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info panel
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.treasureName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: context.textPrimary900),
                  ),
                  SizedBox(height: 2.h),
                  // Stock indicator: show remaining count when not sold out
                  if (!item.isSoldOut && !sessionEnded)
                    _StockIndicator(flashStock: item.flashStock),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.bolt, color: Colors.red, size: 13.w),
                      Text(
                        FormatHelper.formatCurrency(flashPrice),
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: Colors.red),
                      ),
                    ],
                  ),
                  if (originalPrice > flashPrice)
                    Text(
                      FormatHelper.formatCurrency(originalPrice),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: context.textQuaternary500,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: context.textQuaternary500,
                      ),
                    ),
                  SizedBox(height: 6.h),
                  // Buy button
                  SizedBox(
                    width: double.infinity,
                    height: 30.h,
                    child: ElevatedButton(
                      onPressed: isUnavailable
                          ? null
                          : () => _prefetchAndNavigate(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isUnavailable ? Colors.grey.shade300 : Colors.red,
                        foregroundColor: isUnavailable ? Colors.grey.shade600 : Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
                      ),
                      child: Text(
                        isSoldOut
                            ? 'Sold Out'
                            : sessionEnded
                                ? 'Ended'
                                : 'Buy Now',
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                      ),
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

// ---------------------------------------------------------------------------
// Compact stock indicator for product cards
// ---------------------------------------------------------------------------
class _StockIndicator extends StatelessWidget {
  final int flashStock;

  const _StockIndicator({required this.flashStock});

  @override
  Widget build(BuildContext context) {
    // Only show urgency label when stock is limited (≤ 20)
    if (flashStock <= 0) return const SizedBox.shrink();

    final isLow = flashStock <= 10;
    final color = isLow ? Colors.deepOrange : Colors.orange.shade700;

    return Row(
      children: [
        Icon(Icons.inventory_2_outlined, size: 10.w, color: color),
        SizedBox(width: 2.w),
        Text(
          isLow ? 'Only $flashStock left!' : '$flashStock left',
          style: TextStyle(fontSize: 9.sp, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Skeletons
// ---------------------------------------------------------------------------
class _FlashSaleListSkeleton extends StatelessWidget {
  const _FlashSaleListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(12.w),
      itemCount: 2,
      itemBuilder: (_, __) => Column(
        children: [
          Skeleton.react(width: double.infinity, height: 60.h, borderRadius: BorderRadius.circular(12.r)),
          SizedBox(height: 10.h),
          _ProductGridSkeleton(),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

class _ProductGridSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10.w,
          mainAxisSpacing: 10.h,
          childAspectRatio: 0.72,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => Skeleton.react(
          width: double.infinity,
          height: double.infinity,
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / Error states
// ---------------------------------------------------------------------------
class _EmptyFlashSale extends StatelessWidget {
  const _EmptyFlashSale();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bolt_outlined, size: 56.w, color: Colors.grey.shade400),
          SizedBox(height: 12.h),
          Text('No active flash sales right now.', style: TextStyle(color: context.textSecondary700, fontSize: 14.sp)),
          SizedBox(height: 8.h),
          Text('Check back later for great deals!', style: TextStyle(color: context.textQuaternary500, fontSize: 12.sp)),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48.w, color: Colors.red.shade300),
          SizedBox(height: 12.h),
          Text('Something went wrong', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: context.textPrimary900)),
          SizedBox(height: 8.h),
          Text(message, style: TextStyle(fontSize: 12.sp, color: context.textSecondary700), textAlign: TextAlign.center),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(CupertinoIcons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

