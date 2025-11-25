import 'dart:math' as math;

import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/core/providers/order_provider.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../store/lucky_store.dart';

class PurchaseState {
  final int entries; // Number of purchase entries
  final double unitAmount; // Price per unit (PHP)
  final double maxUnitCoins; // Maximum coins per unit (coins)
  final int maxPerBuyQuantity; // Maximum units per purchase
  final int minBuyQuantity; // Minimum units per purchase
  final int stockLeft; // Stock left
  final num? coinAmountCap; // Optional cap on coin amount (PHP)
  final bool useDiscountCoins; // Whether to use discount coins

  final bool isSubmitting; // Submission status

  PurchaseState({
    required this.entries,
    required this.unitAmount,
    required this.maxUnitCoins,
    required this.maxPerBuyQuantity,
    required this.minBuyQuantity,
    required this.stockLeft,
    this.coinAmountCap,
    required this.useDiscountCoins,
    required this.isSubmitting,
  });

  /// 最大可买份数：
  /// - 不能超过库存
  /// - 不能超过限购（<=0 时视为不限购）
  /// - 库存<=0 时直接 0
  int get _maxEntriesAllowed {
    if (stockLeft <= 0) return 0;

    final maxByStock = stockLeft; // 至多买到库存为止
    final maxByLimit = maxPerBuyQuantity <= 0 ? maxByStock : maxPerBuyQuantity;

    return math.max(1, math.min(maxByStock, maxByLimit));
  }

  /// 最小可买份数：
  /// - minBuyQuantity <=0 时按 1
  /// - 再和库存取 min
  /// - 库存<=0 时为 0
  int get _minEntriesAllowed {
    if (stockLeft <= 0) return 0;
    final minByConfig = minBuyQuantity <= 0 ? 1 : minBuyQuantity;
    return math.min(minByConfig, stockLeft);
  }

  /// 小计金额（PHP）
  double get subtotal => unitAmount * entries;

  /// 理论最大可用金币（coins）
  /// 后端：maxUnitCoins 是 “单份最大使用金币数（coins）”
  /// 后端计算：
  ///   maxCoinUsable = maxUnitCoins * entries
  double get theoreticalMaxCoins {
    if (!useDiscountCoins) return 0;
    return maxUnitCoins * entries;
  }

  PurchaseState copyWith({
    int? entries,
    bool? useDiscountCoins,
    bool? isSubmitting,
  }) {
    return PurchaseState(
      entries: entries ?? this.entries,
      unitAmount: unitAmount,
      maxUnitCoins: maxUnitCoins,
      maxPerBuyQuantity: maxPerBuyQuantity,
      minBuyQuantity: minBuyQuantity,
      stockLeft: stockLeft,
      coinAmountCap: coinAmountCap,
      useDiscountCoins: useDiscountCoins ?? this.useDiscountCoins,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

enum PurchaseSubmitError {
  none,
  needLogin,
  insufficientBalance,
  insufficientStock,
  needKyc,
  noAddress,
  purchaseLimitExceeded,
  soldOut,
  unknown,
}

/// Result of a purchase submission
/// provides factory methods for success and error cases
class PurchaseSubmitResult {
  final bool ok;
  final PurchaseSubmitError error;
  final String? message;
  final OrderCheckoutResponse? data;

  // Private constructor， only accessible through factory methods
  const PurchaseSubmitResult._(this.ok, this.error, this.message, [this.data]);

  // Factory method for successful submission
  factory PurchaseSubmitResult.ok(data) =>
      PurchaseSubmitResult._(true, PurchaseSubmitError.none, null, data);

  // Factory method for error submission
  factory PurchaseSubmitResult.error(
    PurchaseSubmitError error, {
    String? message,
  }) => PurchaseSubmitResult._(false, error, message);
}

// Purchase state provider using Riverpod
class PurchaseNotifier extends StateNotifier<PurchaseState> {
  PurchaseNotifier({
    required this.ref,
    required this.treasureId,
    required PurchaseState state,
  }) : super(state);

  final Ref ref;
  final String treasureId;

  double get _balanceCoins => ref.read(luckyProvider).balance.coinBalance;

  double get _realBalance => ref.read(luckyProvider).balance.realBalance;

  double get _exchangeRate => ref.read(luckyProvider).sysConfig.exChangeRate;

  bool get _isAuthenticated => ref.read(authProvider).isAuthenticated;

  /// 计算实际可用的金币数量
  double get coinsCanUse {
    if (!state.useDiscountCoins) return 0.0;
    final maxByRule = state.theoreticalMaxCoins;
    if (!_isAuthenticated) {
      return maxByRule;
    }
    final maxByBalance = _balanceCoins;
    return math.max(0.0, math.min(maxByRule, maxByBalance));
  }

  /// coins to PHP
  double get coinAmount {
    final rate = _exchangeRate;
    if (!state.useDiscountCoins || rate <= 0) return 0.0;
    return coinsCanUse / rate;
  }

  double get payableAmount {
    if (!state.useDiscountCoins) return state.subtotal;
    final raw = state.subtotal - coinAmount;
    return raw <= 0 ? 0.0 : raw;
  }

  Future<PurchaseSubmitResult> submitOrder({String? groupId}) async {
    if (!mounted) {
      return PurchaseSubmitResult.error(
        PurchaseSubmitError.unknown,
        message: 'Notifier is unmounted',
      );
    }
    // need login
    if (!_isAuthenticated) {
      return PurchaseSubmitResult.error(PurchaseSubmitError.needLogin);
    }

    // kyc check
    final sysConfig = ref.read(luckyProvider).sysConfig;
    final needKyc = sysConfig.kycAndPhoneVerification == '1';

    /*if(needKyc){
      final user = ref.read(luckyProvider).userInfo;
      // if(user?.kycStatus != KycStatus.passed){
      if(user?.kycStatus != 2){
        return PurchaseSubmitResult.error(PurchaseSubmitError.needKyc);
      }
    }*/

    // balance check
    final pay = payableAmount;
    final realBalance = _realBalance;
    if (realBalance < pay) {
      return PurchaseSubmitResult.error(
        PurchaseSubmitError.insufficientBalance,
      );
    }

    // address check
    /*if(needKyc){
      final addresses = await ref.read(addressListProvider.future);
      if(addresses.isEmpty){
        return PurchaseSubmitResult.error(PurchaseSubmitError.noAddress);
      }
    }*/

    // stock check,limit check
    if (state.stockLeft <= 0) {
      return PurchaseSubmitResult.error(PurchaseSubmitError.soldOut);
    }

    if (state.entries > state.maxPerBuyQuantity ||
        state.entries > state.stockLeft) {
      return PurchaseSubmitResult.error(
        PurchaseSubmitError.purchaseLimitExceeded,
      );
    }
    try {
      if (!mounted) {
        return PurchaseSubmitResult.error(
          PurchaseSubmitError.unknown,
          message: 'Notifier is unmounted',
        );
      }
      state = state.copyWith(isSubmitting: true);
      final orderCheckoutResult = await ref.read(
        orderCheckoutProvider(
          OrdersCheckoutParams(
            treasureId: treasureId,
            entries: state.entries,
            paymentMethod: state.useDiscountCoins ? 2 : 1,
            groupId: groupId,
            addressId: null,
            couponId: null,
          ),
        ).future,
      );

      if (!mounted) {
        return PurchaseSubmitResult.error(
          PurchaseSubmitError.unknown,
          message: 'Notifier is unmounted',
        );
      }

      //refresh balance
      await ref.read(luckyProvider.notifier).updateWalletBalance();
      return PurchaseSubmitResult.ok(orderCheckoutResult);
    } catch (e) {
      return PurchaseSubmitResult.error(
        PurchaseSubmitError.unknown,
        message: e.toString(),
      );
    } finally {
      if (mounted) {
        state = state.copyWith(isSubmitting: false);
      }
    }
  }

  void resetEntries(int entries) {
    final next = entries.clamp(
      state._minEntriesAllowed,
      state._maxEntriesAllowed,
    );
    state = state.copyWith(entries: next);
  }

  // Increment entries
  void inc(Function(int newEntries)? onChanged) {
    final next = (state.entries + 1).clamp(
      state._minEntriesAllowed,
      state._maxEntriesAllowed,
    );
    state = state.copyWith(entries: next);
    onChanged?.call(next);
  }

  // Decrement entries
  void dec(Function(int newEntries)? onChanged) {
    final next = (state.entries - 1).clamp(
      state._minEntriesAllowed,
      state._maxEntriesAllowed,
    );
    state = state.copyWith(entries: next);
    onChanged?.call(next);
  }

  // Set entries from text input
  void setEntriesFromText(String v) {
    final n = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
    if (n == null) return;
    final next = n.clamp(state._minEntriesAllowed, state._maxEntriesAllowed);
    state = state.copyWith(entries: next);
  }

  void toggleUseDiscountCoins(bool use) {
    state = state.copyWith(useDiscountCoins: use);
  }
}

typedef PurchaseArgs = ({
  int unitPrice,
  int maxUnitCoins,
  double exchangeRate,
  int maxPerBuy,
  int minPerBuy,
  int stockLeft,
  bool isLoggedIn,
  double balanceCoins,
  num? coinAmountCap,
});

final purchaseProvider =
    StateNotifierProvider.family<PurchaseNotifier, PurchaseState, String>((
      ref,
      id,
    ) {

      final detailAsync = ref.read(productDetailProvider(id));
      final detail = detailAsync.value;

      final stockLeft =
          (detail?.seqShelvesQuantity ?? 0) - (detail?.seqBuyQuantity ?? 0);

      final initialState = PurchaseState(
        entries: stockLeft > 0 ? detail?.minBuyQuantity ?? 1 : 0,
        unitAmount: detail?.unitAmount ?? 0.0,
        maxUnitCoins: JsonNumConverter.toDouble(detail?.maxUnitCoins),
        maxPerBuyQuantity: JsonNumConverter.toInt(detail?.maxPerBuyQuantity ?? math.max(1, stockLeft)),
        minBuyQuantity: detail?.minBuyQuantity ?? math.min(1, stockLeft),
        stockLeft: stockLeft,
        useDiscountCoins: false,
        isSubmitting: false,
      );
      return PurchaseNotifier(ref: ref, treasureId: id, state: initialState);
    });
