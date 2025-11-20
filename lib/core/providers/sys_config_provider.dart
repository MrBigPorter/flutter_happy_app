import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/lucky_api.dart';

final sysConfigProvider =FutureProvider((ref) async {
  return await Api.getSysConfig();
});