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
    final cacheEntry = ApiCacheManager.getCacheEntry(_cacheKey);
    if (cacheEntry.hasData) {
      try {
        final list = (cacheEntry.data as List)
            .map((e) => Banners.fromJson(e))
            .toList();
        if (cacheEntry.state == CacheState.stale) {
          unawaited(_fetchAndCache());
        }
        return list;
      } catch (_) {}
    }
    return await _fetchAndCache();
  }

  Future<List<Banners>> _fetchAndCache() async {
    try {
      final freshData = await Api.bannersApi(bannerCate: 1);
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

  Future<void> forceRefresh() async {
    // 应急恢复：如果 state 已丢失，优先从持久化缓存恢复 UI
    if (!state.hasValue) {
      final cacheEntry = ApiCacheManager.getCacheEntry(_cacheKey);
      if (cacheEntry.hasData) {
        try {
          final list = (cacheEntry.data as List)
              .map((e) => Banners.fromJson(e))
              .toList();
          state = AsyncData(list);
        } catch (_) {}
      }
    }
    await _fetchAndCache();
  }
}

final homeBannerProvider =
    AsyncNotifierProvider<HomeBannerNotifier, List<Banners>>(
      () => HomeBannerNotifier(),
    );

// ==============================================================================
// 2. Treasures SWR Provider (瀑布流商品)
// ==============================================================================
class HomeTreasuresNotifier extends AsyncNotifier<List<IndexTreasureItem>> {
  static const String _cacheKey = 'home_treasures_cache_v1';

  @override
  FutureOr<List<IndexTreasureItem>> build() async {
    final cacheEntry = ApiCacheManager.getCacheEntry(_cacheKey);
    if (cacheEntry.hasData) {
      try {
        final list = (cacheEntry.data as List)
            .map((e) => IndexTreasureItem.fromJson(e))
            .toList();
        if (cacheEntry.state == CacheState.stale) {
          unawaited(_fetchAndCache());
        }
        return list;
      } catch (_) {}
    }
    return await _fetchAndCache();
  }

  Future<List<IndexTreasureItem>> _fetchAndCache() async {
    try {
      final freshData = await Api.indexTreasuresApi();
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

  Future<void> forceRefresh() async {
    // 应急恢复：如果 state 已丢失，优先从持久化缓存恢复 UI
    if (!state.hasValue) {
      final cacheEntry = ApiCacheManager.getCacheEntry(_cacheKey);
      if (cacheEntry.hasData) {
        try {
          final list = (cacheEntry.data as List)
              .map((e) => IndexTreasureItem.fromJson(e))
              .toList();
          state = AsyncData(list);
        } catch (_) {}
      }
    }
    await _fetchAndCache();
  }
}

final homeTreasuresProvider =
    AsyncNotifierProvider<HomeTreasuresNotifier, List<IndexTreasureItem>>(
      () => HomeTreasuresNotifier(),
    );

// ==============================================================================
// 4. Ad SWR Provider (广告数据)
// ==============================================================================
class HomeAdNotifier extends FamilyAsyncNotifier<List<AdRes>, int> {
  static String _cacheKeyOf(int adPosition) =>
      'home_ad_cache_v1_pos_$adPosition';

  @override
  FutureOr<List<AdRes>> build(int adPosition) async {
    final cacheKey = _cacheKeyOf(adPosition);
    final cacheEntry = ApiCacheManager.getCacheEntry(cacheKey);
    if (cacheEntry.hasData) {
      try {
        final list = (cacheEntry.data as List)
            .map((e) => AdRes.fromJson(e))
            .toList();
        if (cacheEntry.state == CacheState.stale) {
          unawaited(_fetchAndCache(adPosition));
        }
        return list;
      } catch (_) {}
    }
    return await _fetchAndCache(adPosition);
  }

  Future<List<AdRes>> _fetchAndCache(int adPosition) async {
    final cacheKey = _cacheKeyOf(adPosition);
    try {
      final freshData = await Api.indexAdApi(adPosition: adPosition);
      ApiCacheManager.setCache(
        cacheKey,
        freshData.map((e) => e.toJson()).toList(),
      );
      if (state.hasValue) state = AsyncData(freshData);
      return freshData;
    } catch (e) {
      if (!state.hasValue) rethrow;
      return state.value!;
    }
  }

  Future<void> forceRefresh() async {
    // 应急恢复：如果 state 已丢失，优先从持久化缓存恢复 UI
    final cacheKey = _cacheKeyOf(arg);
    if (!state.hasValue) {
      final cacheEntry = ApiCacheManager.getCacheEntry(cacheKey);
      if (cacheEntry.hasData) {
        try {
          final list = (cacheEntry.data as List)
              .map((e) => AdRes.fromJson(e))
              .toList();
          state = AsyncData(list);
        } catch (_) {}
      }
    }
    await _fetchAndCache(arg);
  }
}

final homeAdProvider =
    AsyncNotifierProvider.family<HomeAdNotifier, List<AdRes>, int>(
      () => HomeAdNotifier(),
    );
