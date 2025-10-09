import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/lucky_app_bar.dart';
import 'package:flutter_app/components/product_item.dart';
import 'package:flutter_app/components/tabs.dart';
import 'package:flutter_app/components/featured_skeleton.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
class _ProductPageState extends ConsumerState<ProductPage> {
  late final ScrollController scrollController;
  final ValueNotifier<double> scrollProgress = ValueNotifier(0.0);

  @override
  void initState() {
    super.initState();
    /// initialize scroll controller and listen to scroll events
    scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    final offset = scrollController.offset;
    const double maxHeaderHeight = 120; // max height of header
    const double minHeaderHeight = 60;
    final progress = (offset / (maxHeaderHeight - minHeaderHeight)).clamp(0.0, 1.0);
    scrollProgress.value = progress;
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
    final categoryList = ref.watch(categoryProvider);
    final active = ref.watch(activeCategoryProvider);
    final products = ref.watch(productListProvider);

    Future<void> onRefresh() async {
      ref.invalidate(categoryProvider);
      ref.invalidate(productListProvider);
      await Future.delayed(const Duration(milliseconds: 400));
    }

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: CustomScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              /// 顶部 AppBar（上滑消失）
              SliverPersistentHeader(
                pinned: false,
                delegate: _FadeHeaderDelegate(),
              ),

              /// Tabs（吸顶固定）
              categoryList.when(
                data: (data) => SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabsHeaderDelegate(
                    data: data,
                    active: active,
                    ref: ref,
                    scrollController: scrollController,
                  ),
                ),
                error: (_, __) => const SliverToBoxAdapter(child: FeaturedSkeleton()),
                loading: () => const SliverToBoxAdapter(child: FeaturedSkeleton()),
              ),

              /// 商品列表
              _ListItem(products: products),
            ],
          ),
        ),
      ),
    );
  }
}

/// 渐隐 Header
class _FadeHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 0.0;
  @override
  double get maxExtent => !kIsWeb ? 80.0 : 56.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double fade = (1 - (shrinkOffset / maxExtent)).clamp(0.0, 1.0);

    return SizedBox(
      height: maxExtent,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: fade,
              child: SizedBox(
                height: 56.h * fade,
                child: const LuckyAppBar(showBack: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FadeHeaderDelegate old) => false;
}

/// Tabs 吸顶
class _TabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<ProductCategoryItem> data;
  final ProductCategoryItem active;
  final WidgetRef ref;
  final ScrollController scrollController;

  const _TabsHeaderDelegate({
    required this.data,
    required this.active,
    required this.ref,
    required this.scrollController,
  });

  @override
  double get minExtent => 60.0;
  @override
  double get maxExtent => 60.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
     final height = !kIsWeb ? 90.0 : 60.0;
     double t = (shrinkOffset / maxExtent).clamp(0.0, 1.0);
    if(t > 0) {
      t = 0.8 + t;
    }
    return Container(
      color: context.bgPrimary.withAlpha((255 * t).clamp(0, 255).toInt()),
      alignment: Alignment.center,
      child: Tabs<ProductCategoryItem>(
        data: data,
        activeItem: active,
        renderItem: (item) => Center(
          child: Text(
            item.name,
          ),
        ),
        onChangeActive: (item) {
          ref.read(activeCategoryProvider.notifier).state = item;
          if (scrollController.hasClients && scrollController.offset > height) {
            scrollController.animateTo(
              height,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabsHeaderDelegate old) =>
      old.active != active || old.data != data;
}

/// 商品列表
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
            child: Center(child: Text('No products')),
          );
        }
        return SliverPadding(
          padding: EdgeInsets.all(16.w),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16.w,
              crossAxisSpacing: 16.w,
              childAspectRatio: 166.w / 365.w,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final item = list[index];
                return ProductItem(
                  data: item,
                  imgHeight: 166,
                  imgWidth: 166,
                );
              },
              childCount: list.length,
            ),
          ),
        );
      },
      error: (_, __) => const SliverToBoxAdapter(child: FeaturedSkeleton()),
      loading: () => const SliverToBoxAdapter(child: FeaturedSkeleton()),
    );
  }
}