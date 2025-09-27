import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';

class _HomeData {
  final List<Banners> banners;
  final List<IndexTreasureItem> treasureList;
  final List<AdRes> adList;
  final IndexStatistics statistics;

  const _HomeData({
    required this.banners,
    required this.treasureList,
    required this.adList,
    required this.statistics,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// 首页 Home Page
/// 包含轮播图、宝贝列表、广告位、数据统计等模块 including carousel, treasure list, ad space, data statistics, etc.
class _HomePageState extends State<HomePage> {

  late Future<_HomeData> _homeDataFuture;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _loadAll();
  }

  Future<_HomeData> _loadAll() async {

      final results = await Future.wait([
        Api.bannersApi(1),
        Api.indexTreasuresApi(),
        Api.indexAdApi(1),
        Api.indexStatisticsApi(),
      ]);

      final data = _HomeData(
          banners: results[0] as List<Banners>,
          treasureList: results[1] as List<IndexTreasureItem>,
          adList: results[2] as List<AdRes>,
          statistics: results[3] as IndexStatistics
      );
      return data;

  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(title: '首页', showBack: false, body: Text('home'));
  }
}
