
import 'package:flutter_app/core/services/fcm/handlers/base_handler.dart';

import '../../../../app/routes/app_router.dart';
import '../fcm_payload.dart';

class GroupActionHandler implements FcmActionHandler{
  @override
  void handle(FcmPayload payload) {
    // 这里的逻辑就是从你原始代码中抽离出来的
    appRouter.pushNamed(
      'groupRoom',
      queryParameters: {'groupId': payload.id},
    );
  }
}