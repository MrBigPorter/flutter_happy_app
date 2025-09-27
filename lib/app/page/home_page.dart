import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/home_components/home_ad.dart';
import 'package:flutter_app/app/page/home_components/home_statistics.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/home_banner.dart';

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

  /// 首页数据 future home page data future
  late Future<_HomeData> _homeDataFuture;

  /// 初始化时加载首页数据 load home page data on init
  @override
  void initState() {
    super.initState();
    _homeDataFuture = _loadAll();
  }

  /// 并行加载所有首页数据 load all home page data in parallel
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

  /// 下拉刷新 refresh handler
  Future<void> _onRefresh() async {
    setState(()=> _homeDataFuture = _loadAll());
    await _homeDataFuture;
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
        showBack: false,
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: FutureBuilder<_HomeData>(
              future: _homeDataFuture,
              builder: (context, snap){
                if(snap.connectionState != ConnectionState.done){
                  return Text("loading");
                }
                if(snap.hasError){
                  return Text("Error: ${snap.error}");
                }

                final data = snap.data!;

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: HomeBanner(banners:data.banners)),
                    SliverToBoxAdapter(child: HomeStatistics()),
                    SliverToBoxAdapter(child: HomeAd()),
                  ]
                );

              }
          ),
        )
    );
  }
}
