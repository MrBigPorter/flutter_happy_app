import 'dart:convert';
import 'dart:math';
import 'package:flutter_app/common.dart';

import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_app/core/models/index.dart';


class Api {

  /// 首页轮播图 type 1: banner 2: 广告 home banner
  static Future<List<Banners>> bannersApi(int type) async {
    final res = await HttpClient.get("/bannersList.json?type=$type");
    return parseList<Banners>(res, (e) => Banners.fromJson(e));
  }

  /// 首页宝藏推荐  home treasures
  static Future<List<IndexTreasureItem>> indexTreasuresApi() async {
    final res = await HttpClient.get("/treasuresList.json");

   return parseList<IndexTreasureItem>(res, (e) => IndexTreasureItem.fromJson(e));

  }

  /// 首页广告 type 1: banner 2: 广告 home ad
  static Future<List<AdRes>> indexAdApi(int type) async {
    final res = await HttpClient.get("/advertiseList.json?type=$type");
     return parseList<AdRes>(res, (e) => AdRes.fromJson(e));
  }

  /// 首页统计数据 home statistics
  static Future<IndexStatistics> indexStatisticsApi() async {
    final res = await HttpClient.get("/homepageStatisticalData.json");
      return IndexStatistics.fromJson(res);
  }


  /// 用户信息 user info
  static Future<UserInfo> getUserInfo() async {
    final res = await HttpClient.get("user/info");
      return UserInfo.fromJson(jsonDecode(res));
  }

  /// 钱包余额 wallet balance
  static Future<Balance> getWalletBalance() async {
    final res = await HttpClient.get('/balance.json');
    return Balance.fromJson(jsonDecode(res));
  }

  /// 系统配置 sys config
  static Future<SysConfig> getSysConfig() async {
    final res = await HttpClient.get('/sysConfigGet.json');
    return SysConfig.fromJson(jsonDecode(res));
  }

  /// 商品分类 product category tabs
  static Future<List<ProductCategoryItem>> getProductCategoryList() async {
    final res = await HttpClient.get('/productCategoryList.json');
    return parseList<ProductCategoryItem>(res, (e)=> ProductCategoryItem.fromJson(e));
  }

  /// 商品列表 product list
  /// products_category_id 0: all
  /// products_category_id 1: hot
  /// products_category_id 2: tech
  static Future<List<ProductListItem>> getProductList(int productsCategoryId) async {
      final res = await HttpClient.get('/productList.json',queryParameters: {
      "products_category_id": productsCategoryId
    });
    return parseList<ProductListItem>(res, (e)=> ProductListItem.fromJson(e));
  }

  /// 中奖总人数 total winners quantity
  static Future<WinnersQuantity> winnersQuantityApi() async {
    final res = await HttpClient.get('/actWinnersQuantity.json');
    return WinnersQuantity.fromJson(res);
  }

  /// 最新中奖名单 latest winners list
  static Future<List<WinnersLastsItem>> winnersLastsApi() async {
    final res = await HttpClient.get('/actWinnersLasts.json');
    return parseList<WinnersLastsItem>(res, (e) => WinnersLastsItem.fromJson(e));
  }

  /// 月度活动数据 monthly activity data
  static Future<List<int>> actMonthNumApi() async {
    final res = await HttpClient.get('/actMonthNum.json');
    return (res as List).map((e) => e as int).toList();
  }

  /// 月度中奖名单 monthly winners list
  /// returns paginated result

  static Future<PageResult<ActWinnersMonth>> winnersMonthApi(ActWinnersMonthParams params) async {
    final res = await HttpClient.get('/actWinnersMonth.json',queryParameters: {
      "month": params.month,
      "current": params.current,
      "size": params.size,
    });

    
    final result = parsePageResponse(res, (e) => ActWinnersMonth.fromJson(e) );

    final now = DateTime.now();
    final target = DateTime(now.year,now.month - (params.month - 1), 1);

    final filteredList = result.list.where((item){
      final dt = DateTime.fromMillisecondsSinceEpoch(item.lotteryTime*1000).toLocal();
      return  dt.month == target.month;
    }).toList();
    
    result.list
      ..clear()
      ..addAll(filteredList);

    int randomMs([int max = 3000]) => Random().nextInt(max);
    await Future.delayed( Duration(milliseconds: randomMs()));
    return result;
  }


}