import 'dart:math' as math;

import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PurchaseState {
  final int entries; // Number of purchase entries
  final int unitAmount; // Price per unit
  final double maxUnitCoins; // Maximum coins per unit
  final double balanceCoins; // User's balance coins
  final double realBalance; // User's balance in real currency
  final double exchangeRate; // Exchange rate
  final int maxPerBuyQuantity; // Maximum units per purchase
  final int minBuyQuantity; // Minimum units per purchase
  final int stockLeft; // Stock left
  final num? coinAmountCap; // Optional cap on coin amount
  final bool isAuthenticated; // User login status

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
  });

  // Maximum entries allowed based on maxPerBuy and stockLeft
  int get _maxEntriesAllowed => math.max(minBuyQuantity, math.min(maxPerBuyQuantity, stockLeft));

  // Minimum entries allowed based on minPerBuy and stockLeft
  int get _minEntriesAllowed => math.min(minBuyQuantity, stockLeft);

  // Whether the current entries exceed the allowed maximum
  int get subtotal => unitAmount * entries;

  // Theoretical maximum coins that can be used
  double get _theoreticalMaxCoins => maxUnitCoins * entries;

  // Actual coins to use based on login status and balance
  double get coinsToUse => isAuthenticated
      ? math.min(_theoreticalMaxCoins.toDouble(), balanceCoins)
      : _theoreticalMaxCoins.toDouble();

  // Coin amount based on exchange rate
  num get coinAmount => exchangeRate > 0 ? (coinsToUse / exchangeRate) : 0;

  // Capped coin amount if a cap is set
  num get coinAmountCapped {
    if (coinAmountCap != null) {
      return math.min(coinAmount, coinAmountCap!);
    }
    return coinAmount;
  }
  PurchaseState copyWith({int? entries}) {
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
    );
  }
}

// Purchase state provider using Riverpod
class PurchaseNotifier extends StateNotifier<PurchaseState> {
  PurchaseNotifier(super.state);

  void resetEntries(int entries) {
    final next = entries.clamp(state._minEntriesAllowed, state._maxEntriesAllowed);
    state = state.copyWith(entries: next);
  }

  // Increment entries
  void inc(Function(int newEntries)? onChanged) {
    final next = (state.entries + 1).clamp(state._minEntriesAllowed, state._maxEntriesAllowed);
    state = state.copyWith(entries: next);
    onChanged?.call(next);
  }

  // Decrement entries
  void dec(Function(int newEntries)? onChanged) {
    final next = (state.entries - 1).clamp(state._minEntriesAllowed, state._maxEntriesAllowed);
     state = state.copyWith(entries: next);
      onChanged?.call(next);
  }


  // Set entries from text input
  void setEntriesFromText(String v) {
    final n = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
    if(n == null) return;
    final next = n.clamp(state._minEntriesAllowed, state._maxEntriesAllowed);
    state = state.copyWith(entries: next);

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
      final detailAsync = ref.watch(productDetailProvider(id));
      final detail = detailAsync.value;
      /*final state = ref.watch(luckyProvider.select((s) => (
          balanceCoins: s.balance.coinBalance,
          realBalance: s.balance.realBalance,
          exChangeRate: s.sysConfig.exChangeRate
      )));*/
      final isAuthenticated = ref.watch(authProvider.select((auth) => auth.isAuthenticated));

      final stockLeft = (detail?.seqShelvesQuantity ?? 0) - (detail?.seqBuyQuantity ?? 0);

      return PurchaseNotifier(
        PurchaseState(
          entries: detail?.minBuyQuantity ?? stockLeft,
          // unitAmount: detail?.unitAmount ?? 0, //todo mock
          unitAmount: detail?.unitAmount ?? 10,
          // maxUnitCoins: detail?.maxUnitCoins ?? 0, //todo mock
          maxUnitCoins: detail?.maxUnitCoins?.toDouble() ?? 0.5,
          // balanceCoins: state.balanceCoins,//todo mock
          balanceCoins: 100000.00,
          // realBalance: state.realBalance, //todo mock
          realBalance: 3000.00,
          // exchangeRate: state.exChangeRate, //todo mock
          exchangeRate: 10.0,
          maxPerBuyQuantity: detail?.maxPerBuyQuantity ?? math.max(1, stockLeft),
          minBuyQuantity: detail?.minBuyQuantity ?? math.min(1, stockLeft),
          stockLeft: stockLeft,
          isAuthenticated: isAuthenticated,
        ),
      );
    });
