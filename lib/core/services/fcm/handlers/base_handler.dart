
import '../fcm_payload.dart';

abstract class FcmActionHandler{
  // 每个处理器只需实现这个方法
  void handle(FcmPayload payload);
}