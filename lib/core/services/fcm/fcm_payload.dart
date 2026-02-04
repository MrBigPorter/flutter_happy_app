enum FcmType {
  groupDetail, // 对应原 group_detail
  chat,        // 对应原 chat
  system,      // 对应原 system
  unknown      // 兜底类型
}

class FcmPayload {
  final FcmType type;
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> rawData; // 保留原始数据以备不时之需

  /// 架构逻辑：判断该消息是否具备触发业务跳转的条件
  /// 只有类型不是 unknown 且 携带了具体的业务 ID 时，才视为有效动作
  bool get hasValidAction => type != FcmType.unknown && id.isNotEmpty;

  FcmPayload({
    required this.type,
    required this.id,
    required this.title,
    required this.body,
    required this.rawData,
  });

  // 核心架构点：工厂方法负责所有“脏活”，包括字段解析和空安全
  factory FcmPayload.fromMap(Map<String, dynamic> data, {String? notificationTitle, String? notificationBody}) {
    return FcmPayload(
      type: _parseType(data['type']),
      id: data['id']?.toString() ?? '', // 确保 ID 永远是字符串且不为空
      title: notificationTitle ?? data['title'] ?? '',
      body: notificationBody ?? data['body'] ?? '',
      rawData: data,
    );
  }


  static FcmType _parseType(String? typeStr) {
    switch (typeStr) {
      case 'group_detail': return FcmType.groupDetail;
      case 'chat': return FcmType.chat;
      case 'system': return FcmType.system;
      default: return FcmType.unknown;
    }
  }
}