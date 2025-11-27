import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/order_components/order_list.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/lucky_custom_material_indicator.dart';
import 'package:flutter_app/components/safe_tab_bar_view.dart';
import 'package:flutter_app/core/providers/me_provider.dart';
import 'package:flutter_app/ui/lucky_tab_bar_delegate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nested_scroll_view_plus/nested_scroll_view_plus.dart';

import '../../core/models/order_item.dart';

class OrderListPage extends ConsumerStatefulWidget{
  final dynamic args;
  const OrderListPage({super.key, this.args});

  @override
  ConsumerState<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends ConsumerState<OrderListPage> with SingleTickerProviderStateMixin{

  late TabController _tabController;
  late List<TabItem> _tabs;
  final _outerCtl = ScrollController();


  Future<void> _onRefresh() async {
    Future.wait([
     // ref.refresh(orderCountProvider.future)

    ]);
  }

  @override
  void initState() {
    super.initState();
    _tabs = ref.read(tabOrderStateProvider);
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {

    final tabs = ref.watch(tabOrderStateProvider);

    return BaseScaffold(
      title:'orders'.tr(),
      elevation: 0,
      body: LuckyCustomMaterialIndicator(
          onRefresh: _onRefresh,
          child: NestedScrollViewPlus(
              controller: _outerCtl,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                   SliverPersistentHeader(
                     pinned: true,
                     delegate: LuckySliverTabBarDelegate(
                         height: 38.h,
                         elevation:0.1,
                         enableUnderLine: true,
                         labelStyle: TextStyle(color: context.textSecondary700),
                         showPersistentBg: true,
                         controller: _tabController,
                         tabs: tabs,
                         onTap: (item){
                           ref.read(activeOrderTabProvider.notifier).state = item;
                         },
                         renderItem: (item) {
                          return Text('${item.name}(${item.total})');
                         }
                     ),
                   )
                ];
              },
              body: SafeTabBarView(
                  controller: _tabController,
                  children: tabs.map((item){
                    return OrderList(
                      status: item.key,
                    );
                  }).toList()
              )
          )
      ),
    );
  }
}