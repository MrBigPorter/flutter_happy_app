// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Conversation _$ConversationFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Conversation', json, ($checkedConvert) {
      final val = Conversation(
        id: $checkedConvert('id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$ConversationTypeEnumMap, v),
        ),
        name: $checkedConvert('name', (v) => v as String),
        avatar: $checkedConvert('avatar', (v) => v as String?),
        lastMsgContent: $checkedConvert('lastMsgContent', (v) => v as String?),
        lastMsgTime: $checkedConvert('lastMsgTime', (v) => (v as num).toInt()),
        unreadCount: $checkedConvert(
          'unreadCount',
          (v) => (v as num?)?.toInt() ?? 0,
        ),
        isPinned: $checkedConvert('isPinned', (v) => v as bool? ?? false),
        isMuted: $checkedConvert('isMuted', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$ConversationToJson(Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$ConversationTypeEnumMap[instance.type]!,
      'name': instance.name,
      'avatar': instance.avatar,
      'lastMsgContent': instance.lastMsgContent,
      'lastMsgTime': instance.lastMsgTime,
      'unreadCount': instance.unreadCount,
      'isPinned': instance.isPinned,
      'isMuted': instance.isMuted,
    };

const _$ConversationTypeEnumMap = {
  ConversationType.direct: 'DIRECT',
  ConversationType.group: 'GROUP',
  ConversationType.business: 'BUSINESS',
  ConversationType.SUPPORT: 'SUPPORT',
};

ChatSender _$ChatSenderFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ChatSender', json, ($checkedConvert) {
      final val = ChatSender(
        id: $checkedConvert('id', (v) => v as String),
        nickname: $checkedConvert('nickname', (v) => v as String),
        avatar: $checkedConvert('avatar', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ChatSenderToJson(ChatSender instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nickname': instance.nickname,
      'avatar': instance.avatar,
    };

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ChatMessage', json, ($checkedConvert) {
      final val = ChatMessage(
        id: $checkedConvert('id', (v) => v as String),
        type: $checkedConvert('type', (v) => (v as num).toInt()),
        content: $checkedConvert('content', (v) => v as String),
        createdAt: $checkedConvert('createdAt', (v) => (v as num).toInt()),
        sender: $checkedConvert(
          'sender',
          (v) =>
              v == null ? null : ChatSender.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'content': instance.content,
      'createdAt': instance.createdAt,
      'sender': instance.sender,
    };

ConversationDetail _$ConversationDetailFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ConversationDetail', json, ($checkedConvert) {
      final val = ConversationDetail(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$ConversationTypeEnumMap, v),
        ),
        history: $checkedConvert(
          'history',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
        ),
      );
      return val;
    });

Map<String, dynamic> _$ConversationDetailToJson(ConversationDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$ConversationTypeEnumMap[instance.type]!,
      'history': instance.history,
    };

ConversationIdResponse _$ConversationIdResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ConversationIdResponse', json, ($checkedConvert) {
  final val = ConversationIdResponse(
    conversationId: $checkedConvert('conversationId', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$ConversationIdResponseToJson(
  ConversationIdResponse instance,
) => <String, dynamic>{'conversationId': instance.conversationId};
