import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/store/hydrated_state_notifier.dart';
import 'package:flutter_app/core/models/index.dart'; // 确保引入 Balance
import '../api/lucky_api.dart';

// 假设 Balance 模型在 models 里
class WalletNotifier extends HydratedStateNotifier<Balance> {
  WalletNotifier() : super(Balance(realBalance: 0, coinBalance: 0));

  @override
  String get storageKey => 'wallet_balance_storage';

  @override
  Balance fromJson(Map<String, dynamic> json) => Balance.fromJson(json);

  @override
  Map<String, dynamic> toJson(Balance state) => state.toJson();

  /// 刷新余额
  Future<void> fetchBalance() async {
    // 假设 Api 类有这个方法，或者你可以复用原有的 walletBalanceProvider 逻辑
    // final data = await ref.read(walletApiProvider).getBalance();
    // 这里为了演示，假设 Api.getWalletBalance() 存在
    final data = await Api.getWalletBalanceApi();
    state = data;
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, Balance>((ref) {
  return WalletNotifier();
});