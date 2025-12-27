import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/form/fields/lf_select.dart';

final provinceProvider = FutureProvider.autoDispose<List<LfSelectOption<int>>>((
  ref,
) async {
  final res = await Api.provincesApi();
  return res
      .map((e) => (text: e.provinceName, value: e.provinceId, disabled: false))
      .toList();
});

final cityProvider = FutureProvider.autoDispose
    .family<List<LfSelectOption<int>>, int>((ref, int provinceId) async {
      final res = await Api.cityApi(provinceId);
      return res
          .map((e) => (text: e.cityName, value: e.cityId, disabled: false))
          .toList();
    });

final barangaysProvider = FutureProvider.autoDispose.family<List<LfSelectOption<int>>,int>((ref,cityId)async{
  final res = await Api.barangayApi(cityId);
  return res
      .map((e) => (text: e.barangayName, value: e.barangayId, disabled: false))
      .toList();
});