import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/app/page/order_components/order_item_container.dart';
import 'package:flutter_app/components/list.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_app/core/providers/me_provider.dart';

class OrderList extends ConsumerStatefulWidget {
  final int status;
  const OrderList({super.key,required this.status});

  @override
  ConsumerState<OrderList> createState() => _OrderListState();
}

class _OrderListState extends ConsumerState<OrderList> with AutomaticKeepAliveClientMixin{
  late final PageListController<OrderItem> _ctl;

  //  切换不重建 no rebuild on switch
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _ctl = PageListController<OrderItem>(
      requestKey: widget.status,
      request: ({required int pageSize, required int page}) {
        //  用入参 status，不依赖外部 provider no rely on external provider
        final tab = ref.read(activeOrderTabProvider.notifier).state;
        return ref.read(orderListProvider(tab.value))(
          pageSize: pageSize,
          page: page,
        );
      },
    );
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _ctl.wrapWithNotification(
      child: ExtendedVisibilityDetector(
        uniqueKey: Key('order_list_visibility_${widget.status}'),
        child: CustomScrollView(
          key: PageStorageKey('order_list_${widget.status}'),//记住滚动位置 remember scroll position
          physics: platformScrollPhysics(),
          cacheExtent: 600, // CustomScrollView 加 cacheExtent，在视窗外提前布局一些像素：
          slivers: [
            PageListViewPro<OrderItem>(
              controller: _ctl,
              sliverMode: true,
              separatorSpace: 16,
              itemBuilder: (context, item, index, isLast) {
                return OrderItemContainer(item: item, isLast: isLast);
              },
            ),
          ],
        ),
      )
    );
  }
}
