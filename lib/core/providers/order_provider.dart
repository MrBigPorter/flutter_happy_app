import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Order checkout provider, OrdersCheckoutParams as input, returns OrderCheckoutResponse
/// family: first parameter is OrderCheckoutResponse, second is OrdersCheckoutParams
final orderCheckoutProvider = FutureProvider.family<OrderCheckoutResponse,OrdersCheckoutParams> ((ref, params) async{
  return await Api.ordersCheckOutApi(params);
});