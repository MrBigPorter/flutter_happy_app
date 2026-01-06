import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/page/order_components/order_item_container.dart';
import 'package:flutter_app/components/list.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_app/core/providers/me_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theme/design_tokens.g.dart';


class OrderList extends ConsumerStatefulWidget {
  final String status;
  const OrderList({super.key,required this.status});

  @override
  ConsumerState<OrderList> createState() => _OrderListState();
}

class _OrderListState extends ConsumerState<OrderList> with AutomaticKeepAliveClientMixin{
  late final PageListController<OrderItem> _ctl;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _ctl = PageListController<OrderItem>(
      requestKey: widget.status,
      request: ({required int pageSize, required int page}) {
        //  用入参 status，不依赖外部 provider no rely on external provider
        return ref.read(orderListProvider((status: widget.status, treasureId: null)))(
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

  void refreshList(){
    _ctl.refresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ref.listen(orderRefreshProvider, (previous, next) {
      if(next.key == widget.status ){
        refreshList();
      }
    });


    return _ctl.wrapWithNotification(
      child: ExtendedVisibilityDetector(
        uniqueKey: Key('order_list_visibility_${widget.status}'),
        child: RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact(); // 震动反馈 vibration feedback
            await _ctl.refresh();
          },
          // 2. 样式配置 (可选，根据你的 UI 规范调整)
          color: context.textBrandPrimary900, // loading 转圈的颜色
          backgroundColor: context.bgPrimary, // loading 背景色(白色)
          displacement: 40.h, // 下拉触发的距离
          child: CustomScrollView(
            key: PageStorageKey('order_list_${widget.status}'),//记住滚动位置 remember scroll position
            physics: platformScrollPhysics(alwaysScrollable: true),
            cacheExtent: 600, // CustomScrollView 加 cacheExtent，在视窗外提前布局一些像素：
            slivers: [
              PageListViewPro<OrderItem>(
                controller: _ctl,
                sliverMode: true,
                separatorSpace: 16,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
                itemBuilder: (context, item, index, isLast) {
                  return OrderItemContainer(
                    item: item,
                    isLast: isLast,
                    onRefresh: (){
                      // 你希望“退款”操作同时刷新“全部”或“售后”Tab，
                      // 在这里触发 orderRefreshProvider，让其他页面监听到并刷新
                      final tabs = ref.read(tabOrderStateProvider);
                      final targetTab = tabs[2];
                      ref.read(activeOrderTabProvider.notifier).state = tabs[2];// 切到“售后”Tab

                      //  强制失效对应的列表 Provider，下次进入该 Tab 会重新触发接口请求
                      // 假设你的列表 Provider 是 orderListProvider(tabKey)

                      // 这会触发 initState 里定义的 request 方法，重新请求接口
                      _ctl.refresh();

                    },
                  );
                },
                skeletonBuilder: (context, {bool isLast = false}) {
                  return  Padding(
                    padding: EdgeInsets.only(
                        top: 16.h
                    ),
                    child: OrderItemContainerSkeleton(isLast: isLast),
                  );
                },
              ),
            ],
          ),
        )
      )
    );
  }
}

