import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

class PurchaseState {
  final int entries; // Number of purchase entries
  final int unitPrice; // Price per unit
  final int maxUnitCoins; // Maximum coins per unit
  final double balanceCoins; // User's balance coins
  final double exchangeRate; // Exchange rate
  final int maxPerBuy; // Maximum units per purchase
  final int stockLeft; // Stock left
  final num? coinAmountCap; // Optional cap on coin amount
  final bool isLoginIn; // User login status

  PurchaseState({
    required this.entries,
    required this.unitPrice,
    required this.maxUnitCoins,
    required this.balanceCoins,
    required this.exchangeRate,
    required this.maxPerBuy,
    required this.stockLeft,
    this.coinAmountCap,
    required this.isLoginIn,
  });

  // Maximum entries allowed based on maxPerBuy and stockLeft
  int get _maxEntriesAllowed => math.max(0, math.min(maxPerBuy, stockLeft));

  // Whether the current entries exceed the allowed maximum
  int get subtotal => unitPrice * entries;

  // Theoretical maximum coins that can be used
  int get _theoreticalMaxCoins => maxUnitCoins * entries;

  // Actual coins to use based on login status and balance
  double get coinsToUse => isLoginIn
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
    final e = (entries ?? this.entries).clamp(0, _maxEntriesAllowed);
    return PurchaseState(
      entries: e,
      unitPrice: unitPrice,
      maxUnitCoins: maxUnitCoins,
      balanceCoins: balanceCoins,
      exchangeRate: exchangeRate,
      maxPerBuy: maxPerBuy,
      stockLeft: stockLeft,
      coinAmountCap: coinAmountCap,
      isLoginIn: isLoginIn,
    );
  }
}

// Purchase state provider using Riverpod
class PurchaseNotifier extends StateNotifier<PurchaseState> {
  PurchaseNotifier(super.s);

  // Increment entries
  void inc() => state = state.copyWith(entries: state.entries + 1);

  // Decrement entries
  void dec() => state = state.copyWith(entries: state.entries - 1);


  // Set entries from text input
  void setEntriesFromText(String v) {
    final n = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    state = state.copyWith(entries: n);
  }
}

typedef PurchaseArgs = ({
  int unitPrice,
  int maxUnitCoins,
  double exchangeRate,
  int maxPerBuy,
  int stockLeft,
  bool isLoggedIn,
  double balanceCoins,
  num? coinAmountCap,
});

final purchaseProvider = StateNotifierProvider.autoDispose
    .family<PurchaseNotifier, PurchaseState, PurchaseArgs>((ref, args) {
      return PurchaseNotifier(
        PurchaseState(
          entries: 1,
          unitPrice: args.unitPrice,
          maxUnitCoins: args.maxUnitCoins,
          balanceCoins: args.balanceCoins,
          exchangeRate: args.exchangeRate,
          maxPerBuy: args.maxPerBuy,
          stockLeft: args.stockLeft,
          coinAmountCap: args.coinAmountCap,
          isLoginIn: args.isLoggedIn,
        ),
      );
    });
