import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/home_components/home_ad.dart';
import 'package:flutter_app/app/page/home_components/home_statistics.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/home_banner.dart';
import 'package:flutter_app/components/skeleton.dart';

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

  ///  banner, treasure, ad, statistics fetch functions
  Future<List<Banners>> _fetchBanners()=> Api.bannersApi(1);
  Future<List<IndexTreasureItem>> _fetchTreasures()=> Api.indexTreasuresApi();
  Future<List<AdRes>> _fetchAds()=> Api.indexAdApi(1);
  Future<IndexStatistics> _fetchStatistics()=> Api.indexStatisticsApi();


  /// 下拉刷新 refresh handler
  Future<void> _onRefresh() async {
    setState(() {});
     Future.wait([
      _fetchAds(),
      _fetchBanners(),
      _fetchStatistics(),
      _fetchTreasures(),
    ]);
     await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
        showBack: false,
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 轮播图 Banner
              SliverToBoxAdapter(
                child: FutureBuilder<List<Banners>>(
                  future: _fetchBanners(),
                  builder: (context,snapshot){
                    if(snapshot.connectionState != ConnectionState.done){
                      return Padding(
                          padding: EdgeInsets.all(16),
                          child: Skeleton.react(
                              width: double.infinity,
                              height: 356,
                          ),
                      );
                    }

                    if(snapshot.hasError) {
                      return Center(child: Text('loading fail: ${snapshot.error}'));
                    }
                    return HomeBanner(banners: snapshot.data!);
                  },
                ),
              )
            ]
          ),
        )
    );
  }
}
