import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_item.dart';

/// Coupon threshold list provider
final thresholdListProvider = FutureProvider((ref) async {
  return Api.thresholdListApi();
});

/// Order list request provider with pagination and status filter
final orderListProvider = Provider.family((ref, int status){
  return ({required int pageSize, required int page}) {
    return Api.orderListApi(
      OrderListParams(
        orderState: status,
        page: page,
        size: pageSize,
      ),
    );
  };
});



/// Order count by status provider
final orderCountProvider = FutureProvider((ref) async {
  final orderCount = await Api.orderCountApi();
  ref.read(tabOrderStateProvider.notifier).updateTabOrderTotal(orderCount);
  return orderCount;
});

final activeOrderTabProvider = StateProvider<TabItem>((ref) {
  return TabItem(
    name: 'common.active',
    value: 1,
    total: 0,
    key: 'active_count',
  );
});

/// Tab order
/// Contains list of TabItem with their totals
/// Used to display order tabs with counts
class TabOrderStateNotifier extends StateNotifier<List<TabItem>> {
   TabOrderStateNotifier():super([
       TabItem(name: 'common.active', key:'active_count', value: 1, total: 0),
       TabItem(name: 'common.ended', key:'end_count',value: 2, total: 0),
       TabItem(name: 'common.refund',key:'refund_count', value: 4, total: 0),
     ]);

   void updateTabOrderTotal(OrderCount newCountMap) {
     final map = newCountMap.asMap();
     state = [
       for (final item in state)
         item.copyWith(total: map[item.key] ?? 0)
     ];
   }
}

/// Tab order state provider
/// Contains list of TabItem with their totals
/// Used to display order tabs with counts
final tabOrderStateProvider = StateNotifierProvider<TabOrderStateNotifier,List<TabItem>>((ref)=> TabOrderStateNotifier());
