import 'dart:async';
import 'package:flutter_app/common.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../utils/services/liveness_service.dart';

part 'liveness_provider.g.dart';

@riverpod
class LivenessNotifier extends _$LivenessNotifier {
   @override
   FutureOr<void> build() {} // 初始状态为空

    Future<void> startDetection() async {
      // 设置状态为loading
      state = const AsyncLoading();

      // 1. 使用 AsyncValue.guard 包裹异步操作，自动处理异常，返回 AsyncError AsyncData
      state = await AsyncValue.guard(() async {
        // 2. 调用 Service 获取 ID
        final result = await Api.kycSessionApi();
        // 3. 调用原生插件拉起 AWS 圆圈
        final bool? isSuccess = await LivenessService.start(result.sessionId);
        if (isSuccess != true) {
          throw Exception("Liveness detection failed or was cancelled");
        }

        print("Liveness detection succeeded:${result.sessionId}");

        //调用验证接口
        // 后端会拿着 sessionId 去问 AWS："刚才这个人多少分？"
       // await Api.kycSubmitApi();
      });
    }
}