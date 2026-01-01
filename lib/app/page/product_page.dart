import 'package:flutter/foundation.dart';
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
/// use CustomScrollView with Slivers to achieve app bar fade out on scroll
/// and tabs stick to top
/// and product list below tabs
class ProductPage extends ConsumerWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 使用 Riverpod 监听分类数据，自动处理 Loading/Error
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
        loading: () => _ProductLoadingSkeleton(),
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
    //  优化 1: 更严谨的比较逻辑
    // 仅仅比较 length 是不够的，如果分类 ID 变了但数量没变，会导致 Tab 显示错误
    if (!listEquals(oldWidget.categories, widget.categories)) {
      _tabController.dispose();
      _initTabController();
      setState(() {});
    }
  }

  void _initTabController() {
    _tabController = TabController(
      length: widget.categories.length,
      vsync: this,
    );
    // 同步当前选中的分类到 Provider
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        //final curCategory = widget.categories[_tabController.index];
        // 注意：这会导致频繁通知，根据业务需求决定是否需要同步给 activeCategoryProvider
        // ref.read(activeCategoryProvider.notifier).state = curCategory;
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
        //  优化 2: 刷新逻辑
        // invalidate 会导致 Provider 重置，配合 PageListController 的 requestKey 变化
        // 或者 PageListController 内部监听了 Provider 变化，从而触发刷新
        ref.invalidate(productListProvider(currentCatId));

        // 可选：如果需要在下拉时同时刷新分类配置
        // ref.refresh(categoryProvider);

        return true;
      } catch (e) {
        return false;
      }
    }

    return LuckyCustomMaterialIndicator(
      onRefresh: onRefresh,
      child: NestedScrollViewPlus(
        overscrollBehavior: OverscrollBehavior.outer,
        physics: const AlwaysScrollableScrollPhysics(), // 确保不满一屏也能下拉
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverPersistentHeader(
              pinned: true,
              delegate: LuckySliverTabBarDelegate(
                showPersistentBg: true,
                height: 60,
                // 建议用 .w 适配: 60.w
                tabs: widget.categories,
                renderItem: (t) => Tab(text: t.name),
                controller: _tabController,
                onTap: (item) {
                  // 点击 Tab 时的逻辑
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
              //  优化 3: Key 的唯一性非常重要，确保 Tab 切换时 Element 树能正确复用或重建
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

/// 商品列表6. 混入 AutomaticKeepAliveClientMixin 实现页面保活
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
