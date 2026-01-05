import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/providers/me_provider.dart';
import 'order_components/order_list.dart';

class OrderListPage extends ConsumerStatefulWidget {
  final dynamic args;
  const OrderListPage({super.key, this.args});

  @override
  ConsumerState<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends ConsumerState<OrderListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final tabs = ref.read(tabOrderStateProvider);
    _tabController = TabController(length: tabs.length, vsync: this);

    if (widget.args != null && widget.args is Map) {
      final targetStatus = widget.args['status'];
      if (targetStatus != null) {
        final index = tabs.indexWhere((t) => t.key == targetStatus);
        if (index != -1) {
          _tabController.index = index;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(activeOrderTabProvider.notifier).state = tabs[index];
          });
        }
      }
    }

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final tabs = ref.read(tabOrderStateProvider);
        ref.read(activeOrderTabProvider.notifier).state = tabs[_tabController.index];
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ref.watch(tabOrderStateProvider);

    return BaseScaffold(
      title: 'orders'.tr(),
      elevation: 0,
      body: Column(
        children: [
          // --- 1. 顶部 Tab 区域 ---
          Container(
            width: double.infinity,
            color: context.bgPrimary,
            padding: EdgeInsets.symmetric(vertical: 8.w, horizontal: 16.w),
            child: Container(
              height: 44.w,
              decoration: BoxDecoration(
                color: context.bgSecondary,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Theme(
                data: ThemeData(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: TabBar(
                  tabAlignment: TabAlignment.center, // 居中对齐，如果 Tab 少的时候会居中
                  controller: _tabController,
                  isScrollable: true,
                  padding: EdgeInsets.zero,
                  labelPadding: EdgeInsets.symmetric(horizontal: 4.w), // Tab 之间的间距

                  // --- 指示器样式 ---
                  indicator: BoxDecoration(
                    color: context.bgPrimary,
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: EdgeInsets.all(4.w),
                  dividerColor: Colors.transparent,

                  // --- 文字样式 ---
                  labelColor: context.textBrandPrimary900,
                  labelStyle: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700
                  ),
                  unselectedLabelColor: context.textPrimary900,
                  unselectedLabelStyle: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500
                  ),

                  tabs: tabs.map((item) {
                    return Tab(
                      child: Container(
                        // 【修改点 1】减小内部左右间距，让卡片更紧凑 (原 16.w -> 12.w)
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 【修改点 2】限制文字宽度并截断
                            ConstrainedBox(
                              // 这里设置最大宽度，超过这个宽度就会变成 ...
                              // 你可以根据需要调整这个值，比如 60.w 或 80.w
                              constraints: BoxConstraints(maxWidth: 80.w),
                              child: Text(
                                _getTabName(item.key),
                                maxLines: 1, // 限制一行
                                overflow: TextOverflow.ellipsis, // 超出显示省略号
                                softWrap: false,
                              ),
                            ),

                            // --- 数字角标 ---
                            if (item.total > 0) ...[
                              SizedBox(width: 4.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.w),
                                constraints: BoxConstraints(minWidth: 16.w),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: context.utilityError500.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  item.total > 99 ? '99+' : '${item.total}',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: context.utilityError500,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // --- 2. 列表内容 ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: tabs.map((item) {
                return OrderList(
                  status: item.key,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getTabName(String key) {
    switch (key) {
      case 'paid': return 'order.tab.paid'.tr();
      case 'unpaid': return 'order.tab.unpaid'.tr();
      case 'refunded': return 'order.tab.refund'.tr();
      case 'cancelled': return 'order.tab.cancelled'.tr();
      default: return key;
    }
  }
}