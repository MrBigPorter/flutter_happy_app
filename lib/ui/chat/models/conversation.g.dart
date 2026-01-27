// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Conversation _$ConversationFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'Conversation',
      json,
      ($checkedConvert) {
        final val = Conversation(
          id: $checkedConvert('id', (v) => v as String),
          type: $checkedConvert(
              'type', (v) => $enumDecode(_$ConversationTypeEnumMap, v)),
          name: $checkedConvert('name', (v) => v as String),
          avatar: $checkedConvert('avatar', (v) => v as String?),
          lastMsgContent:
              $checkedConvert('lastMsgContent', (v) => v as String?),
          lastMsgTime:
              $checkedConvert('lastMsgTime', (v) => (v as num).toInt()),
          unreadCount:
              $checkedConvert('unreadCount', (v) => (v as num?)?.toInt() ?? 0),
          isPinned: $checkedConvert('isPinned', (v) => v as bool? ?? false),
          isMuted: $checkedConvert('isMuted', (v) => v as bool? ?? false),
          lastMsgStatus: $checkedConvert(
              'lastMsgStatus',
              (v) =>
                  $enumDecodeNullable(_$MessageStatusEnumMap, v,
                      unknownValue: MessageStatus.success) ??
                  MessageStatus.success),
        );
        return val;
      },
    );

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
      'lastMsgStatus': _$MessageStatusEnumMap[instance.lastMsgStatus]!,
    };

const _$ConversationTypeEnumMap = {
  ConversationType.direct: 'DIRECT',
  ConversationType.group: 'GROUP',
  ConversationType.business: 'BUSINESS',
  ConversationType.support: 'SUPPORT',
};

const _$MessageStatusEnumMap = {
  MessageStatus.sending: 'sending',
  MessageStatus.success: 'success',
  MessageStatus.failed: 'failed',
  MessageStatus.read: 'read',
  MessageStatus.pending: 'pending',
};

ChatSender _$ChatSenderFromJson(Map<String, dynamic> json) => $checkedCreate(
      'ChatSender',
      json,
      ($checkedConvert) {
        final val = ChatSender(
          id: $checkedConvert('id', (v) => v as String),
          nickname: $checkedConvert('nickname', (v) => v as String),
          avatar: $checkedConvert('avatar', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$ChatSenderToJson(ChatSender instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nickname': instance.nickname,
      'avatar': instance.avatar,
    };

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => $checkedCreate(
      'ChatMessage',
      json,
      ($checkedConvert) {
        final val = ChatMessage(
          id: $checkedConvert('id', (v) => v as String),
          type: $checkedConvert('type', (v) => (v as num).toInt()),
          content: $checkedConvert('content', (v) => v as String),
          createdAt: $checkedConvert('createdAt', (v) => (v as num).toInt()),
          isRecalled: $checkedConvert('isRecalled', (v) => v as bool? ?? false),
          sender: $checkedConvert(
              'sender',
              (v) => v == null
                  ? null
                  : ChatSender.fromJson(v as Map<String, dynamic>)),
          isSelf: $checkedConvert('isSelf', (v) => v as bool? ?? false),
          seqId: $checkedConvert('seqId', (v) => (v as num?)?.toInt()),
          meta: $checkedConvert('meta', (v) => v as Map<String, dynamic>?),
        );
        return val;
      },
    );

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'content': instance.content,
      'createdAt': instance.createdAt,
      'sender': instance.sender,
      'seqId': instance.seqId,
      'isRecalled': instance.isRecalled,
      'meta': instance.meta,
      'isSelf': instance.isSelf,
    };

ChatMember _$ChatMemberFromJson(Map<String, dynamic> json) => $checkedCreate(
      'ChatMember',
      json,
      ($checkedConvert) {
        final val = ChatMember(
          userId: $checkedConvert('userId', (v) => v as String),
          nickname: $checkedConvert('nickname', (v) => v as String),
          avatar: $checkedConvert('avatar', (v) => v as String?),
          role: $checkedConvert('role', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$ChatMemberToJson(ChatMember instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'nickname': instance.nickname,
      'avatar': instance.avatar,
      'role': instance.role,
    };

ConversationIdResponse _$ConversationIdResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'ConversationIdResponse',
      json,
      ($checkedConvert) {
        final val = ConversationIdResponse(
          conversationId: $checkedConvert('conversationId', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$ConversationIdResponseToJson(
        ConversationIdResponse instance) =>
    <String, dynamic>{
      'conversationId': instance.conversationId,
    };

Map<String, dynamic> _$MessageHistoryRequestToJson(
        MessageHistoryRequest instance) =>
    <String, dynamic>{
      'conversationId': instance.conversationId,
      'cursor': instance.cursor,
      'pageSize': instance.pageSize,
    };

MessageListResponse _$MessageListResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'MessageListResponse',
      json,
      ($checkedConvert) {
        final val = MessageListResponse(
          list: $checkedConvert(
              'list',
              (v) =>
                  (v as List<dynamic>?)
                      ?.map((e) =>
                          ChatMessage.fromJson(e as Map<String, dynamic>))
                      .toList() ??
                  []),
          partnerLastReadSeqId: $checkedConvert(
              'partnerLastReadSeqId', (v) => (v as num).toInt()),
          nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$MessageListResponseToJson(
        MessageListResponse instance) =>
    <String, dynamic>{
      'list': instance.list,
      'nextCursor': instance.nextCursor,
      'partnerLastReadSeqId': instance.partnerLastReadSeqId,
    };

SocketMessage _$SocketMessageFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SocketMessage',
      json,
      ($checkedConvert) {
        final val = SocketMessage(
          id: $checkedConvert('id', (v) => v as String),
          conversationId: $checkedConvert('conversationId', (v) => v as String),
          senderId: $checkedConvert('senderId', (v) => v as String),
          content: $checkedConvert('content', (v) => v as String),
          type: $checkedConvert('type', (v) => (v as num).toInt()),
          createdAt: $checkedConvert('createdAt', (v) => (v as num).toInt()),
          sender: $checkedConvert(
              'sender',
              (v) => v == null
                  ? null
                  : SocketSender.fromJson(v as Map<String, dynamic>)),
          tempId: $checkedConvert('tempId', (v) => v as String?),
          isSelf: $checkedConvert('isSelf', (v) => v as bool?),
          seqId: $checkedConvert('seqId', (v) => (v as num?)?.toInt()),
          meta: $checkedConvert('meta', (v) => v as Map<String, dynamic>?),
        );
        return val;
      },
    );

Map<String, dynamic> _$SocketMessageToJson(SocketMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversationId': instance.conversationId,
      'senderId': instance.senderId,
      'content': instance.content,
      'type': instance.type,
      'createdAt': instance.createdAt,
      'sender': instance.sender,
      'tempId': instance.tempId,
      'isSelf': instance.isSelf,
      'seqId': instance.seqId,
      'meta': instance.meta,
    };

SocketSender _$SocketSenderFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SocketSender',
      json,
      ($checkedConvert) {
        final val = SocketSender(
          id: $checkedConvert('id', (v) => v as String),
          nickname:
              $checkedConvert('nickname', (v) => v as String? ?? 'Unknown'),
          avatar: $checkedConvert('avatar', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$SocketSenderToJson(SocketSender instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nickname': instance.nickname,
      'avatar': instance.avatar,
    };

MessageMarkReadRequest _$MessageMarkReadRequestFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'MessageMarkReadRequest',
      json,
      ($checkedConvert) {
        final val = MessageMarkReadRequest(
          conversationId: $checkedConvert('conversationId', (v) => v as String),
          maxSeqId: $checkedConvert('maxSeqId', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$MessageMarkReadRequestToJson(
        MessageMarkReadRequest instance) =>
    <String, dynamic>{
      'conversationId': instance.conversationId,
      'maxSeqId': instance.maxSeqId,
    };

MessageMarkReadResponse _$MessageMarkReadResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'MessageMarkReadResponse',
      json,
      ($checkedConvert) {
        final val = MessageMarkReadResponse(
          unreadCount:
              $checkedConvert('unreadCount', (v) => (v as num?)?.toInt() ?? 0),
          lastReadSeqId:
              $checkedConvert('lastReadSeqId', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$MessageMarkReadResponseToJson(
        MessageMarkReadResponse instance) =>
    <String, dynamic>{
      'unreadCount': instance.unreadCount,
      'lastReadSeqId': instance.lastReadSeqId,
    };

SocketReadEvent _$SocketReadEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SocketReadEvent',
      json,
      ($checkedConvert) {
        final val = SocketReadEvent(
          conversationId: $checkedConvert('conversationId', (v) => v as String),
          readerId: $checkedConvert('readerId', (v) => v as String),
          lastReadSeqId: $checkedConvert(
              'lastReadSeqId', (v) => (v as num?)?.toInt() ?? 0),
          isSelf: $checkedConvert('isSelf', (v) => v as bool?),
        );
        return val;
      },
    );

Map<String, dynamic> _$SocketReadEventToJson(SocketReadEvent instance) =>
    <String, dynamic>{
      'conversationId': instance.conversationId,
      'readerId': instance.readerId,
      'isSelf': instance.isSelf,
      'lastReadSeqId': instance.lastReadSeqId,
    };

MessageRecallRequest _$MessageRecallRequestFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'MessageRecallRequest',
      json,
      ($checkedConvert) {
        final val = MessageRecallRequest(
          conversationId: $checkedConvert('conversationId', (v) => v as String),
          messageId: $checkedConvert('messageId', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$MessageRecallRequestToJson(
        MessageRecallRequest instance) =>
    <String, dynamic>{
      'conversationId': instance.conversationId,
      'messageId': instance.messageId,
    };

MessageRecallResponse _$MessageRecallResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'MessageRecallResponse',
      json,
      ($checkedConvert) {
        final val = MessageRecallResponse(
          messageId: $checkedConvert('messageId', (v) => v as String),
          tip: $checkedConvert('tip', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$MessageRecallResponseToJson(
        MessageRecallResponse instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'tip': instance.tip,
    };

SocketRecallEvent _$SocketRecallEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SocketRecallEvent',
      json,
      ($checkedConvert) {
        final val = SocketRecallEvent(
          conversationId: $checkedConvert('conversationId', (v) => v as String),
          messageId: $checkedConvert('messageId', (v) => v as String),
          tip: $checkedConvert('tip', (v) => v as String),
          isSelf: $checkedConvert('isSelf', (v) => v as bool),
          operatorId: $checkedConvert('operatorId', (v) => v as String),
          seqId: $checkedConvert('seqId', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$SocketRecallEventToJson(SocketRecallEvent instance) =>
    <String, dynamic>{
      'conversationId': instance.conversationId,
      'messageId': instance.messageId,
      'tip': instance.tip,
      'operatorId': instance.operatorId,
      'seqId': instance.seqId,
      'isSelf': instance.isSelf,
    };

MessageDeleteRequest _$MessageDeleteRequestFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'MessageDeleteRequest',
      json,
      ($checkedConvert) {
        final val = MessageDeleteRequest(
          messageId: $checkedConvert('messageId', (v) => v as String),
          conversationId: $checkedConvert('conversationId', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$MessageDeleteRequestToJson(
        MessageDeleteRequest instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'conversationId': instance.conversationId,
    };

MessageDeleteResponse _$MessageDeleteResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'MessageDeleteResponse',
      json,
      ($checkedConvert) {
        final val = MessageDeleteResponse(
          messageId: $checkedConvert('messageId', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$MessageDeleteResponseToJson(
        MessageDeleteResponse instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
    };

ChatUser _$ChatUserFromJson(Map<String, dynamic> json) => $checkedCreate(
      'ChatUser',
      json,
      ($checkedConvert) {
        final val = ChatUser(
          id: $checkedConvert('id', (v) => v as String),
          nickname: $checkedConvert('nickname', (v) => v as String),
          avatar: $checkedConvert('avatar', (v) => v as String?),
          phone: $checkedConvert('phone', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$ChatUserToJson(ChatUser instance) => <String, dynamic>{
      'id': instance.id,
      'nickname': instance.nickname,
      'avatar': instance.avatar,
      'phone': instance.phone,
    };

Map<String, dynamic> _$AddFriendRequestToJson(AddFriendRequest instance) =>
    <String, dynamic>{
      'friendId': instance.friendId,
    };

Map<String, dynamic> _$CreateGroupRequestToJson(CreateGroupRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'memberIds': instance.memberIds,
    };

CreateGroupResponse _$CreateGroupResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CreateGroupResponse',
      json,
      ($checkedConvert) {
        final val = CreateGroupResponse(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          type: $checkedConvert('type', (v) => v as String),
          ownerId: $checkedConvert('ownerId', (v) => v as String),
          createdAt: $checkedConvert('createdAt', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$CreateGroupResponseToJson(
        CreateGroupResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'ownerId': instance.ownerId,
      'createdAt': instance.createdAt,
    };

InviteToGroupRequest _$InviteToGroupRequestFromJson(
        Map<String, dynamic> json) =>
    InviteToGroupRequest(
      groupId: json['groupId'] as String,
      memberIds:
          (json['memberIds'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$InviteToGroupRequestToJson(
        InviteToGroupRequest instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'memberIds': instance.memberIds,
    };

InviteToGroupResponse _$InviteToGroupResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'InviteToGroupResponse',
      json,
      ($checkedConvert) {
        final val = InviteToGroupResponse(
          count: $checkedConvert('count', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$InviteToGroupResponseToJson(
        InviteToGroupResponse instance) =>
    <String, dynamic>{
      'count': instance.count,
    };

Map<String, dynamic> _$LeaveGroupRequestToJson(LeaveGroupRequest instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
    };

LeaveGroupResponse _$LeaveGroupResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LeaveGroupResponse',
      json,
      ($checkedConvert) {
        final val = LeaveGroupResponse(
          success: $checkedConvert('success', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$LeaveGroupResponseToJson(LeaveGroupResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
    };
