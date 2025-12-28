import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/common.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../utils/camera/services/liveness_service.dart';

part 'liveness_provider.g.dart';

@riverpod
class LivenessNotifier extends _$LivenessNotifier {
  @override
  FutureOr<String?> build() {
    return null; // 初始：没有 sessionId
  }

  /// 开始活体检测，并返回 sessionId（成功才返回）
  Future<String?> startDetection(BuildContext context) async {
    // 先置为 loading
    state = const AsyncLoading<String?>();

    String? sessionId;

    state = await AsyncValue.guard<String?>(() async {
      // 1) 拿后端 sessionId
      final result = await Api.kycSessionApi();

      final id = result.sessionId;
      if (id.isEmpty) {
        throw Exception('Failed to create liveness session');
      }
      sessionId = id;

      // 2) 拉起原生 AWS 活体
      final bool? ok = await LivenessService.start(context, id);
      if (ok != true) {
        throw Exception('Liveness detection failed or was cancelled');
      }

      // 3) 成功：把 sessionId 作为 AsyncData 的 value
      return id;
    });

    return sessionId;
  }

  void reset() {
    state = const AsyncData<String?>(null);
  }
}