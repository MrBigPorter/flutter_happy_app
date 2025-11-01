import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/list.dart';
import 'package:flutter_app/components/lucky_custom_material_indicator.dart';
import 'package:flutter_app/components/product_item.dart';
import 'package:flutter_app/components/safe_tab_bar_view.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/ui/animated_list_item.dart';
import 'package:flutter_app/ui/lucky_tab_bar_delegate.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:nested_scroll_view_plus/nested_scroll_view_plus.dart';

/// 商品页 Product Page
class ProductPage extends ConsumerStatefulWidget {
  const ProductPage({super.key});

  @override
  ConsumerState<ProductPage> createState() => _ProductPageState();
}

/// 商品页状态 Product Page State
/// use CustomScrollView with Slivers to achieve app bar fade out on scroll
/// and tabs stick to top
/// and product list below tabs
class _ProductPageState extends ConsumerState<ProductPage> with SingleTickerProviderStateMixin {
  late final ScrollController scrollController;
  final ValueNotifier<double> scrollProgress = ValueNotifier(0.0);
  TabController? _tabController;
  List<ProductCategoryItem> _tabs = const [];

  @override
  void initState() {
    super.initState();

    Future.microtask(() async{
      final category = await ref.read(categoryProvider.future);
      _initializeCategory(category);
    });


  }

  void _initializeCategory(List<ProductCategoryItem> category){
    if (category.isNotEmpty) {
      setState(() {
        _tabs = category;
      });
      _tabController = TabController(length: category.length, vsync: this);
    }

  }


  @override
  void dispose() {
    scrollController.dispose();
    scrollProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;

    Future<bool> onRefresh() async {
      Future.wait([
        ref.refresh(categoryProvider.future),
        //ref.refresh(productListProvider.future),
      ]);
      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    }

    return BaseScaffold(
      showBack: false,
      body: LuckyCustomMaterialIndicator(
          onRefresh: onRefresh,
          child: NestedScrollViewPlus(
              overscrollBehavior: OverscrollBehavior.outer,
              physics: platformScrollPhysics(),
              headerSliverBuilder: (context,_)=>[
                SliverPersistentHeader(
                  pinned: true,
                  delegate: LuckySliverTabBarDelegate(
                    showPersistentBg: true,
                    height: 60,
                    tabs: _tabs,
                    renderItem: (t) => Tab(text: t.name),
                    controller: _tabController,
                    onTap: (item){
                      ref.read(activeCategoryProvider.notifier).state = item;
                    },
                  ),
                )

              ],
              body: SafeTabBarView(
                  controller: _tabController,
                  children: _tabs.map((tab) {
                    return ExtendedVisibilityDetector(
                      uniqueKey: Key('product_list_${tab.id}'),
                      child: _List(categoryId: tab.id,),
                    );
                  }).toList()
              ),
          )
      ),
    );
  }
}

class _List extends ConsumerStatefulWidget {
  final int categoryId;

  const _List({required this.categoryId});

  @override
  ConsumerState<_List> createState() => _ListState();
}

/// 商品列表
class _ListState extends ConsumerState<_List> {
  late final PageListController<ProductListItem> _ctl;

  @override
  void initState() {
    super.initState();

    _ctl = PageListController<ProductListItem>(
        request: ({required int pageSize, required int page}) {
          final req = ref.read(productListProvider(widget.categoryId));
          return req(
            pageSize: pageSize,
            page: page,
          );
        },
        requestKey: widget.categoryId
    );
  }


  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return CustomScrollView(
      physics: platformScrollPhysics(),
      key: PageStorageKey<String>('product_list_${widget.categoryId}'),
      slivers: [
        PageListViewPro(
            controller: _ctl,
            sliverMode: true,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 22.w,
              crossAxisSpacing: 16.w,
              childAspectRatio: 166 / 365,
            ),
            itemBuilder: (context, item, index, isLast){
              return AnimatedListItem(index: index, child: ProductItem(data: item, imgHeight: 166, imgWidth: 166));
            }
        ),

      ],
    );

  }
}
