class SetMuteRequest {
  final String conversationId;
  final bool isMuted;

  SetMuteRequest({required this.conversationId, required this.isMuted});

  Map<String, dynamic> toJson() => {
    'conversationId': conversationId,
    'isMuted': isMuted,
  };
}

class SetPinRequest {
  final String conversationId;
  final bool isPinned;

  SetPinRequest({required this.conversationId, required this.isPinned});

  Map<String, dynamic> toJson() => {
    'conversationId': conversationId,
    'isPinned': isPinned,
  };
}

class ClearHistoryRequest {
  final String conversationId;

  ClearHistoryRequest({required this.conversationId});

  Map<String, dynamic> toJson() => {
    'conversationId': conversationId,
  };
}

class ChatSettingsResponse {
  final bool success;
  final bool? isMuted;
  final bool? isPinned;

  ChatSettingsResponse({required this.success, this.isMuted, this.isPinned});

  factory ChatSettingsResponse.fromJson(Map<String, dynamic> json) {
    return ChatSettingsResponse(
      success: json['success'] ?? false,
      isMuted: json['isMuted'],
      isPinned: json['isPinned'],
    );
  }
}