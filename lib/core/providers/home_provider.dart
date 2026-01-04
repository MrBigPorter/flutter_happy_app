import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Home page banner provider
final homeBannerProvider = FutureProvider((ref) async{
  return Api.bannersApi(bannerCate: 1);
});

/// Home page treasures provider
final homeTreasuresProvider = FutureProvider((ref) async{
  final data = await Api.indexTreasuresApi();
  return data;
});

/// Home page ad provider
final homeAdProvider = FutureProvider((ref) async{
  return Api.indexAdApi(
    adPosition: 1,
  );
});

/// Home page statistics provider
final homeStatisticsProvider = FutureProvider((ref) async{
  return Api.indexStatisticsApi();
});