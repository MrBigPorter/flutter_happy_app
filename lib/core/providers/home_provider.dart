import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/core/cache/api_cache_manager.dart';

// add a global provider to trigger home refresh when returning from other pages
final homeNeedsRefreshProvider = StateProvider<bool>((ref) => false);

// ==============================================================================
// 1. Banner SWR Provider (首页轮播图)
// ==============================================================================
class HomeBannerNotifier extends AsyncNotifier<List<Banners>> {
  static const String _cacheKey = 'home_banners_cache_v1';

  @override
  FutureOr<List<Banners>> build() async {
    //  SWR 阶段 1: 极速读取缓存
    final cachedData = ApiCacheManager.getCache(_cacheKey);
    if (cachedData != null) {
      try {
        final list = (cachedData as List).map((e) => Banners.fromJson(e)).toList();
        _fetchAndCache(); // 后台静默刷新
        return list;      // 瞬间返回缓存，秒开
      } catch (_) {}
    }
    //  SWR 阶段 2: 无缓存时阻塞等网络
    return await _fetchAndCache();
  }

  Future<List<Banners>> _fetchAndCache() async {
    try {
      final freshData = await Api.bannersApi(bannerCate: 1);
      // 写入缓存
      ApiCacheManager.setCache(_cacheKey, freshData.map((e) => e.toJson()).toList());
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
final homeBannerProvider = AsyncNotifierProvider<HomeBannerNotifier, List<Banners>>(() => HomeBannerNotifier());


// ==============================================================================
// 2. Treasures SWR Provider (瀑布流商品)
// ==============================================================================
class HomeTreasuresNotifier extends AsyncNotifier<List<IndexTreasureItem>> {
  static const String _cacheKey = 'home_treasures_cache_v1';

  @override
  FutureOr<List<IndexTreasureItem>> build() async {
    final cachedData = ApiCacheManager.getCache(_cacheKey);
    if (cachedData != null) {
      try {
        final list = (cachedData as List).map((e) => IndexTreasureItem.fromJson(e)).toList();
        _fetchAndCache();
        return list;
      } catch (_) {}
    }
    return await _fetchAndCache();
  }

  Future<List<IndexTreasureItem>> _fetchAndCache() async {
    try {
      final freshData = await Api.indexTreasuresApi();
      ApiCacheManager.setCache(_cacheKey, freshData.map((e) => e.toJson()).toList());
      if (state.hasValue) state = AsyncData(freshData);
      return freshData;
    } catch (e) {
      if (!state.hasValue) rethrow;
      return state.value!;
    }
  }

  Future<void> forceRefresh() async => await _fetchAndCache();
}
final homeTreasuresProvider = AsyncNotifierProvider<HomeTreasuresNotifier, List<IndexTreasureItem>>(() => HomeTreasuresNotifier());



// ==============================================================================
// 4. Ad SWR Provider (广告数据 - 如果需要)
// ==============================================================================
class HomeAdNotifier extends AsyncNotifier<List<AdRes>> {
  static const String _cacheKey = 'home_ad_cache_v1';

  @override
  FutureOr<List<AdRes>> build() async {
    final cachedData = ApiCacheManager.getCache(_cacheKey);
    if (cachedData != null) {
      try {
        final list = (cachedData as List).map((e) => AdRes.fromJson(e)).toList();
        _fetchAndCache();
        return list;
      } catch (_) {}
    }
    return await _fetchAndCache();
  }

  Future<List<AdRes>> _fetchAndCache() async {
    try {
      final freshData = await Api.indexAdApi(adPosition: 1);
      ApiCacheManager.setCache(_cacheKey, freshData.map((e) => e.toJson()).toList());
      if (state.hasValue) state = AsyncData(freshData);
      return freshData;
    } catch (e) {
      if (!state.hasValue) rethrow;
      return state.value!;
    }
  }
  Future<void> forceRefresh() async => await _fetchAndCache();
}
final homeAdProvider = AsyncNotifierProvider<HomeAdNotifier, List<AdRes>>(() => HomeAdNotifier());

