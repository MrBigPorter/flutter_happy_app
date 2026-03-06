import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/payment/payment_section.dart';
import 'package:flutter_app/app/page/payment/payment_skeleton.dart';
import 'package:flutter_app/app/page/payment_components/insufficient_balance_sheet.dart';
import 'package:flutter_app/app/page/payment_components/payment_success_sheet.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';

import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_app/core/providers/address_provider.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/core/providers/purchase_state_provider.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/core/store/wallet_store.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/ui/modal/sheet/modal_sheet_config.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/core/providers/coupon_provider.dart';
import 'package:flutter_app/core/guards/kyc_guard.dart';

// Logic is separated using 'part' to maintain clean UI code
part 'payment_page_logic.dart';

/// Extension to safely parse the isGroupBuy parameter from various types (bool or String)
extension PagePaymentParamsExt on PagePaymentParams {
  bool get isRealGroupBuy {
    if (isGroupBuy == null) return false;
    return isGroupBuy.toString().toLowerCase() == 'true';
  }
}

/// A notification bar that appears at the top for Group Buy mode
class _GroupTipsBar extends StatelessWidget {
  final bool isJoin;

  const _GroupTipsBar({required this.isJoin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.w),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF7E6),
        border: Border(bottom: BorderSide(color: Color(0xFFFFD591))),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, color: Colors.orange, size: 18.w),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              isJoin
                  ? "You are joining a group. Order will be confirmed after payment."
                  : "You are starting a group. Invite friends after payment.",
              style: TextStyle(
                  color: Colors.orange[900],
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentPage extends ConsumerStatefulWidget {
  final PagePaymentParams params;

  const PaymentPage({super.key, required this.params});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

/// Implementation uses Mixin (PaymentPageLogic) to handle data initialization and coupon validation
class _PaymentPageState extends ConsumerState<PaymentPage> with PaymentPageLogic {
  @override
  void initState() {
    super.initState();
    // Initializes wallet balance, product details, and auto-matching for coupons
    initPaymentData();
  }

  @override
  Widget build(BuildContext context) {
    final params = widget.params;
    final isGroupBuy = params.isRealGroupBuy;
    final isJoinGroup = params.groupId != null && params.groupId!.isNotEmpty;

    // Show skeleton if treasureId is missing (Safety check)
    if (params.treasureId == null) return const PaymentSkeleton();

    // Dynamically validate if the selected coupon still meets the minimum purchase requirement
    listenAndValidateCoupon(params.treasureId!);

    final detail = ref.watch(productDetailProvider(params.treasureId!));

    return detail.when(
      loading: () => const PaymentSkeleton(),
      error: (_, __) => const PaymentSkeleton(),
      data: (value) {
        return BaseScaffold(
          title: 'checkout'.tr(),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard on tap
            child: LayoutBuilder(
              builder: (context, constrains) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constrains.maxHeight),
                    child: Column(
                      children: [
                        if (isGroupBuy) _GroupTipsBar(isJoin: isJoinGroup),
                        const AddressSection(),
                        SizedBox(height: 8.w),
                        ProductSection(detail: value),
                        SizedBox(height: 8.w),
                        InfoSection(detail: value, treasureId: params.treasureId!),
                        SizedBox(height: 8.w),
                        // Optimized Voucher Section (Icon removed)
                        CheckoutVoucherSection(treasureId: params.treasureId!),
                        SizedBox(height: 8.w),
                        PaymentMethodSection(treasureId: params.treasureId!,),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          bottomNavigationBar: _BottomNavigationBar(
            params: params,
            title: value.treasureName ?? '',
            isGroupBuy: isGroupBuy,
          ),
        );
      },
    );
  }
}

class _BottomNavigationBar extends ConsumerStatefulWidget {
  final String title;
  final PagePaymentParams params;
  final bool isGroupBuy;

  const _BottomNavigationBar({
    required this.params,
    required this.title,
    required this.isGroupBuy,
  });

  @override
  ConsumerState<_BottomNavigationBar> createState() => _BottomNavigationBarState();
}

class _BottomNavigationBarState extends ConsumerState<_BottomNavigationBar> with BottomNavigationBarLogic {
  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(purchaseProvider(widget.params.treasureId ?? '').notifier);
    final purchase = ref.watch(purchaseProvider(widget.params.treasureId ?? ''));
    final addressListAsync = ref.watch(addressListProvider);

    final selectedCoupon = ref.watch(selectedCouponProvider);
    final double couponDiscount = double.tryParse(selectedCoupon?.discountValue ?? '0') ?? 0.0;

    final double finalPayable = notifier.payableAmount;

    final isBusy = purchase.isSubmitting || (addressListAsync.isLoading && !addressListAsync.hasValue);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.only(
            left: 16.w, right: 16.w, top: 16.w,
            bottom: ViewUtils.bottomBarHeight + (kIsWeb ? 16.w : 0)
        ),
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.bgPrimary,
          boxShadow: [
            BoxShadow(color: context.shadowMd01.withValues(alpha: 0.1), blurRadius: 10.w, offset: Offset(0, -1.w))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(children: [
                    TextSpan(text: '${'common.total'.tr()}: ', style: TextStyle(color: context.textPrimary900, fontSize: context.textSm, fontWeight: FontWeight.w600)),
                    TextSpan(
                      text: FormatHelper.formatCurrency(finalPayable),
                      style: TextStyle(color: context.textErrorPrimary600, fontSize: context.textLg, fontWeight: FontWeight.w800),
                    ),
                  ]),
                ),
                SizedBox(height: 8.w),
                //  优化展示逻辑：让优惠券和金币抵扣能同时展示，不互相覆盖
                if (couponDiscount > 0)
                  Text(
                    'Voucher Discount: -${FormatHelper.formatCurrency(couponDiscount)}',
                    style: TextStyle(color: context.textErrorPrimary600, fontSize: 11.sp, fontWeight: FontWeight.w600),
                  ),
                if (purchase.useDiscountCoins && notifier.coinAmount > 0)
                  Text(
                    '${'common.total.discount'.tr()} ${FormatHelper.formatCurrency(notifier.coinAmount)}',
                    style: TextStyle(color: context.textErrorPrimary600, fontSize: 11.sp, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            SizedBox(width: 16.w),
            Button(
              width: 120.w,
              height: 40.h,
              loading: isBusy,
              onPressed: submitPayment,
              child: Text('common.checkout'.tr(), style: TextStyle(color: Colors.white, fontSize: context.textMd, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
// =========================================================================
// Specialized Voucher Entry Section for the Checkout Page
// =========================================================================
class CheckoutVoucherSection extends ConsumerWidget {
  final String treasureId;

  const CheckoutVoucherSection({super.key, required this.treasureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch current subtotal to determine coupon eligibility
    final purchaseState = ref.watch(purchaseProvider(treasureId));
    final double orderAmount = purchaseState.subtotal;

    final selectedCoupon = ref.watch(selectedCouponProvider);
    // Optimized: Filters coupons locally in memory to avoid frequent API calls on price change
    final availableAsync = ref.watch(availableCouponsForOrderProvider(orderAmount));
    final availableCount = availableAsync.valueOrNull?.length ?? 0;

    return GestureDetector(
      onTap: () {
        // Show Bottom Sheet to select a coupon
        RadixSheet.show(
          builder: (context, close) {
            return _CouponSelectorBottomSheet(
              orderAmount: orderAmount,
              onClose: close,
            );
          },
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
          decoration: BoxDecoration(
            color: context.bgPrimary,
            borderRadius: BorderRadius.circular(8.w),
          ),
          child: Row(
            children: [
              // Ticket icon removed per request for a cleaner UI
              Text(
                'Platform Voucher',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: context.textPrimary900),
              ),
              const Spacer(),

              // Logic to display: Selected amount OR Number of available coupons OR "None"
              if (selectedCoupon != null) ...[
                Text(
                  '- ₱${selectedCoupon.discountValue}',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.pinkAccent),
                ),
              ] else if (availableCount > 0) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent,
                    borderRadius: BorderRadius.circular(4.w),
                  ),
                  child: Text(
                    '$availableCount Available',
                    style: TextStyle(fontSize: 10.sp, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ] else ...[
                Text(
                  'None',
                  style: TextStyle(fontSize: 14.sp, color: context.textSecondary700),
                ),
              ],

              SizedBox(width: 4.w),
              Icon(CupertinoIcons.chevron_right, size: 16.w, color: context.textSecondary700),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// Bottom Sheet for Selecting Coupons
// =========================================================================
class _CouponSelectorBottomSheet extends ConsumerWidget {
  final double orderAmount;
  final VoidCallback onClose;

  const _CouponSelectorBottomSheet({
    required this.orderAmount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider filters the master list locally for high performance
    final asyncCoupons = ref.watch(availableCouponsForOrderProvider(orderAmount));
    final selectedCoupon = ref.watch(selectedCouponProvider);

    return Column(
      children: [
        Expanded(
          child: asyncCoupons.when(
            data: (list) {
              if (list.isEmpty) {
                return const Center(child: Text('No vouchers available for this order.'));
              }

              return ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  final isSelected = selectedCoupon?.userCouponId == item.userCouponId;

                  return GestureDetector(
                    onTap: () {
                      // Toggle selection logic
                      if (isSelected) {
                        ref.read(selectedCouponProvider.notifier).select(null);
                      } else {
                        ref.read(selectedCouponProvider.notifier).select(item);
                      }
                      onClose(); // Close sheet after selection
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 12.w),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: context.bgPrimary,
                        borderRadius: BorderRadius.circular(8.w),
                        border: Border.all(
                          color: isSelected ? Colors.pinkAccent : Colors.transparent,
                          width: 1.5.w,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.couponName,
                                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4.w),
                                Text(
                                  'Min. Spend ₱${item.minPurchase}',
                                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '- ₱${item.discountValue}',
                            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.pinkAccent),
                          ),
                          SizedBox(width: 12.w),
                          Icon(
                            isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                            color: isSelected ? Colors.pinkAccent : Colors.grey[300],
                            size: 24.w,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (err, stack) => const Center(child: Text('Error loading vouchers')),
          ),
        ),
        // Option to deselect any coupon
        Button(
          width: double.infinity,
          variant: ButtonVariant.outline,
          onPressed: () {
            ref.read(selectedCouponProvider.notifier).select(null);
            onClose();
          },
          child: const Text('Do not use voucher'),
        ),
        SizedBox(height: 20.h,)
      ],
    );
  }
}