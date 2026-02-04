
import 'package:flutter_app/app/routes/app_router.dart';
import '../fcm_payload.dart';
import 'base_handler.dart';

class ChatActionHandler implements FcmActionHandler{
  @override
  void handle(FcmPayload payload) {
    // 这里的逻辑就是从你原始代码中抽离出来的
    appRouter.push( '/chat/room/${payload.id}?title=${Uri.encodeComponent(payload.title)}');

  }
}