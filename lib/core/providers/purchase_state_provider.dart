import 'dart:math' as math;
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_app/core/providers/address_provider.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/core/providers/order_provider.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/core/store/config_store.dart';
import 'package:flutter_app/core/store/user_store.dart';
import 'package:flutter_app/core/store/wallet_store.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/time/server_time_helper.dart';

import 'package:flutter_app/core/providers/coupon_provider.dart';

// ==========================================
// 1. State 改造：使用 Getter 派生价格，杜绝数据不同步
// ==========================================
class PurchaseState {
  final int entries;

  // 分别缓存两种价格，作为底层数据源
  final double baseGroupPrice;
  final double baseSoloPrice;

  final bool isGroupBuy; // 当前模式：拼团 (true) / 单买 (false)

  final double maxUnitCoins;
  final int maxPerBuyQuantity;
  final int minBuyQuantity;
  final int stockLeft;
  final bool useDiscountCoins;
  final bool isSubmitting;

  final int? salesStartAt;
  final int? salesEndAt;
  final int productState;

  PurchaseState({
    required this.entries,
    required this.baseGroupPrice,
    required this.baseSoloPrice,
    required this.isGroupBuy,
    required this.maxUnitCoins,
    required this.maxPerBuyQuantity,
    required this.minBuyQuantity,
    required this.stockLeft,
    required this.useDiscountCoins,
    required this.isSubmitting,
    this.salesStartAt,
    this.salesEndAt,
    this.productState = 1,
  });

  //  核心修复 1：将 unitAmount 变成动态计算的 Getter
  // 无论后台接口什么时候回来，或者怎么切模式，当前单价永远正确！
  double get unitAmount {
    if (isGroupBuy) return baseGroupPrice;

    // 如果是单买：优先用后端的单买价，如果没有，强制兜底为拼团价的 1.5 倍
    if (baseSoloPrice > 0) return baseSoloPrice;
    return baseGroupPrice * 1.5;
  }

  //  核心修复 2：小计自动使用上面算出的绝对正确单价
  double get subtotal => unitAmount * entries;

  int get _maxEntriesAllowed {
    if (stockLeft <= 0) return 0;
    final maxByLimit = maxPerBuyQuantity <= 0 ? stockLeft : maxPerBuyQuantity;
    return math.max(1, math.min(stockLeft, maxByLimit));
  }

  int get _minEntriesAllowed {
    if (stockLeft <= 0) return 0;
    final minByConfig = minBuyQuantity <= 0 ? 1 : minBuyQuantity;
    return math.min(minByConfig, stockLeft);
  }

  double get theoreticalMaxCoins {
    if (!useDiscountCoins) return 0;
    return maxUnitCoins * entries;
  }

  PurchaseState copyWith({
    int? entries,
    int? stockLeft,
    double? baseGroupPrice,
    double? baseSoloPrice,
    bool? isGroupBuy,
    bool? useDiscountCoins,
    bool? isSubmitting,
    int? maxPerBuyQuantity,
    int? minBuyQuantity,
    int? productState,
  }) {
    return PurchaseState(
      entries: entries ?? this.entries,
      baseGroupPrice: baseGroupPrice ?? this.baseGroupPrice,
      baseSoloPrice: baseSoloPrice ?? this.baseSoloPrice,
      isGroupBuy: isGroupBuy ?? this.isGroupBuy,
      maxUnitCoins: maxUnitCoins,
      maxPerBuyQuantity: maxPerBuyQuantity ?? this.maxPerBuyQuantity,
      minBuyQuantity: minBuyQuantity ?? this.minBuyQuantity,
      stockLeft: stockLeft ?? this.stockLeft,
      useDiscountCoins: useDiscountCoins ?? this.useDiscountCoins,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      salesStartAt: salesStartAt,
      salesEndAt: salesEndAt,
      productState: productState ?? this.productState,
    );
  }
}

enum PurchaseSubmitError {
  none, needLogin, insufficientBalance, insufficientStock,
  purchaseLimitExceeded, soldOut, unknown, preSaleNotStarted,
  salesEnded, productOffline, needKyc, noAddress,
}

class PurchaseSubmitResult {
  final bool ok;
  final PurchaseSubmitError error;
  final String? message;
  final OrderCheckoutResponse? data;

  const PurchaseSubmitResult._(this.ok, this.error, this.message, [this.data]);

  factory PurchaseSubmitResult.ok(data) => PurchaseSubmitResult._(true, PurchaseSubmitError.none, null, data);
  factory PurchaseSubmitResult.error(PurchaseSubmitError error, {String? message}) => PurchaseSubmitResult._(false, error, message);
}

// ==========================================
// 2. Notifier：彻底清爽，只管改模式和存数据
// ==========================================
class PurchaseNotifier extends StateNotifier<PurchaseState> {
  final Ref ref;
  final String treasureId;

  PurchaseNotifier({
    required this.ref,
    required this.treasureId,
    required PurchaseState state,
  }) : super(state) {
    _listenToProductUpdates();
  }

  //  核心修复 3：切模式时，只需要改 isGroupBuy 标识，不用再手动算价了！
  void setGroupMode(bool isGroup) {
    state = state.copyWith(isGroupBuy: isGroup);
    _clampEntries(); // 切模式后检查数量是否合法
  }

  void _listenToProductUpdates() {
    // 监听实时状态
    ref.listen(productRealtimeStatusProvider(treasureId), (prev, next) {
      next.whenData((status) {
        final newStock = status.stock;
        final newState = status.state;
        final newGroupPrice = status.price;

        //  加上 1.5 倍兜底
        final newSoloPrice = status.soloPrice ?? (newGroupPrice * 1.5);

        state = state.copyWith(
          stockLeft: newStock,
          baseGroupPrice: newGroupPrice,
          baseSoloPrice: newSoloPrice,
          productState: newState,
        );
        _clampEntries();
      });
    });

    // 监听商品详情
    ref.listen(productDetailProvider(treasureId), (prev, next) {
      next.whenData((detail) {
        final newGroupPrice = detail.unitAmount ?? 0.0;
        final newSoloPrice = detail.soloAmount ?? (newGroupPrice * 1.5);

        state = state.copyWith(
          baseGroupPrice: state.baseGroupPrice > 0 ? state.baseGroupPrice : newGroupPrice,
          baseSoloPrice: state.baseSoloPrice > 0 ? state.baseSoloPrice : newSoloPrice,
          maxPerBuyQuantity: JsonNumConverter.toInt(detail.maxPerBuyQuantity ?? 0),
          minBuyQuantity: detail.minBuyQuantity ?? 1,
        );
        _clampEntries();
      });
    });
  }

  void _clampEntries() {
    final min = state._minEntriesAllowed;
    final max = state._maxEntriesAllowed;
    final safeEntries = state.entries.clamp(min, max);
    if (safeEntries != state.entries) {
      state = state.copyWith(entries: safeEntries);
    }
  }

  void resetEntries(int targetEntries) {
    state = state.copyWith(entries: targetEntries);
    _clampEntries();
  }

  // Getters
  double get _balanceCoins => ref.read(walletProvider).coinBalance;
  double get _realBalance => ref.read(walletProvider).realBalance;
  double get _exchangeRate => ref.read(configProvider).exChangeRate;
  bool get _isAuthenticated => ref.read(authProvider).isAuthenticated;

  double get coinsCanUse {
    if (!state.useDiscountCoins) return 0.0;
    final maxByRule = state.theoreticalMaxCoins;
    if (!_isAuthenticated) return maxByRule;
    return math.max(0.0, math.min(maxByRule, _balanceCoins));
  }

  double get coinAmount {
    final rate = _exchangeRate;
    if (!state.useDiscountCoins || rate <= 0) return 0.0;
    return coinsCanUse / rate;
  }

  double get payableAmount {
    double currentSubtotal = state.subtotal;

    final selectedCoupon = ref.read(selectedCouponProvider);
    if (selectedCoupon != null) {
      final discount = double.tryParse(selectedCoupon.discountValue) ?? 0.0;
      currentSubtotal = (currentSubtotal - discount).clamp(0.0, double.infinity);
    }

    if (!state.useDiscountCoins) return currentSubtotal;
    final raw = currentSubtotal - coinAmount;
    return raw <= 0 ? 0.0 : raw;
  }

  Future<PurchaseSubmitResult> submitOrder({String? groupId, String? couponId}) async {
    if (!mounted) return PurchaseSubmitResult.error(PurchaseSubmitError.unknown);
    if (state.isSubmitting) return PurchaseSubmitResult.error(PurchaseSubmitError.unknown);

    if (!_isAuthenticated) return PurchaseSubmitResult.error(PurchaseSubmitError.needLogin);
    if (state.stockLeft <= 0) return PurchaseSubmitResult.error(PurchaseSubmitError.soldOut);
    if (state.productState != 1) return PurchaseSubmitResult.error(PurchaseSubmitError.productOffline);

    final now = ServerTimeHelper.nowMilliseconds;
    if (state.salesStartAt != null && state.salesStartAt! > now) {
      return PurchaseSubmitResult.error(PurchaseSubmitError.preSaleNotStarted, message: 'Pre-sale has not started yet.');
    }
    if (state.salesEndAt != null && state.salesEndAt! < now) {
      return PurchaseSubmitResult.error(PurchaseSubmitError.salesEnded, message: 'Sales have ended.');
    }

    final kycStatus = ref.read(userProvider.select((s) => s?.kycStatus));
    if (KycStatusEnum.fromStatus(kycStatus ?? 0) != KycStatusEnum.approved) {
      return PurchaseSubmitResult.error(PurchaseSubmitError.needKyc);
    }
    final address = await ref.read(selectedAddressProvider);
    if (address == null) return PurchaseSubmitResult.error(PurchaseSubmitError.noAddress);

    if (state.entries > state._maxEntriesAllowed) {
      return PurchaseSubmitResult.error(PurchaseSubmitError.purchaseLimitExceeded);
    }

    if (_realBalance < payableAmount) {
      return PurchaseSubmitResult.error(PurchaseSubmitError.insufficientBalance);
    }

    try {
      state = state.copyWith(isSubmitting: true);

      final orderCheckoutResult = await ref.read(
        orderCheckoutProvider(
          OrdersCheckoutParams(
            treasureId: treasureId,
            entries: state.entries,
            paymentMethod: state.useDiscountCoins ? 2 : 1,
            groupId: groupId,
            isGroup: state.isGroupBuy, // 这里取的值现在永远是对的！
            couponId: couponId,
          ),
        ).future,
      );

      if (!mounted) return PurchaseSubmitResult.error(PurchaseSubmitError.unknown);

      ref.read(selectedCouponProvider.notifier).select(null);
      ref.read(walletProvider.notifier).fetchBalance();
      ref.invalidate(productRealtimeStatusProvider(treasureId));

      return PurchaseSubmitResult.ok(orderCheckoutResult);
    } catch (e) {
      return PurchaseSubmitResult.error(PurchaseSubmitError.unknown, message: e.toString());
    } finally {
      if (mounted) state = state.copyWith(isSubmitting: false);
    }
  }

  void inc(Function(int)? onChanged) {
    final max = state._maxEntriesAllowed;
    if (state.entries >= max) return;
    state = state.copyWith(entries: state.entries + 1);
    onChanged?.call(state.entries);
  }

  void dec(Function(int)? onChanged) {
    final min = state._minEntriesAllowed;
    if (state.entries <= min) return;
    state = state.copyWith(entries: state.entries - 1);
    onChanged?.call(state.entries);
  }

  void setEntriesFromText(String v) {
    final clean = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return;
    int n = int.tryParse(clean) ?? state.minBuyQuantity;
    n = n.clamp(state._minEntriesAllowed, state._maxEntriesAllowed);
    state = state.copyWith(entries: n);
  }

  void toggleUseDiscountCoins(bool use) {
    state = state.copyWith(useDiscountCoins: use);
  }
}

// ==========================================
// 4. Provider 初始化改造
// ==========================================
final purchaseProvider = StateNotifierProvider.family
    .autoDispose<PurchaseNotifier, PurchaseState, String>((ref, id) {

  final detail = ref.read(productDetailProvider(id)).valueOrNull;
  final status = ref.read(productRealtimeStatusProvider(id)).valueOrNull;

  final stockLeft = status?.stock ?? ((detail?.seqShelvesQuantity ?? 0) - (detail?.seqBuyQuantity ?? 0));
  final productState = status?.state ?? (detail?.state ?? 1);
  final minBuy = detail?.minBuyQuantity ?? 1;

  final groupPrice = status?.price ?? (detail?.unitAmount ?? 0.0);

  //  核心修复 4：初始化时也必须带上 1.5 倍兜底！
  final soloPrice = status?.soloPrice ?? (detail?.soloAmount ?? (groupPrice * 1.5));

  final initialState = PurchaseState(
    entries: stockLeft > 0 ? minBuy : 0,

    baseGroupPrice: groupPrice,
    baseSoloPrice: soloPrice,
    isGroupBuy: true, // 初始先设为默认，反正会被逻辑层立即 setGroupMode 改掉

    maxUnitCoins: JsonNumConverter.toDouble(detail?.maxUnitCoins),
    maxPerBuyQuantity: JsonNumConverter.toInt(detail?.maxPerBuyQuantity ?? 0),
    minBuyQuantity: minBuy,
    stockLeft: stockLeft,
    useDiscountCoins: true,
    isSubmitting: false,
    salesStartAt: detail?.salesStartAt,
    salesEndAt: detail?.salesEndAt,
    productState: productState,
  );

  return PurchaseNotifier(ref: ref, treasureId: id, state: initialState);
});