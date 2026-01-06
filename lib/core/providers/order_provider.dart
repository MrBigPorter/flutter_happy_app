import 'dart:async';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_app/utils/cache/cache_for_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'order_provider.g.dart';


/// Order checkout provider, OrdersCheckoutParams as input, returns OrderCheckoutResponse
/// family: first parameter is OrderCheckoutResponse, second is OrdersCheckoutParams
final orderCheckoutProvider = FutureProvider.family<OrderCheckoutResponse,OrdersCheckoutParams> ((ref, params) async{
  return await Api.ordersCheckOutApi(params);
});

/// Order detail provider, takes orderId as input, returns OrderDetail
final orderDetailProvider = FutureProvider.family<OrderDetailItem,String>((ref,orderId) async{

  ref.cacheFor(Duration(seconds: 60)); // 缓存 60s


  return await Api.orderDetailApi(orderId);
});

@riverpod
class OrderRefundApply extends _$OrderRefundApply{
  @override
  // 初始状态是 null (没有订单)
  AsyncValue<RefundOrderResp?> build() => const AsyncValue.data(null);

  // 创建退款申请
  Future<RefundOrderResp?> create(RefundApplyReq dto) async {
    state = const AsyncValue.loading();
    //guard 自动处理异常
    state = await AsyncValue.guard(() async {
      return await Api.orderRefundApply(dto);
    });

    // 创建失败，返回 null
    if(state.hasError){
      // 或者直接返回 null，UI 层通过监听 state 变红来处理
      return null;
    }

    //  此时 state.value 就是 OrderRefundResponse 了
    return state.value;
  }
}