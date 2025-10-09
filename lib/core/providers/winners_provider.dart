import 'package:flutter_app/core/api/lucky_api.dart';
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