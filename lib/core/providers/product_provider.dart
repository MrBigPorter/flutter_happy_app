import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/models/index.dart';
/// Product category provider, includes "all" category
final categoryProvider = FutureProvider((ref) async {
 final res =  await Api.getProductCategoryList();
  return [
    ProductCategoryItem(name: "all", productsCategoryId: 0),
    ...res
  ];
});

/// Active category state provider
final activeCategoryProvider = StateProvider<ProductCategoryItem>((ref) {
  return ProductCategoryItem(name: "all", productsCategoryId: 0);
});

/// Product list provider
final productListProvider = FutureProvider((ref) async {
  final id = ref.watch(activeCategoryProvider).productsCategoryId;
  return Api.getProductList(id);
});