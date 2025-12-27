import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/lucky_api.dart';
import '../models/kyc.dart';

part 'kyc_provider.g.dart';

// ==========================================
// 1. 数据类 Provider (GET 请求 - 自动加载)
// ==========================================
/// 获取 ID 类型列表 (进入页面自动加载)
final kycIdTypeProvider = FutureProvider((ref) async {
  return Api.kycIdTypesApi();
});

/// 获取我的 KYC 状态
final kycMeProvider = FutureProvider((ref) async {
  return Api.kycMeApi();
});

// ==========================================
// 2. 动作类 Controller (POST 请求 - 手动触发)
// ==========================================

/// KYC 操作控制器
/// 负责：OCR 识别、提交 KYC 等动作
///
@riverpod
class KycNotifier extends _$KycNotifier {
  @override
  Future<KycOcrResult?> build() {
    // 初始状态为空
    return Future.value(null);
  }

  /// 执行 OCR 识别
  /// [key] 是图片上传到 R2 后返回的 key
  ///
  Future<KycOcrResult?> scanIdCard(String key) async {
    // 1. 设置 loading 状态 (UI 转圈)
    state = const AsyncLoading();

    // 2. 调用 API 执行 OCR 识别
    final newState = await AsyncValue.guard(() async {
      return await Api.kycOcrApi(key);
    });

    // 3. 更新状态
    state = newState;
    return newState.value;
  }
}
