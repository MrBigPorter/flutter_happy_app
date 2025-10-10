import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/lucky_app_bar.dart';
import 'package:flutter_app/components/product_item.dart';
import 'package:flutter_app/components/sticky_header.dart';
import 'package:flutter_app/components/tabs.dart';
import 'package:flutter_app/components/featured_skeleton.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/ui/empty.dart';

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
    scrollProgress.value = offset.clamp(0.0, double.infinity);
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

    return BaseScaffold(
      showBack: false,
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            /// Tabs（吸顶固定）
            categoryList.when(
              data: (data) => StickyHeader.pinned(
                minHeight: 70,
                maxHeight: 70,
                builder: (context, info) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.bgPrimary.withAlpha(
                        (255 * info.progress + 10).clamp(0, 255).toInt(),
                      )
                    ),
                    child: Tabs<ProductCategoryItem>(
                      data: data,
                      activeItem: active,
                      parentHeight: 70,
                      renderItem: (item) => Center(child: Text(item.name)),
                      onChangeActive: (item) {
                        ref.read(activeCategoryProvider.notifier).state = item;
                        if (scrollController.hasClients &&
                            scrollProgress.value > 70) {
                          scrollController.jumpTo(0);
                        }
                      },
                    ),
                  );
                },
              ),
              error: (_, __) =>
                  const SliverToBoxAdapter(child: FeaturedSkeleton()),
              loading: () =>
                  const SliverToBoxAdapter(child: FeaturedSkeleton()),
            ),

            /// 商品列表
            _ListItem(products: products),
          ],
        ),
      ),
    );
  }
}


/// 商品列表
class _ListItem extends StatelessWidget {
  final AsyncValue<List<ProductListItem>> products;

  const _ListItem({required this.products});

  @override
  Widget build(BuildContext context) {
    return products.when(
      data: (list) {
        if (!list.isNullOrEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Empty(),
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
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = list[index];
              return ProductItem(data: item, imgHeight: 166, imgWidth: 166);
            }, childCount: list.length),
          ),
        );
      },
      error: (_, __) => const SliverToBoxAdapter(child: FeaturedSkeleton()),
      loading: () => const SliverToBoxAdapter(child: FeaturedSkeleton()),
    );
  }
}
