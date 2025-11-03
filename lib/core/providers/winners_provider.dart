import 'package:flutter_app/core/api/lucky_api.dart';
import 'package:flutter_app/core/models/page_request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/act_month_tab.dart';
import '../models/act_winners_month.dart';


/// Winners banner provider
final winnersBannerProvider = FutureProvider((ref) async {
  return Api.bannersApi(bannerCate: 2);
});

/// Winners quantity provider
final winnersQuantityProvider = FutureProvider((ref) async {
  return Api.winnersQuantityApi();
});

/// Winners lasts provider
final winnersLastsProvider = FutureProvider((ref) async {
  return await Api.winnersLastsApi();
});

/// Activity month number provider
final actMonthNumProvider = FutureProvider.autoDispose((ref) async {
  return  Api.actMonthNumApi();
});

/// Active month state provider
final activeMonthProvider = StateProvider<ActMonthTab?>((ref){
  return null;
});


/// Winners request provider with pagination
final actWinnersMonthsProvider =
Provider.family<PageRequest<ActWinnersMonth>, int>((ref, month) {
  return ({required int pageSize, required int page}) {
    return Api.winnersMonthApi(
      ActWinnersMonthParams(
        month: month,
        page: page,
        size: pageSize,
      ),
    );
  };
});