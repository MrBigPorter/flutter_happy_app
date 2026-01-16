import 'package:json_annotation/json_annotation.dart';

part 'conversation.g.dart';

enum ConversationType {
  @JsonValue('DIRECT') direct,
  @JsonValue('GROUP') group,
  @JsonValue('BUSINESS') business,
  @JsonValue('SUPPORT') SUPPORT,
}

@JsonSerializable(checked: true)
class Conversation {
  final String id;
  final ConversationType type;
  final String name;
  final String? avatar;
  final String? lastMsgContent;
  final int lastMsgTime;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;

  Conversation({
    required this.id,
    required this.type,
    required this.name,
    this.avatar,
    this.lastMsgContent,
    required this.lastMsgTime,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
  });

  static ConversationType _parseType(String? typeStr) {
    switch (typeStr) {
      case 'DIRECT': return ConversationType.direct;
      case 'GROUP': return ConversationType.group;
      case 'BUSINESS': return ConversationType.business;
      default: return ConversationType.group;
    }
  }

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

@JsonSerializable(checked: true)
class ChatSender {
  final String id;
  final String nickname;
  final String? avatar;

  ChatSender({required this.id, required this.nickname, this.avatar});

  factory ChatSender.fromJson(Map<String, dynamic> json) => _$ChatSenderFromJson(json);

  Map<String, dynamic> toJson() => _$ChatSenderToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

@JsonSerializable(checked: true)
class ChatMessage {
  final String id;
  final int type; // 0:Text, 1:Image, etc.
  final String content;
  final int createdAt; // 时间戳
  final ChatSender? sender;

  ChatMessage({
    required this.id,
    required this.type,
    required this.content,
    required this.createdAt,
    this.sender,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}


@JsonSerializable(checked: true)
class ConversationDetail {
  final String id;
  final String name;
  final ConversationType type;
  @JsonKey(name: 'history', defaultValue: [])
  final List<ChatMessage> history;

  ConversationDetail({
    required this.id,
    required this.name,
    required this.type,
    required this.history,
  });


  factory ConversationDetail.fromJson(Map<String, dynamic> json) =>
      _$ConversationDetailFromJson(json);

  static ConversationType _parseType(String? typeStr) {
    switch (typeStr) {
      case 'DIRECT': return ConversationType.direct;
      case 'GROUP': return ConversationType.group;
      case 'BUSINESS': return ConversationType.business;
      default: return ConversationType.group;
    }
  }
}

@JsonSerializable(checked: true)
class ConversationIdResponse {
  final String conversationId;

  ConversationIdResponse({required this.conversationId});

  factory ConversationIdResponse.fromJson(Map<String, dynamic> json) =>
      _$ConversationIdResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationIdResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
