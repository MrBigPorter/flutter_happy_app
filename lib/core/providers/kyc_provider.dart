
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/lucky_api.dart';

// ==========================================
// 1. 数据类 Provider (GET 请求 - 自动加载)
// ==========================================
/// 获取 ID 类型列表 (进入页面自动加载)
final kycIdTypeProvider = FutureProvider.autoDispose((ref) async {
  //  Keep alive the provider while in use
  // final link = ref.keepAlive();

  // 2. 只有当没有任何页面监听这个 provider 时，计时器才开始
  // ref.onDispose(() {
  //   Timer(const Duration(minutes: 30), () {
  //     link.close();
  //   });
  // });

  // 发起请求
  return Api.kycIdTypesApi();
});

/// 获取我的 KYC 状态
final kycMeProvider = FutureProvider((ref) async {
  return Api.kycMeApi();
});
