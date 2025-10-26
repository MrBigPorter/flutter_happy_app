import 'package:flutter/cupertino.dart';
import 'package:flutter_app/app/page/order_components/order_item_container.dart';
import 'package:flutter_app/components/list.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/providers/me_provider.dart';

class OrderList extends ConsumerStatefulWidget{

  const OrderList({super.key});

  @override
  ConsumerState<OrderList> createState() => _OrderListState();
}

class _OrderListState extends ConsumerState<OrderList>{

  late final PageListController<OrderItem> _ctl;

  @override
  void initState() {
    super.initState();

    _ctl = PageListController<OrderItem>(
      request: ({required int pageSize, required int current}) {
        // Replace 'all' with the desired status or make it dynamic
        return ref.read(orderListProvider('all'))(
          pageSize: pageSize,
          current: current,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: platformScrollPhysics(),
      slivers: [
        PageListViewPro<OrderItem>(
            controller: _ctl,
            sliverMode: true,
            separatorSpace: 16,
            itemBuilder: (context, item, index, isLast) {
              return OrderItemContainer(item: item, isLast: isLast);
            }
        )
      ],
    );
  }
}