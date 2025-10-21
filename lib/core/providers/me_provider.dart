import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Coupon threshold list provider
final thresholdListProvider = FutureProvider((ref) async {
  return Api.thresholdListApi();
});