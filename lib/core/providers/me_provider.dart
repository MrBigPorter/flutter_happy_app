import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_item.dart';

/// Coupon threshold list provider
final thresholdListProvider = FutureProvider((ref) async {
  return Api.thresholdListApi();
});

/// Order list request provider with pagination and status filter
final orderListProvider = Provider.family((ref, String status){
  return ({required int pageSize, required int current}) {
    return Api.orderListApi(
      OrderListParams(
        orderState: status,
        current: current,
        size: pageSize,
      ),
    );
  };
});

/// Order count by status provider
final orderCountProvider = FutureProvider((ref) async {
  return Api.orderCountApi();
});

final activeOrderTabProvider = StateProvider<TabItem>((ref) {
  return TabItem(
    name: 'common.active',
    value: 1,
    total: 0
  );
});