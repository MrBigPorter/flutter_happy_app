import 'package:flutter/material.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/list.dart';
import 'package:flutter_app/components/lucky_custom_material_indicator.dart';
import 'package:flutter_app/components/product_item.dart';
import 'package:flutter_app/components/safe_tab_bar_view.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/ui/animated_list_item.dart';
import 'package:flutter_app/ui/lucky_tab_bar_delegate.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:nested_scroll_view_plus/nested_scroll_view_plus.dart';

/// 商品页状态 Product Page State
class ProductPage extends ConsumerWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听分类数据，使用 SWR 机制，缓存瞬间直出
    final categoriesAsync = ref.watch(categoryProvider);

    return BaseScaffold(
      showBack: false,
      elevation: 0,
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No Categories Found'));
          }
          return _ProductContent(categories: categories);
        },
        loading: () => const _ProductLoadingSkeleton(),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $err'),
              TextButton(
                onPressed: () => ref.refresh(categoryProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 商品页内容 Product Page Content
class _ProductContent extends ConsumerStatefulWidget {
  final List<ProductCategoryItem> categories;

  const _ProductContent({required this.categories});

  @override
  ConsumerState<_ProductContent> createState() => _ProductContentState();
}

class _ProductContentState extends ConsumerState<_ProductContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initTabController();
  }

  @override
  void didUpdateWidget(covariant _ProductContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 核心优化：深度比较 ID
    // 防止 SWR 后台拉取新数据时，因为内存地址变更导致 TabController 强行重置
    bool isSameCategories = _checkIfCategoriesSame(oldWidget.categories, widget.categories);

    if (!isSameCategories) {
      _tabController.dispose();
      _initTabController();
      setState(() {});
    }
  }

  // 手动比对 ID 和长度，确保滑动位置绝对稳定
  bool _checkIfCategoriesSame(List<ProductCategoryItem> oldList, List<ProductCategoryItem> newList) {
    if (oldList.length != newList.length) return false;
    for (int i = 0; i < oldList.length; i++) {
      if (oldList[i].id != newList[i].id) return false;
    }
    return true;
  }

  void _initTabController() {
    _tabController = TabController(
      length: widget.categories.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // ref.read(activeCategoryProvider.notifier).state = widget.categories[_tabController.index];
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
    // 下拉刷新逻辑
    Future<bool> onRefresh() async {
      try {
        final currentCatId = widget.categories[_tabController.index].id;

        // 1. 刷新当前选中分类的列表数据
        ref.invalidate(productListProvider(currentCatId));

        // 2.  使用 forceRefresh 强制且静默更新顶部分类栏，不闪白屏
        ref.read(categoryProvider.notifier).forceRefresh();

        return true;
      } catch (e) {
        return false;
      }
    }

    return LuckyCustomMaterialIndicator(
      onRefresh: onRefresh,
      child: NestedScrollViewPlus(
        overscrollBehavior: OverscrollBehavior.outer,
        physics: const AlwaysScrollableScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverPersistentHeader(
              pinned: true,
              delegate: LuckySliverTabBarDelegate(
                showPersistentBg: true,
                height: 60,
                tabs: widget.categories,
                renderItem: (t) => Tab(text: t.name),
                controller: _tabController,
                onTap: (item) {
                  ref.read(activeCategoryProvider.notifier).state = item;
                },
              ),
            ),
          ];
        },
        body: SafeTabBarView(
          controller: _tabController,
          children: widget.categories.map((category) {
            return _List(
              // Key 非常重要，保证 Tab 状态复用
              key: PageStorageKey<String>('cat_${category.id}'),
              categoryId: category.id,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _List extends ConsumerStatefulWidget {
  final int categoryId;

  const _List({super.key, required this.categoryId});

  @override
  ConsumerState<_List> createState() => _ListState();
}

/// 混入 AutomaticKeepAliveClientMixin 实现页面保活
class _ListState extends ConsumerState<_List>
    with AutomaticKeepAliveClientMixin {
  late final PageListController<ProductListItem> _ctl;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _ctl = PageListController<ProductListItem>(
      request: ({required int pageSize, required int page}) {
        final req = ref.read(productListProvider(widget.categoryId));
        return req(pageSize: pageSize, page: page);
      },
      requestKey: widget.categoryId,
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
          itemBuilder: (context, item, index, isLast) {
            return RepaintBoundary(
              child: AnimatedListItem(
                index: index,
                child: ProductItem(data: item, imgHeight: 166, imgWidth: 166),
              ),
            );
          },
          skeletonBuilder: (context, {bool isLast = false}) {
            return RepaintBoundary(child: const ProductItemSkeleton());
          },
        ),
      ],
    );
  }
}

class _ProductLoadingSkeleton extends StatelessWidget {
  const _ProductLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return NestedScrollViewPlus(
      physics: const NeverScrollableScrollPhysics(),
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverPersistentHeader(
            pinned: true,
            delegate: LuckySliverTabBarDelegate(
              showPersistentBg: true,
              height: 60,
              tabs: List.generate(
                4,
                    (index) => ProductCategoryItem(id: index, name: '分类$index'),
              ),
              renderItem: (t) => Skeleton.react(
                width: 60.w,
                height: 30.h,
                borderRadius: BorderRadius.circular(8.h),
              ),
              controller: null,
              onTap: (item) {},
            ),
          ),
        ];
      },
      body: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                    RepaintBoundary(child: const ProductItemSkeleton()),
                childCount: 10,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 22,
                crossAxisSpacing: 16,
                childAspectRatio: 166 / 365,
              ),
            ),
          ),
        ],
      ),
    );
  }
}