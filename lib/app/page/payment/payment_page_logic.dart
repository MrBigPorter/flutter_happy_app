part of 'payment_page.dart';

// =========================================================================
// Main Logic: Data Init and Auto-Matching
// =========================================================================
mixin PaymentPageLogic on ConsumerState<PaymentPage> {
  void initPaymentData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAuthenticated = ref.read(authProvider.select((state) => state.isAuthenticated));
      if (!isAuthenticated) return;

      ref.read(walletProvider.notifier).fetchBalance();

      final treasureId = widget.params.treasureId;
      if (treasureId != null) {
        ref.invalidate(productDetailProvider(treasureId));
        ref.refresh(productRealtimeStatusProvider(treasureId));

        final action = ref.read(purchaseProvider(treasureId).notifier);
        action.setGroupMode(widget.params.isRealGroupBuy);

        if (widget.params.entries != null) {
          final entries = int.tryParse(widget.params.entries!) ?? 1;
          action.resetEntries(entries);
        }

        //  Auto-select the best coupon on page enter
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _autoMatchBestCoupon(treasureId);
        });
      }
    });
  }

  ///  Dynamic Validation: Automatically remove coupon if price falls below threshold
  void listenAndValidateCoupon(String treasureId) {
    ref.listen(purchaseProvider(treasureId).select((s) => s.subtotal), (prev, current) {
      if (prev == current) return;
      final selected = ref.read(selectedCouponProvider);
      if (selected != null) {
        final minSpend = double.tryParse(selected.minPurchase) ?? 0.0;
        if (current < minSpend) {
          // If the new subtotal is lower than the coupon requirement, clear selection
          ref.read(selectedCouponProvider.notifier).select(null);
          // Try to find a new one that fits the lower price
          _autoMatchBestCoupon(treasureId);
        }
      } else if ((prev ?? 0) < current) {
        // If price increased and no coupon was selected, try to auto-match
        _autoMatchBestCoupon(treasureId);
      }
    });
  }

  void _autoMatchBestCoupon(String treasureId) async {
    try {
      final amount = ref.read(purchaseProvider(treasureId)).subtotal;
      if (amount <= 0) return;
      final coupons = await ref.read(availableCouponsForOrderProvider(amount).future);
      if (coupons.isNotEmpty && ref.read(selectedCouponProvider) == null && mounted) {
        // Match the one with the highest discount value
        final best = coupons.reduce((a, b) {
          final valA = double.tryParse(a.discountValue) ?? 0.0;
          final valB = double.tryParse(b.discountValue) ?? 0.0;
          return valA > valB ? a : b;
        });
        ref.read(selectedCouponProvider.notifier).select(best);
      }
    } catch (e) {
      debugPrint('Auto-match failed: $e');
    }
  }
}

// =========================================================================
// Bottom Bar Logic: Anti-Shake (Debounce) and Order Submission
// =========================================================================
mixin BottomNavigationBarLogic on ConsumerState<_BottomNavigationBar> {
  int _lastClickTime = 0; //  Timestamp for debouncing button clicks

  void submitPayment() async {
    //  ANTI-SHAKE: Prevent duplicate orders if user taps rapidly (2s debounce)
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastClickTime < 2000) return;
    _lastClickTime = now;

    final id = widget.params.treasureId ?? '';
    if (id.isEmpty) return;

    final action = ref.read(purchaseProvider(id).notifier);
    final couponId = ref.read(selectedCouponProvider)?.userCouponId;

    final result = await action.submitOrder(
      groupId: widget.params.groupId,
      couponId: couponId,
    );

    if (!mounted) return;
    if (!result.ok) {
      _handlePaymentError(result.error);
      return;
    }

    if (widget.isGroupBuy) {
      final groupId = result.data?.groupId ?? widget.params.groupId;
      if (groupId != null) {
        appRouter.pushReplacement('/group-room?groupId=$groupId');
        return;
      }
    }

    RadixSheet.show(
      builder: (context, close) => PaymentSuccessSheet(
        title: widget.title,
        purchaseResponse: result.data!,
        onClose: () {
          close();
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
    );
  }

  void _handlePaymentError(PurchaseSubmitError? error) {
    switch (error) {
      case PurchaseSubmitError.needLogin:
        appRouter.pushNamed('login');
        break;
      case PurchaseSubmitError.needKyc:
        KycGuard.ensure(context: context, ref: ref, onApproved: () {});
        break;
      case PurchaseSubmitError.noAddress:
        RadixToast.error('please.add.delivery.address'.tr());
        break;
      case PurchaseSubmitError.insufficientBalance:
        RadixSheet.show(
          config: const ModalSheetConfig(enableHeader: false),
          builder: (context, close) => InsufficientBalanceSheet(close: close),
        );
        break;
      default:
        RadixToast.error('Payment Failed');
        break;
    }
  }
}