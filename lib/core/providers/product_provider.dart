import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/groups.dart';
import 'package:flutter_app/utils/cache/cache_for_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/models/index.dart';

import '../cache/api_cache_manager.dart';

// ==============================================================================
// 1. 分类 Tab SWR Provider (瞬间直出分类)
// ==============================================================================
class CategoryNotifier extends AsyncNotifier<List<ProductCategoryItem>> {
  static const String _cacheKey = 'product_category_cache_v1';

  @override
  FutureOr<List<ProductCategoryItem>> build() async {
    //  SWR 阶段 1: 极速读取缓存
    final cachedData = ApiCacheManager.getCache(_cacheKey);
    if (cachedData != null) {
      try {
        final list = (cachedData as List)
            .map((e) => ProductCategoryItem.fromJson(e))
            .toList();
        _fetchAndCache(); // 后台静默拉取最新分类
        return list; // 瞬间返回，UI 的 TabBar 立即渲染！
      } catch (_) {}
    }

    //  SWR 阶段 2: 无缓存时，阻塞等待网络
    return await _fetchAndCache();
  }

  Future<List<ProductCategoryItem>> _fetchAndCache() async {
    try {
      final res = await Api.getProductCategoryList();
      final freshData = [ProductCategoryItem(name: "all", id: 0), ...res];

      // 写入缓存
      ApiCacheManager.setCache(
        _cacheKey,
        freshData.map((e) => e.toJson()).toList(),
      );

      // 静默覆盖 UI
      if (state.hasValue) state = AsyncData(freshData);

      return freshData;
    } catch (e) {
      if (!state.hasValue) rethrow;
      return state.value!;
    }
  }

  Future<void> forceRefresh() async => await _fetchAndCache();
}

final categoryProvider =
    AsyncNotifierProvider<CategoryNotifier, List<ProductCategoryItem>>(() {
      return CategoryNotifier();
    });

/// 选中的分类状态
final activeCategoryProvider = StateProvider<ProductCategoryItem>((ref) {
  return ProductCategoryItem(name: "all", id: 0);
});

// ==============================================================================
// 2. 核心列表 Provider (拦截 page == 1 实现列表首屏秒开)
// ==============================================================================
final productListProvider = Provider.family<PageRequest<ProductListItem>, int>((
  ref,
  id,
) {
  return ({required int pageSize, required int page}) async {
    // 为每个分类的“第一页”生成独立的 Cache Key
    final String cacheKey = 'product_list_category_${id}_page_1';

    // Banners 核心优化：拦截第一页请求，尝试瞬间返回缓存
    if (page == 1) {
      final cachedData = ApiCacheManager.getCache(cacheKey);

      if (cachedData != null) {
        try {
          final List<dynamic> rawList = cachedData['list'] ?? [];
          final items = rawList
              .map((e) => ProductListItem.fromJson(e))
              .toList();

          final cachedResult = PageResult<ProductListItem>(
            list: items,
            total: cachedData['total'] ?? items.length,
            // 如果缓存里有总数就用，没有就默认当前长度
            page: 1,
            // 既然拦截的是第一页，必定是 1
            count: items.length,
            // 当前页数量
            pageSize: pageSize, // UI 传进来的 pageSize
          );
          //  静默后台刷新：派出一个小弟去后台拉取最新数据，保证数据新鲜
          Future.microtask(() async {
            try {
              final freshData = await Api.getProductList(
                ProductListParams(categoryId: id, page: 1, pageSize: pageSize),
              );
              ApiCacheManager.setCache(cacheKey, {
                'list': freshData.list.map((e) => e.toJson()).toList(),
              });
            } catch (_) {}
          });

          return cachedResult; // ⚡ 瞬间出图！没有任何骨架屏等待！
        } catch (e) {
          debugPrint('列表缓存解析失败，降级网络请求: $e');
        }
      }
    }

    //  正常网络请求 (无缓存 或 请求 page > 1)
    final res = await Api.getProductList(
      ProductListParams(categoryId: id, page: page, pageSize: pageSize),
    );

    // 如果成功拉取到第一页，顺手存入缓存供下次秒开
    if (page == 1) {
      ApiCacheManager.setCache(cacheKey, {
        'list': res.list.map((e) => e.toJson()).toList(),
      });
    }

    return res;
  };
});


/// Product detail provider (保留你原来的智能销毁策略)
final productDetailProvider = FutureProvider.autoDispose
    .family<ProductListItem, String>((ref, String productId) async {
      final link = ref.keepAlive();
      Timer(const Duration(minutes: 5), () {
        link.close();
      });
      return Api.getProductDetail(productId);
    });

/// group for treasure items on index page
final groupsListProvider =
    FutureProvider.family<
      PageResult<GroupForTreasureItem>,
      GroupsListRequestParams
    >((ref, params) async {
      ref.keepAlive();
      return Api.groupsListApi(params);
    });

/// 详情页“正在拼团”预览 Provider
final groupsPreviewProvider = FutureProvider.autoDispose
    .family<List<GroupForTreasureItem>, String>((ref, treasureId) async {
      ref.cacheFor(Duration(seconds: 5));
      final res = await Api.groupsListApi(
        GroupsListRequestParams(treasureId: treasureId, page: 1, pageSize: 2),
      );
      return res.list;
    });

/// group list provider for treasure detail page
final groupsPageListProvider =
    Provider.family<PageRequest<GroupForTreasureItem>, String>((
      ref,
      treasureId,
    ) {
      return ({required int pageSize, required int page}) {
        return Api.groupsListApi(
          GroupsListRequestParams(
            treasureId: treasureId,
            page: page,
            pageSize: pageSize,
          ),
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
            pageSize: 3,
          ),
        );
      };
    });

final productRealtimeStatusProvider =
    FutureProvider.family<TreasureStatusModel, String>((ref, treasureId) async {
      return Api.getRealTimePriceApi(treasureId);
    });

final groupDetailProvider = FutureProvider.autoDispose
    .family<GroupDetailModel, String>((ref, groupId) async {
      return Api.getGroupDetailApi(groupId);
    });

// ==============================================================================
// 4. 首页热门拼团 SWR Provider (保持不变，已支持秒开)
// ==============================================================================
class HomeGroupBuyingNotifier extends AsyncNotifier<List<ProductListItem>> {
  static const String _cacheKey = 'home_group_buying_cache_v1';

  @override
  FutureOr<List<ProductListItem>> build() async {
    final cachedData = ApiCacheManager.getCache(_cacheKey);
    if (cachedData != null) {
      try {
        final list = (cachedData as List)
            .map((e) => ProductListItem.fromJson(e))
            .toList();
        _fetchAndCache();
        return list;
      } catch (_) {}
    }
    return await _fetchAndCache();
  }

  Future<List<ProductListItem>> _fetchAndCache() async {
    try {
      final hotList = await Api.getTreasureHotGroups(10);
      final freshData = hotList.map((e) => e.toProductListItem()).toList();
      ApiCacheManager.setCache(
        _cacheKey,
        freshData.map((e) => e.toJson()).toList(),
      );
      if (state.hasValue) state = AsyncData(freshData);
      return freshData;
    } catch (e) {
      if (!state.hasValue) rethrow;
      return state.value!;
    }
  }

  Future<void> forceRefresh() async => await _fetchAndCache();
}

final homeGroupBuyingProvider =
    AsyncNotifierProvider<HomeGroupBuyingNotifier, List<ProductListItem>>(() {
      return HomeGroupBuyingNotifier();
    });
