// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_ui_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatUiModel _$ChatUiModelFromJson(Map<String, dynamic> json) => ChatUiModel(
  id: json['id'] as String,
  content: json['content'] as String,
  type: $enumDecode(_$MessageTypeEnumMap, json['type']),
  isMe: json['isMe'] as bool,
  status:
      $enumDecodeNullable(_$MessageStatusEnumMap, json['status']) ??
      MessageStatus.success,
  createdAt: (json['createdAt'] as num).toInt(),
  conversationId: json['conversationId'] as String,
  isRecalled: json['isRecalled'] as bool? ?? false,
  senderAvatar: json['senderAvatar'] as String?,
  senderName: json['senderName'] as String?,
  seqId: (json['seqId'] as num?)?.toInt(),
  localPath: json['localPath'] as String?,
  width: (json['width'] as num?)?.toDouble(),
  height: (json['height'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ChatUiModelToJson(ChatUiModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'seqId': instance.seqId,
      'content': instance.content,
      'type': _$MessageTypeEnumMap[instance.type]!,
      'isMe': instance.isMe,
      'status': _$MessageStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt,
      'senderAvatar': instance.senderAvatar,
      'senderName': instance.senderName,
      'conversationId': instance.conversationId,
      'localPath': instance.localPath,
      'width': instance.width,
      'height': instance.height,
      'isRecalled': instance.isRecalled,
    };

const _$MessageTypeEnumMap = {
  MessageType.text: 1,
  MessageType.image: 2,
  MessageType.audio: 3,
  MessageType.video: 4,
  MessageType.system: 99,
};

const _$MessageStatusEnumMap = {
  MessageStatus.sending: 'sending',
  MessageStatus.success: 'success',
  MessageStatus.failed: 'failed',
  MessageStatus.read: 'read',
};
