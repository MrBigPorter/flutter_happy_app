enum GlobalEventType {
  deviceBanned,  // 设备封禁
  userBlacklisted, // 用户黑名单
  forceUpdate,   // 强制更新
  maintenance,   // 系统维护
}

class GlobalEvent{
  final GlobalEventType type;
  final String? message;
  final Map<String, dynamic>? data;

  GlobalEvent(this.type, {this.message, this.data});
}