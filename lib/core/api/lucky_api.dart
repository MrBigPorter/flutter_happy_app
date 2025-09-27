import 'dart:convert';
import 'package:flutter_app/common.dart';

import '../../utils/helper.dart';


class Api {

  static Future<List<Banners>> bannersApi(int type) async {
    final res = await HttpClient.get("/bannersList.json?type=$type");
    return parseList<Banners>(res, (e) => Banners.fromJson(e));
  }

  static Future<List<IndexTreasureItem>> indexTreasuresApi() async {
    final res = await HttpClient.get("/treasuresList.json");

   return parseList<IndexTreasureItem>(res, (e) => IndexTreasureItem.fromJson(e));

  }

  static Future<List<AdRes>> indexAdApi(int type) async {
    final res = await HttpClient.get("/advertiseList.json?type=$type");
     return parseList(res, (e) => AdRes.fromJson(e));
  }

  static Future<IndexStatistics> indexStatisticsApi() async {
    final res = await HttpClient.get("/homepageStatisticalData.json");
      return IndexStatistics.fromJson(res);
  }


  static Future<UserInfo> getUserInfo() async {
    final res = await HttpClient.get("user/info");
      return UserInfo.fromJson(jsonDecode(res));
  }

  static Future<Balance> getWalletBalance() async {
    final res = await HttpClient.get('/balance.json');
    return Balance.fromJson(jsonDecode(res));
  }

  static Future<SysConfig> getSysConfig() async {
    final res = await HttpClient.get('/sysConfigGet.json');
    return SysConfig.fromJson(jsonDecode(res));
  }
}