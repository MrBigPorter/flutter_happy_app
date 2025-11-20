import 'dart:math' as math;

import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/core/providers/wallet_provider.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../store/lucky_store.dart';

class PurchaseState {
  final int entries; // Number of purchase entries
  final double unitAmount; // Price per unit
  final double maxUnitCoins; // Maximum coins per unit
  final double balanceCoins; // User's balance coins
  final double realBalance; // User's balance in real currency
  final double exchangeRate; // Exchange rate
  final int maxPerBuyQuantity; // Maximum units per purchase
  final int minBuyQuantity; // Minimum units per purchase
  final int stockLeft; // Stock left
  final num? coinAmountCap; // Optional cap on coin amount
  final bool isAuthenticated; // User login status
  final bool useDiscountCoins; // Whether to use discount coins

  final bool isSubmitting; // Submission status

  PurchaseState({
    required this.entries,
    required this.unitAmount,
    required this.maxUnitCoins,
    required this.balanceCoins,
    required this.realBalance,
    required this.exchangeRate,
    required this.maxPerBuyQuantity,
    required this.minBuyQuantity,
    required this.stockLeft,
    this.coinAmountCap,
    required this.isAuthenticated,
    required this.useDiscountCoins,

    required this.isSubmitting,
  });

  // Maximum entries allowed based on maxPerBuy and stockLeft
  int get _maxEntriesAllowed =>
      math.max(minBuyQuantity, math.min(maxPerBuyQuantity, stockLeft));

  // Minimum entries allowed based on minPerBuy and stockLeft
  int get _minEntriesAllowed => math.min(minBuyQuantity, stockLeft);

  // Whether the current entries exceed the allowed maximum
  double get subtotal => unitAmount * entries;

  double? get payableAmount =>
      useDiscountCoins ? (subtotal - coinAmount) : subtotal;

  // Theoretical maximum coins that can be used
  double get _theoreticalMaxCoins => maxUnitCoins * entries;

  // Actual coins to use based on login status and balance
  double get coinsToUse => isAuthenticated
      ? math.min(_theoreticalMaxCoins.toDouble(), balanceCoins)
      : _theoreticalMaxCoins.toDouble();

  // Coin amount based on exchange rate
  double get coinAmount => exchangeRate > 0 ? (coinsToUse / exchangeRate) : 0;

  // Capped coin amount if a cap is set
  num get coinAmountCapped {
    if (coinAmountCap != null) {
      return math.min(coinAmount, coinAmountCap!);
    }
    return coinAmount;
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
      balanceCoins: balanceCoins,
      exchangeRate: exchangeRate,
      maxPerBuyQuantity: maxPerBuyQuantity,
      minBuyQuantity: minBuyQuantity,
      stockLeft: stockLeft,
      coinAmountCap: coinAmountCap,
      isAuthenticated: isAuthenticated,
      realBalance: realBalance,
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

  // Private constructor， only accessible through factory methods
  const PurchaseSubmitResult._(this.ok, this.error, this.message);

  // Factory method for successful submission
  factory PurchaseSubmitResult.ok() =>
      PurchaseSubmitResult._(true, PurchaseSubmitError.none, null);

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

  Future<PurchaseSubmitResult> submitOrder({String? groupId}) async {
    // need login
    if (!state.isAuthenticated) {
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
    final pay = state.payableAmount ?? state.subtotal;
    if (state.realBalance < pay) {
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
      state = state.copyWith(isSubmitting: true);
      /*final walletDebit = ref.read(walletDebitProvider.future);
      await repo.submitOrder(
        treasureId: treasureId,
        quantity: state.entries,
        useCoins: state.useDiscountCoins,
        groupId: groupId,
      );*/
      //refresh balance
      await ref.read(luckyProvider.notifier).updateWalletBalance();
      return PurchaseSubmitResult.ok();
    } catch (e) {
      return PurchaseSubmitResult.error(
        PurchaseSubmitError.unknown,
        message: e.toString(),
      );
    } finally {
      state = state.copyWith(isSubmitting: false);
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

final purchaseProvider = StateNotifierProvider.autoDispose
    .family<PurchaseNotifier, PurchaseState, String>((ref, id) {
      final isAuthenticated = ref.watch(
        authProvider.select((auth) => auth.isAuthenticated),
      );
      final detailAsync = ref.watch(productDetailProvider(id));
      final detail = detailAsync.value;


      final state = ref.watch(
        luckyProvider.select(
          (s) => (
            balanceCoins: s.balance.coinBalance,
            realBalance: s.balance.realBalance,
            exChangeRate: s.sysConfig.exChangeRate,
          ),
        ),
      );

      final stockLeft =
          (detail?.seqShelvesQuantity ?? 0) - (detail?.seqBuyQuantity ?? 0);

      final initialState = PurchaseState(
        entries: detail?.minBuyQuantity ?? stockLeft,
        unitAmount: detail?.unitAmount ?? 0.0,
        maxUnitCoins: detail?.maxUnitCoins ?? 0,
        balanceCoins: state.balanceCoins,
        realBalance: state.realBalance,
        // exchangeRate: state.exChangeRate, //todo mock
        exchangeRate: 10.0,
        maxPerBuyQuantity: detail?.maxPerBuyQuantity ?? math.max(1, stockLeft),
        minBuyQuantity: detail?.minBuyQuantity ?? math.min(1, stockLeft),
        stockLeft: stockLeft,
        isAuthenticated: isAuthenticated,
        useDiscountCoins: false,
        isSubmitting: false,
      );
      return PurchaseNotifier(ref: ref, treasureId: id, state: initialState);
    });
