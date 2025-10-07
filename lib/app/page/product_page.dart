import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/featured_skeleton.dart';
import 'package:flutter_app/components/lucky_app_bar.dart';
import 'package:flutter_app/components/product_item.dart';
import 'package:flutter_app/components/tabs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/core/models/index.dart';

class ProductPage extends ConsumerStatefulWidget {
  const ProductPage({super.key});

  @override
  ConsumerState<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<ProductPage> {
  /// tell the CustomScrollView to scroll to top when category changed
  /// late used to avoid null safety issue
  late final ScrollController scrollController;
  final ValueNotifier<double> scrollProgress = ValueNotifier(0.0);

  @override
  void initState() {
    super.initState();

    /// initialize scroll controller
    scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    final offset = scrollController.offset;
    double maxHeaderHeight = 132; // app bar height + tabs height + padding
    double minHeaderHeight = 60;
    final progress = (offset / (maxHeaderHeight - minHeaderHeight)).clamp(
      0.0,
      1.0,
    );
    scrollProgress.value = progress;
  }

  @override
  void dispose() {
    /// dispose scroll controller
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    scrollProgress.dispose();
    super.dispose();

  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final categoryList = ref.watch(categoryProvider);
    final active = ref.watch(activeCategoryProvider);
    final products = ref.watch(productListProvider);

    // get device pixel ratio for header delegate
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    Future<void> onRefresh() async {
      ref.invalidate(categoryProvider);
      ref.invalidate(productListProvider);
      await Future.delayed(const Duration(milliseconds: 400));
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          /// use the scroll controller, you need to bind it to the CustomScrollView
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            /// app bar
            SliverPersistentHeader(
              pinned: false,
              delegate: _FixedHeaderDelegate(
                minHeight: 56.h,
                maxHeight: 56.h,
                devicePixelRatio: devicePixelRatio,
                child: ValueListenableBuilder<double>(
                  valueListenable: scrollProgress,
                  builder: (context, value, _) {
                    final opacity = (1 - value).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: opacity,
                      child: const LuckyAppBar(showBack: false),
                    );
                  },
                ),
              ),
            ),
            _CategoryTabs(
              categoryList: categoryList,
              devicePixelRatio: devicePixelRatio,
              scrollProgress: scrollProgress,
              active: active,
              ref: ref,
              scrollController: scrollController
            ),
            _ListItem(products: products),
          ],
        ),
      ),
    );
  }
}

/// Fixed header delegate for SliverPersistentHeader
class _FixedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double maxHeight;
  final double minHeight;
  final Widget child;
  final double devicePixelRatio;

  const _FixedHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
    required this.devicePixelRatio,
  });

  double _pxFloor(double logical) {
    return (logical * devicePixelRatio).floor() / devicePixelRatio;
  }

  @override
  double get minExtent => _pxFloor(minHeight);

  @override
  double get maxExtent => _pxFloor(max(minHeight, maxHeight));

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _FixedHeaderDelegate old) =>
      old.minHeight != minHeight ||
      old.maxHeight != maxHeight ||
      old.devicePixelRatio != devicePixelRatio ||
      old.child != child;
}

class _CategoryTabs extends StatelessWidget {
  final AsyncValue<List<ProductCategoryItem>> categoryList;
  final double devicePixelRatio;
  final ValueNotifier<double> scrollProgress;
  final ProductCategoryItem active;
  final WidgetRef ref;
  final ScrollController scrollController;

     const _CategoryTabs({
        required this.categoryList,
        required this.devicePixelRatio,
        required this.scrollProgress,
        required this.active,
        required this.ref,
        required this.scrollController
    });

  @override
  Widget build(BuildContext context) {
    return categoryList.when(
        data: (data) => SliverPersistentHeader(
          pinned: true,
          delegate: _FixedHeaderDelegate(
            minHeight: 60.w,
            maxHeight: 60.w,
            devicePixelRatio: devicePixelRatio,
            child: ValueListenableBuilder<double>(
              valueListenable: scrollProgress,
              builder: (context, value, _) {
                final progress = value.clamp(0.0, 1.0);
                // over 0.2 start to change background color
                final start = 0.9;
                // normalize t to 0-1
                final t = (progress - start) / (1 - start);
                final easedT = Curves.easeOut.transform(t.clamp(0.0, 1.0));
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 8.w),
                  decoration: BoxDecoration(
                    color: Color.lerp(Colors.transparent, context.bgPrimary, easedT),
                    border: Border(
                      bottom: BorderSide(
                        color: Color.lerp(Colors.transparent, context.bgSecondary, easedT)!,
                        width: 1 - progress,
                      ),
                    ),
                  ),
                  child: Tabs<ProductCategoryItem>(
                    data: data,
                    activeItem: active,
                    renderItem: (item) => Center(child: Text(item.name)),
                    onChangeActive: (item) {
                      ref.read(activeCategoryProvider.notifier).state = item;
                      if(scrollController.hasClients){
                        final double appBarHeight = (56.h);
                        if(scrollProgress.value >= 1.0){
                          scrollController.animateTo(appBarHeight, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                        }
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ),
        error: (_, __) => SliverToBoxAdapter(
          child: Tabs(
            data: [],
            activeItem: '',
            renderItem: (item) => SizedBox.shrink(),
            onChangeActive: (item) => {},
          ),
        ),
        loading: () => SliverToBoxAdapter(
          child: Tabs(
            data: [],
            activeItem: '',
            renderItem: (item) => SizedBox.shrink(),
            onChangeActive: (item) => {},
          ),
        ),
      );
  }
}

/// product list item
class _ListItem extends StatelessWidget {
  final AsyncValue<List<ProductListItem>> products;
  const _ListItem({required this.products});

  @override
  Widget build(BuildContext context) {
    return products.when(
        data: (list) {
          if (list.isEmpty) {
            return const SliverFillRemaining(
              hasScrollBody: false,
              child: Text('No products'),
            );
          }
          return SliverPadding(
            padding: EdgeInsets.only(
              top: 16.w,
              bottom: 20.w,
              left: 16.w,
              right: 16.w,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16.w,
                crossAxisSpacing: 16.w,
                childAspectRatio: 166.w / 365.w,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = list[index];
                return ProductItem(
                  data: item,
                  imgHeight: 166,
                  imgWidth: 166,
                );
              }, childCount: list.length),
            ),
          );
        },
        error: (_, __) => SliverToBoxAdapter(child: FeaturedSkeleton()),
        loading: () => SliverToBoxAdapter(child: FeaturedSkeleton()),
      );
  }
}
