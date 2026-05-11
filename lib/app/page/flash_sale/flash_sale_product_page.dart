import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/components/swiper_banner.dart';
import 'package:flutter_app/core/models/flash_sale.dart';
import 'package:flutter_app/core/providers/flash_sale_provider.dart';
import 'package:flutter_app/ui/html/product_html_content.dart';
import 'package:flutter_app/ui/img/optimized_image.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ---------------------------------------------------------------------------
// Flash Sale Product Detail Page
// Route: /flash-sale/products/:id  (id = flashSaleProductId)
// ---------------------------------------------------------------------------
class FlashSaleProductPage extends ConsumerWidget {
  final String flashSaleProductId;

  const FlashSaleProductPage({super.key, required this.flashSaleProductId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(flashSaleProductDetailProvider(flashSaleProductId));

    return detailAsync.when(
      loading: () => const _DetailSkeleton(),
      error: (err, _) => BaseScaffold(
        title: 'Flash Sale',
        body: _ErrorBody(
          message: err.toString(),
          onRetry: () => ref.invalidate(flashSaleProductDetailProvider(flashSaleProductId)),
        ),
      ),
      data: (detail) => _DetailBody(detail: detail),
    );
  }
}

class _DetailBody extends StatefulWidget {
  final FlashSaleProductDetail detail;
  const _DetailBody({required this.detail});

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = Duration(milliseconds: math.max(0, widget.detail.session.remainingMs));
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

  bool get _isEnded => _remaining.inSeconds <= 0;
  bool get _isSoldOut => widget.detail.isSoldOut;
  bool get _canBuy => !_isEnded && !_isSoldOut;

  void _goToCheckout() {
    appRouter.push(
      '/payment?treasureId=${widget.detail.treasureId}&flashSaleProductId=${widget.detail.id}&isGroupBuy=false',
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final flashPrice = double.tryParse(detail.flashPrice) ?? 0.0;
    final originalPrice = double.tryParse(detail.product.unitAmount) ?? 0.0;
    final images = detail.product.mainImageList.isNotEmpty
        ? detail.product.mainImageList
        : [detail.product.treasureCoverImg ?? ''];
    final int discountPct = (originalPrice > 0 && flashPrice < originalPrice)
        ? ((1 - flashPrice / originalPrice) * 100).round()
        : 0;

    return BaseScaffold(
      title: '⚡ Flash Sale',
      bottomNavigationBar: _BottomBar(
        canBuy: _canBuy,
        isEnded: _isEnded,
        isSoldOut: _isSoldOut,
        discountPct: discountPct,
        onBuy: _goToCheckout,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部图片：多图轮播，单图优化加载
            if (images.length > 1)
              SwiperBanner(
                width: 1.sw,
                height: 280.w,
                borderRadius: 0,
                banners: images,
                blurhash: detail.product.blurhash,
              )
            else
              OptimizedImageFactory.banner(
                url: images.first,
                width: 1.sw,
                height: 280.w,
                borderRadius: BorderRadius.zero,
                blurhash: detail.product.blurhash,
              ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _PriceCountdownRow(
                flashPrice: flashPrice,
                originalPrice: originalPrice,
                discountPct: discountPct,
                remaining: _remaining,
                isEnded: _isEnded,
              ),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _StockBar(flashStock: detail.flashStock, isSoldOut: _isSoldOut),
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                detail.product.treasureName,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: context.textPrimary900),
              ),
            ),
            if (detail.product.productName != null && detail.product.productName!.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(detail.product.productName!, style: TextStyle(fontSize: 13.sp, color: context.textSecondary700)),
              ),
            ],
            SizedBox(height: 16.h),
            if (detail.product.desc != null && detail.product.desc!.isNotEmpty) ...[
              _SectionDivider(title: 'Description'),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: ProductHtmlContent(
                  html: detail.product.desc!,
                  textStyle: TextStyle(fontSize: 13.sp, color: context.textSecondary700, height: 1.6),
                ),
              ),
            ],
            if (detail.product.ruleContent != null && detail.product.ruleContent!.isNotEmpty) ...[
              _SectionDivider(title: 'Rules'),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: ProductHtmlContent(
                  html: detail.product.ruleContent!,
                  textStyle: TextStyle(fontSize: 13.sp, color: context.textSecondary700, height: 1.6),
                ),
              ),
            ],
            SizedBox(height: 120.h),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Price + countdown row widget
// ---------------------------------------------------------------------------
class _PriceCountdownRow extends StatelessWidget {
  final double flashPrice;
  final double originalPrice;
  final int discountPct;
  final Duration remaining;
  final bool isEnded;

  const _PriceCountdownRow({
    required this.flashPrice,
    required this.originalPrice,
    required this.discountPct,
    required this.remaining,
    required this.isEnded,
  });

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: isEnded
            ? LinearGradient(colors: [Colors.grey.shade200, Colors.grey.shade300])
            : const LinearGradient(colors: [Color(0xFFFFF1F0), Color(0xFFFFE7E7)]),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isEnded ? Colors.grey.shade400 : const Color(0xFFFF4D4F).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt, color: isEnded ? Colors.grey : Colors.red, size: 20.w),
                  Text(
                    FormatHelper.formatCurrency(flashPrice),
                    style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w900, color: isEnded ? Colors.grey : Colors.red),
                  ),
                  if (discountPct > 0 && !isEnded) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4.r)),
                      child: Text(
                        '$discountPct% OFF',
                        style: TextStyle(fontSize: 10.sp, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              if (originalPrice > flashPrice)
                Text(
                  FormatHelper.formatCurrency(originalPrice),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.textQuaternary500,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: context.textQuaternary500,
                  ),
                ),
            ],
          ),
          const Spacer(),
          if (isEnded)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(20.r)),
              child: Text('Ended', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp)),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Ends in', style: TextStyle(fontSize: 10.sp, color: Colors.red.shade700)),
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6.r)),
                  child: Text(
                    _fmt(remaining),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stock bar widget
// ---------------------------------------------------------------------------
class _StockBar extends StatelessWidget {
  final int flashStock;
  final bool isSoldOut;

  const _StockBar({required this.flashStock, required this.isSoldOut});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isSoldOut ? Icons.inventory_2_outlined : Icons.inventory_2,
          size: 16.w,
          color: isSoldOut ? Colors.grey : Colors.orange,
        ),
        SizedBox(width: 6.w),
        Text(
          isSoldOut ? 'Sold Out' : '$flashStock left in stock',
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: isSoldOut ? Colors.grey : Colors.orange.shade700),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section divider with title
// ---------------------------------------------------------------------------
class _SectionDivider extends StatelessWidget {
  final String title;

  const _SectionDivider({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Container(width: 3.w, height: 16.h, color: Colors.red, margin: EdgeInsets.only(right: 8.w)),
          Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: context.textPrimary900)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom CTA bar
// ---------------------------------------------------------------------------
class _BottomBar extends StatelessWidget {
  final bool canBuy;
  final bool isEnded;
  final bool isSoldOut;
  final int discountPct;
  final VoidCallback onBuy;

  const _BottomBar({
    required this.canBuy,
    required this.isEnded,
    required this.isSoldOut,
    required this.discountPct,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final label = isSoldOut
        ? 'Sold Out'
        : isEnded
            ? 'Flash Sale Ended'
            : discountPct > 0
                ? '⚡ Buy Now · Save $discountPct%'
                : '⚡ Buy Now (Flash Price)';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            onPressed: canBuy ? onBuy : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canBuy ? Colors.red : Colors.grey.shade300,
              disabledBackgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.grey.shade600,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: Text(label, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton — mirrors the detail page layout so perceived load is instant
// ---------------------------------------------------------------------------
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: '⚡ Flash Sale',
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner image placeholder
            Skeleton.react(
              width: double.infinity,
              height: 280,
              borderRadius: BorderRadius.zero,
            ),
            SizedBox(height: 12.h),
            // Price + countdown row placeholder
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                height: 80.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.all(14.w),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Skeleton.react(width: 120.w, height: 28.h, borderRadius: BorderRadius.circular(6.r)),
                        SizedBox(height: 6.h),
                        Skeleton.react(width: 80.w, height: 14.h, borderRadius: BorderRadius.circular(4.r)),
                      ],
                    ),
                    const Spacer(),
                    Skeleton.react(width: 90.w, height: 40.h, borderRadius: BorderRadius.circular(6.r)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
            // Stock bar placeholder
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Skeleton.react(width: 140.w, height: 18.h, borderRadius: BorderRadius.circular(4.r)),
            ),
            SizedBox(height: 16.h),
            // Title placeholder
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Skeleton.react(width: double.infinity, height: 22.h, borderRadius: BorderRadius.circular(4.r)),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Skeleton.react(width: 200.w, height: 16.h, borderRadius: BorderRadius.circular(4.r)),
            ),
            SizedBox(height: 24.h),
            // Description placeholder lines
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: List.generate(
                  5,
                  (i) => Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Skeleton.react(
                      width: i == 4 ? 160.w : double.infinity,
                      height: 14.h,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error body
// ---------------------------------------------------------------------------
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
          Text('Failed to load', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
          SizedBox(height: 8.h),
          Text(message, style: TextStyle(fontSize: 12.sp, color: context.textSecondary700), textAlign: TextAlign.center),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
