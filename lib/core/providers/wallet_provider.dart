import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/lucky_api.dart';

final walletBalanceProvider = FutureProvider((ref) async {
  return await Api.getWalletBalanceApi();
});

