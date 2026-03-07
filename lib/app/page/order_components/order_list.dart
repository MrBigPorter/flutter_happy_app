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


final _orderListCache = <String, PageResult<OrderItem>>{};
final orderListDirtyProvider = StateProvider.family<bool, String>((ref, status) => false);

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
      request: ({required int pageSize, required int page}) async {
        final cacheKey = 'order_list_${widget.status}';
        final fetchApi = ref.read(orderListProvider((status: widget.status, treasureId: null)));

        if (page == 1) {
          final isDirty = ref.read(orderListDirtyProvider(widget.status));

          //  2. 真·SWR 拦截：有缓存且客户端没标记脏
          if (!isDirty && _orderListCache.containsKey(cacheKey)) {

            // ① 派小弟去后台拉取最新数据（对齐服务器端的发货/取消状态）
            fetchApi(pageSize: pageSize, page: 1).then((freshData) {
              if (mounted && _ctl.value.currentPage <= 1) {
                _orderListCache[cacheKey] = freshData;
                // ② 数据回来后，【绕过 Controller，直接修改底层 ValueNotifier】！
                // 这会让 UI 瞬间热更新，已经发货的商品会无缝消失，完全不闪屏！
                _ctl.value = _ctl.value.copyWith(
                  items: freshData.list,
                  hasMore: freshData.list.length < freshData.total,
                  status: freshData.list.isEmpty ? PageStatus.empty : PageStatus.success,
                );
              }
            }).catchError((_) {});

            // ③ 0 毫秒瞬间返回内存里的缓存，消灭一切骨架屏！
            return _orderListCache[cacheKey]!;
          }

          // ============ 正常走网络请求（冷启动或被客户端标记脏了） ============
          final res = await fetchApi(pageSize: pageSize, page: 1);
          _orderListCache[cacheKey] = res;
          if (isDirty) ref.read(orderListDirtyProvider(widget.status).notifier).state = false;
          return res;
        }

        // 第 2 页之后正常加载更多
        return await fetchApi(pageSize: pageSize, page: page);
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

    ref.listen(activeOrderTabProvider, (previous, next) {
      // 只要用户肉眼切到了这个 Tab，不管三七二十一，触发一次静默刷新！
      // 此时它会命中上面的 SWR 拦截，瞬间出图 + 后台对齐服务器！
      if (next.key == widget.status && previous?.key != next.key) {
        _ctl.refresh(clearList: false);
      }
    });


    return _ctl.wrapWithNotification(
      child: ExtendedVisibilityDetector(
        uniqueKey: Key('order_list_visibility_${widget.status}'),
        child: RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact(); // 震动反馈 vibration feedback
            ref.read(orderListDirtyProvider(widget.status).notifier).state = true;
            await _ctl.refresh(clearList: false);
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
                      final tabs = ref.read(tabOrderStateProvider);
                      final targetTab = tabs[2];
                      ref.read(activeOrderTabProvider.notifier).state = tabs[2];// 切到“售后”Tab

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

