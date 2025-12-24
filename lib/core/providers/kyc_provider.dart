

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/lucky_api.dart';

final kycIdTypeProvider = FutureProvider((ref) async {
  return Api.kycIdTypesApi();
});

final kycMeProvider = FutureProvider((ref) async {
  return Api.kycMeApi();
});

