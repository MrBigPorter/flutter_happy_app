import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/models/index.dart';
/// Product category provider, includes "all" category
final categoryProvider = FutureProvider.autoDispose((ref) async {
 final res =  await Api.getProductCategoryList();
  return [
    ProductCategoryItem(name: "all", id: 0),
    ...res
  ];
});

/// Active category state provider
final activeCategoryProvider = StateProvider<ProductCategoryItem>((ref) {
  return ProductCategoryItem(name: "all", id: 0);
});

/// Product list provider

final productListProvider =
Provider.family<PageRequest<ProductListItem>, int>((ref, id) {
  return ({required int pageSize, required int page}) {
    return Api.getProductList(
      ProductListParams(
        categoryId: id,
        page: page,
        pageSize: pageSize,
      ),
    );
  };
});


/// Product detail provider
final productDetailProvider = FutureProvider.autoDispose.family<ProductListItem, String>((ref, String productId) async {
  return Api.getProductDetail(productId);
});