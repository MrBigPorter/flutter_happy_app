import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/lucky_api.dart';
import '../models/balance.dart';

part 'wallet_provider.g.dart';



@riverpod
Future<Balance> walletBalance(WalletBalanceRef ref) async {
  return await Api.getWalletBalanceApi();
}

@riverpod
class CreateRecharge extends _$CreateRecharge {
  @override
  // 2. 修改这里：把 <void> 改成 <RechargeResponse?>
  // 初始状态是 null (没有订单)
  AsyncValue<RechargeResponse?> build() => const AsyncValue.data(null);
  
  // 创建充值订单
  Future<RechargeResponse?> create(CreateRechargeDto dto) async {
    state = const AsyncValue.loading();
    //guard 自动处理异常
    state = await AsyncValue.guard(() async {
      return await Api.walletRechargeCreateApi(dto);
    });

    // 创建失败，返回 null
    if(state.hasError){
      // 或者直接返回 null，UI 层通过监听 state 变红来处理
      return null;
    }

    //  此时 state.value 就是 RechargeResponse 了
    return state.value;
  }
}

