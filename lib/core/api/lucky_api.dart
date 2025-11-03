import 'dart:convert';
import 'dart:math';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/coupon_threshold_data.dart';

import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_app/core/models/index.dart';

class Api {
  /// 首页轮播图 type 1: banner 2: 广告 home banner
  static Future<List<Banners>> bannersApi({
    required int bannerCate,
    int? position,
    int? state,
    int? validState,
    int? limit = 10,
  }) async {
    final query = {
      'bannerCate': bannerCate,
      'limit': limit,
      'state': state,
      'validState': validState,
      'position': position,
    }..removeWhere((key, value) => value == null);

    final res = await Http.get(
      "/api/v1/banners",
      query: query
    );
    return parseList<Banners>(res, (e) => Banners.fromJson(e));
  }

  /// 首页宝藏推荐  home treasures
  static Future<List<IndexTreasureItem>> indexTreasuresApi() async {
    final res = await Http.get("/api/v1/home/sections",query: {
      'limit': 10,
    });

    return parseList<IndexTreasureItem>(
      res,
      (e) => IndexTreasureItem.fromJson(e),
    );
  }

  /// 首页广告 type 1: banner 2: 广告 home ad
  static Future<List<AdRes>> indexAdApi({
    required int adPosition,
    int? status,
    int? limit = 2,
}) async {
    final query = {
      'adPosition': adPosition,
      'status': status,
      'limit': limit,
    }..removeWhere((key, value) => value == null);
    final res = await Http.get("/api/v1/ads",query: query);
    return parseList<AdRes>(res, (e) => AdRes.fromJson(e));
  }

  /// 首页统计数据 home statistics
  static Future<IndexStatistics> indexStatisticsApi() async {
    final res = await Http.get("/homepageStatisticalData.json");
    return IndexStatistics.fromJson(res);
  }

  /// 用户信息 user info
  static Future<UserInfo> getUserInfo() async {
    final res = await Http.get("user/info");
    return UserInfo.fromJson(jsonDecode(res));
  }

  /// 钱包余额 wallet balance
  static Future<Balance> getWalletBalance() async {
    final res = await Http.get('/balance.json');
    return Balance.fromJson(res);
  }

  /// 系统配置 sys config
  static Future<SysConfig> getSysConfig() async {
    final res = await Http.get('/sysConfigGet.json');
    return SysConfig.fromJson(res);
  }

  /// 商品分类 product category tabs
  static Future<List<ProductCategoryItem>> getProductCategoryList() async {
    final res = await Http.get('/api/v1/categories');
    return parseList<ProductCategoryItem>(
      res,
      (e) => ProductCategoryItem.fromJson(e),
    );
  }

  /// 商品列表 product list
  /// products_category_id 0: all
  /// products_category_id 1: hot
  /// products_category_id 2: tech
  static Future<PageResult<ProductListItem>> getProductList(
    ProductListParams params,
  ) async {
    final res = await Http.get(
      '/api/v1/treasure',
      queryParameters: {
        'page': params.page,
        'pageSize': params.pageSize,
        "categoryId": params.categoryId,
      },
    );
    return parsePageResponse(res, (e) => ProductListItem.fromJson(e));
  }

  /// 中奖总人数 total winners quantity
  static Future<WinnersQuantity> winnersQuantityApi() async {
    final res = await Http.get('/actWinnersQuantity.json');
    return WinnersQuantity.fromJson(res);
  }

  /// 最新中奖名单 latest winners list
  static Future<List<WinnersLastsItem>> winnersLastsApi() async {
    final res = await Http.get('/actWinnersLasts.json');
    return parseList<WinnersLastsItem>(
      res,
      (e) => WinnersLastsItem.fromJson(e),
    );
  }

  /// 月度活动数据 monthly activity data
  static Future<List<int>> actMonthNumApi() async {
    final res = await Http.get('/actMonthNum.json');
    return (res as List).map((e) => e as int).toList();
  }

  /// 月度中奖名单 monthly winners list
  /// returns paginated result

  static Future<PageResult<ActWinnersMonth>> winnersMonthApi(
    ActWinnersMonthParams params,
  ) async {
    final res = await Http.get(
      '/actWinnersMonth.json',
      queryParameters: {
        "month": params.month,
        "page": params.page,
        "size": params.size,
      },
    );

    final result = parsePageResponse(res, (e) => ActWinnersMonth.fromJson(e));

    final now = DateTime.now();
    final target = DateTime(now.year, now.month - (params.month - 1), 1);

    final filteredList = result.list.where((item) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        item.lotteryTime * 1000,
      ).toLocal();
      return dt.month == target.month;
    }).toList();

    result.list
      ..clear()
      ..addAll(filteredList);

    int randomMs([int max = 3000]) => Random().nextInt(max);
    await Future.delayed(Duration(milliseconds: randomMs()));
    return result;
  }

  /// 优惠券门槛列表 coupon threshold list
  /// returns list of CouponThresholdData
  /// desc: description

  static Future<CouponThresholdResponse> thresholdListApi() async {
    final res = await Http.get('/userCouponThresholdList.json');
    final response = CouponThresholdResponse.fromJson(res);
    return response;
  }

  /// 订单各状态数量 order count by status
  static Future<OrderCount> orderCountApi() async {
    final res = await Http.get('/userOrderStateCount.json');
    return OrderCount.fromJson(res);
  }

  static Future<PageResult<OrderItem>> orderListApi(
    OrderListParams params,
  ) async {
    final res = await Http.get(
      '/userOrderList.json',
      queryParameters: {
        "order_state": params.orderState,
        "page": params.page,
        "size": params.size,
      },
    );
    final result = parsePageResponse(res, (e) => OrderItem.fromJson(e));
    return result;
  }
}
