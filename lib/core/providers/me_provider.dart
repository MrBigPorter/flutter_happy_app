import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_item.dart';

/// Coupon threshold list provider
final thresholdListProvider = FutureProvider((ref) async {
  return Api.thresholdListApi();
});

/// Order list request provider with pagination and status filter
 typedef OrderProviderParam = ({String status,String? treasureId});
final orderListProvider = Provider.family((ref, OrderProviderParam params) {
  return ({required int pageSize, required int page}) {
    return Api.orderListApi(
      OrderListParams(
        status: params.status,
        treasureId: params.treasureId,
        page: page,
        pageSize: pageSize,
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
    name: 'paid',
    total: 0,
    key: 'paid',
  );
});

/// Tab order
/// Contains list of TabItem with their totals
/// Used to display order tabs with counts
class TabOrderStateNotifier extends StateNotifier<List<TabItem>> {
   TabOrderStateNotifier():super([
       TabItem(name: 'paid', key:'paid', total: 0),
       TabItem(name: 'unpaid', key:'unpaid',total: 0),
       TabItem(name: 'refunded',key:'refunded',total: 0),
       TabItem(name: 'cancelled',key:'cancelled', total: 0),
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
