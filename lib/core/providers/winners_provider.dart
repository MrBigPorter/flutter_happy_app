import 'package:flutter_app/components/list.dart';
import 'package:flutter_app/core/api/lucky_api.dart';
import 'package:flutter_app/core/models/index.dart' hide PageRequest;
import 'package:flutter_riverpod/flutter_riverpod.dart';


/// Winners banner provider
final winnersBannerProvider = FutureProvider((ref) async {
  return Api.bannersApi(2);
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
final actMonthNumProvider = FutureProvider((ref) async {
  return  Api.actMonthNumApi();
});

/// Active month state provider
final activeMonthProvider = StateProvider<ActMonthTab>((ref){
  return ActMonthTab(title: '', monthTitle: '', value: 0);
});


/// Winners request provider with pagination
final actWinnersMonthsProvider = Provider.family<PageRequest<ActWinnersMonth>,int>((ref,month){
  return ({required int pageSize, required int current})  {
    return Api.winnersMonthApi(
      ActWinnersMonthParams(month: month, current: current, size: pageSize)
    );
  };
});