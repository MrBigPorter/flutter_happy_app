import 'dart:async';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/groups.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/models/index.dart';

/// Product category provider, includes "all" category
/// // 使用 autoDispose + keepAlive，既能缓存，又能被 invalidate 强制刷新
final categoryProvider = FutureProvider.autoDispose((ref) async {
  // 1. 保持状态不被销毁，实现“秒开”
  final link = ref.keepAlive();

  // 分类数据在后台 1小时后自动失效，可以加定时器
  Timer(const Duration(minutes: 5), () {
    link.close();
  });

  final res = await Api.getProductCategoryList();
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
//  2: 列表请求构造器
// 注意：这个 Provider 返回的是一个“函数”，而不是数据本身。
// 数据的缓存目前是靠 UI 层的 AutomaticKeepAliveClientMixin 维持的。
// 这种写法下，riverpod 无法直接缓存列表数据，除非改写架构。
// 但对于分页列表来说，目前的写法配合 UI 保活是最高效的。
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
/// // 详情页是用户极其频繁进出的页面，必须缓存！
final productDetailProvider = FutureProvider.autoDispose.family<
    ProductListItem,
    String>((ref, String productId) async {
  // 1. 保持状态不被销毁，实现“秒开”
  final link = ref.keepAlive();

  // 2. 智能销毁策略：
  // 如果用户 5 分钟内没有再次访问这个商品，则释放内存
  // 这样既保证了短时间内反复进出的“秒开”，又防止浏览几百个商品后内存爆炸
  Timer(const Duration(minutes: 5), () {
    link.close();
  });

  return Api.getProductDetail(productId);
});


/// group for treasure items on index page
final groupsListProvider = FutureProvider.family<
    PageResult<GroupForTreasureItem>,
    GroupsListRequestParams>((ref, params) async {
      ref.keepAlive();
  return Api.groupsListApi(params);
});

/// group list provider for treasure detail page
final groupsPageListProvider = Provider.family<PageRequest, String> ((ref, treasureId) {
  return ({required int pageSize, required int page}) {
    return Api.groupsListApi(
        GroupsListRequestParams(
            treasureId: treasureId,
            page: page,
            pageSize: pageSize
        )
    );
  };
});

/// group member list provider
final groupMemberListProvider =
Provider.family<PageRequest<GroupMemberItem>, String>((ref, groupId) {
  return ({required int pageSize, required int page}) {
    return Api.groupMemberListApi(
        GroupMemberListRequestParams(
            groupId: groupId,
            page: page,
            pageSize: 3
        )
    );
  };
});

final productRealtimeStatusProvider = FutureProvider.family<TreasureStatusModel,String>((ref,treasureId) async {
  return Api.getRealTimePriceApi(treasureId);
});