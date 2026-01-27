import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import 'chat_ui_model.dart';

part 'conversation.g.dart';

// 1. 优化：统一枚举命名风格 (Dart 推荐小驼峰)
enum ConversationType {
  @JsonValue('DIRECT') direct,
  @JsonValue('GROUP') group,
  @JsonValue('BUSINESS') business,
  @JsonValue('SUPPORT') support,
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
  // unknownEnumValue: 防止后端返回了无法识别的状态时报错，默认回退到 success
  @JsonKey(unknownEnumValue: MessageStatus.success)
  final MessageStatus lastMsgStatus;

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
    this.lastMsgStatus = MessageStatus.success,
  });

  Conversation copyWith({
    String? id,
    ConversationType? type,
    String? name,
    String? avatar,
    String? lastMsgContent,
    int? lastMsgTime,
    int? unreadCount,
    bool? isPinned,
    bool? isMuted,
    MessageStatus? lastMsgStatus,
  }) {
    return Conversation(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      lastMsgContent: lastMsgContent ?? this.lastMsgContent,
      lastMsgTime: lastMsgTime ?? this.lastMsgTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      lastMsgStatus: lastMsgStatus ?? this.lastMsgStatus,
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationToJson(this);

  @override
  String toString() => toJson().toString();
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
  String toString() => toJson().toString();
}

@JsonSerializable(checked: true)
class ChatMessage {
  final String id;
  final int type; // 0:Text, 1:Image
  final String content;
  final int createdAt;
  final ChatSender? sender;
  final int? seqId;
  final bool isRecalled;

  // [新增] 核心字段
  final Map<String, dynamic>? meta;
  // 接收后端的 isSelf 字段
  @JsonKey(defaultValue: false)
  final bool isSelf;

  ChatMessage({
    required this.id,
    required this.type,
    required this.content,
    required this.createdAt,
    this.isRecalled = false,
    this.sender,
    this.isSelf = false,
    this.seqId,
    this.meta,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  @override
  String toString() => toJson().toString();
}

// ==========================================
// 成员模型
// ==========================================
@JsonSerializable(checked: true)
class ChatMember {
  final String userId;
  final String nickname;
  final String? avatar;
  final String role;

  ChatMember({
    required this.userId,
    required this.nickname,
    this.avatar,
    required this.role,
  });

  factory ChatMember.fromJson(Map<String, dynamic> json) =>
      _$ChatMemberFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMemberToJson(this);
}

// ==========================================
// 详情模型
// ==========================================
// lib/ui/chat/models/conversation.dart

class ConversationDetail {
  final String id;
  final String name;
  final String? avatar;
  final ConversationType type;
  final List<ChatMember> members;

  ConversationDetail({
    required this.id,
    required this.name,
    this.avatar,
    required this.type,
    required this.members,
  });

  factory ConversationDetail.fromJson(Map<String, dynamic> json) {
    // 后端返回的是 "GROUP", "DIRECT" 等字符串
    final typeStr = json['type']?.toString().toUpperCase() ?? 'GROUP';

    final typeEnum = ConversationType.values.firstWhere(
          (e) => e.name.toUpperCase() == typeStr,
      orElse: () => ConversationType.group, // 匹配不到默认为群聊
    );

    return ConversationDetail(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      type: typeEnum,
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => ChatMember.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,

      // 这样本地数据库存的就是 "GROUP" 而不是 0 或 1，更直观且不怕枚举顺序改变
      'type': type.name.toUpperCase(),

      'members': members.map((m) => m.toJson()).toList(),
    };
  }

  int get memberCount => members.length;
}

@JsonSerializable(checked: true)
class ConversationIdResponse {
  final String conversationId;

  ConversationIdResponse({required this.conversationId});

  factory ConversationIdResponse.fromJson(Map<String, dynamic> json) =>
      _$ConversationIdResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationIdResponseToJson(this);

  @override
  String toString() => toJson().toString();
}

// ==========================================
//  新增：历史消息请求参数 Request
// ==========================================
@JsonSerializable(createFactory: false) // 我们只需要 toJson 发送给后端
class MessageHistoryRequest {
  final String conversationId;

  // 后端接收的是 'cursor'，所以这里把 Dart 的 beforeMessageId 映射过去
  // 当然你也可以直接改名叫 cursor
  final String? cursor;

  final int pageSize; // 你可以用 pageSize, 映射为后端的 limit

  MessageHistoryRequest({
    required this.conversationId,
    this.pageSize = 20,
    this.cursor,
  });

  Map<String, dynamic> toJson() => _$MessageHistoryRequestToJson(this);
}

// ==========================================
//  新增：历史消息响应 Wrapper Response
// 对应后端的 { list: [], nextCursor: "..." }
// ==========================================
@JsonSerializable(checked: true)
class MessageListResponse {
  @JsonKey(defaultValue: [])
  final List<ChatMessage> list;

  // 下一页游标，如果为 null 说明没有更多数据了
  final String? nextCursor;
  final int partnerLastReadSeqId;

  MessageListResponse({
    required this.list,
    required this.partnerLastReadSeqId,
    this.nextCursor,
  });

  factory MessageListResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MessageListResponseToJson(this);

  @override
  String toString() => toJson().toString();
}


@JsonSerializable(checked: true)
class SocketMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final int type;
  final int createdAt;
  final SocketSender? sender;
  final String? tempId;
  final bool? isSelf;

  final int? seqId;
  final Map<String, dynamic>? meta;

  SocketMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.createdAt,
    this.sender,
    this.tempId,
     this.isSelf,
    this.seqId,
    this.meta,
  });

  factory SocketMessage.fromJson(Map<String, dynamic> json) => _$SocketMessageFromJson(json);
  Map<String, dynamic> toJson() => _$SocketMessageToJson(this);

  @override
  String toString() => toJson().toString();

}

@JsonSerializable(checked: true)
class SocketSender {
  final String id;
  final String nickname;
  final String? avatar;

  SocketSender({
    required this.id,
    this.nickname = 'Unknown',
    this.avatar
  });

  factory SocketSender.fromJson(Map<String, dynamic> json) => _$SocketSenderFromJson(json);
  Map<String, dynamic> toJson() => _$SocketSenderToJson(this);

  @override
  String toString() => toJson().toString();

}

@JsonSerializable(checked: true)
class MessageMarkReadRequest {
  final String conversationId;
  final int? maxSeqId;

  MessageMarkReadRequest({
    required this.conversationId,
    this.maxSeqId,
  });

  Map<String, dynamic> toJson() => _$MessageMarkReadRequestToJson(this);

}

@JsonSerializable(checked: true)
class MessageMarkReadResponse {
  final int unreadCount;
  final int lastReadSeqId;

  MessageMarkReadResponse({
    required this.unreadCount,
    required this.lastReadSeqId,
  });

  factory MessageMarkReadResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageMarkReadResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MessageMarkReadResponseToJson(this);

  @override
  String toString() => toJson().toString();
}

@JsonSerializable(checked: true)
class SocketReadEvent {
  final String conversationId;
  final String readerId;
  final bool? isSelf;
  @JsonKey(defaultValue: 0)
  final int lastReadSeqId;

  SocketReadEvent({
    required this.conversationId,
    required this.readerId,
    required this.lastReadSeqId,
     this.isSelf,
  });

  factory SocketReadEvent.fromJson(Map<String, dynamic> json) =>
      _$SocketReadEventFromJson(json);
}


@JsonSerializable(checked: true)
class MessageRecallRequest {
  final String conversationId;
  final String messageId;

  MessageRecallRequest({
    required this.conversationId,
    required this.messageId,
  });

  Map<String, dynamic> toJson() => _$MessageRecallRequestToJson(this);
}


@JsonSerializable(checked: true)
class MessageRecallResponse {
  final String messageId;
  final String tip;
  MessageRecallResponse({
    required this.messageId,
    required this.tip,
  });
  factory MessageRecallResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageRecallResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MessageRecallResponseToJson(this);
  @override
  String toString() => toJson().toString();
}


@JsonSerializable(checked: true)
class SocketRecallEvent {
  final String conversationId;
  final String messageId;
  final String tip;
  final String operatorId;
  final int? seqId;
  final bool isSelf;

  SocketRecallEvent({
    required this.conversationId,
    required this.messageId,
    required this.tip,
    required this.isSelf,
    required this.operatorId,
    this.seqId,
  });
  factory SocketRecallEvent.fromJson(Map<String, dynamic> json) =>
      _$SocketRecallEventFromJson(json);
}


@JsonSerializable(checked: true)
class MessageDeleteRequest {
  final String messageId;
  final String conversationId;

  MessageDeleteRequest({
    required this.messageId,
    required this.conversationId,
  });

  Map<String, dynamic> toJson() => _$MessageDeleteRequestToJson(this);
}

@JsonSerializable(checked: true)
class MessageDeleteResponse {
  final String messageId;
  MessageDeleteResponse({
    required this.messageId,
  });
  factory MessageDeleteResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageDeleteResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MessageDeleteResponseToJson(this);
  @override
  String toString() => toJson().toString();
}

// ==========================================
//  搜索用户/联系人基础模型
// ==========================================
@JsonSerializable(checked: true)
class ChatUser {
  final String id;
  final String nickname;
  final String? avatar;
  final String? phone; // 搜索时可能返回手机号

  ChatUser({
    required this.id,
    required this.nickname,
    this.avatar,
    this.phone,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) => _$ChatUserFromJson(json);
  Map<String, dynamic> toJson() => _$ChatUserToJson(this);
}

// ==========================================
//  添加好友请求
// ==========================================
@JsonSerializable(createFactory: false)
class AddFriendRequest {
  final String friendId;

  AddFriendRequest({required this.friendId});

  Map<String, dynamic> toJson() => _$AddFriendRequestToJson(this);
}

// ==========================================
//  创建群聊请求参数
// ==========================================
@JsonSerializable(createFactory: false)
class CreateGroupRequest {
  final String name;
  final List<String> memberIds; // 选中的好友 ID 列表

  CreateGroupRequest({
    required this.name,
    required this.memberIds,
  });

  Map<String, dynamic> toJson() => _$CreateGroupRequestToJson(this);
}

// ==========================================
//  建群成功响应 (通常后端会返回创建成功的会话详情)
// ==========================================
@JsonSerializable(checked: true)
class CreateGroupResponse {
  final String id;          // 对应 Conversation ID
  final String name;
  final String type;        // "GROUP"
  final String ownerId;
  final int? createdAt;

  CreateGroupResponse({
    required this.id,
    required this.name,
    required this.type,
    required this.ownerId,
     this.createdAt,
  });

  factory CreateGroupResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateGroupResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreateGroupResponseToJson(this);
}


@JsonSerializable(createFactory: true)
class InviteToGroupRequest {
  final String groupId;
  final List<String> memberIds;

  InviteToGroupRequest({
    required this.groupId,
    required this.memberIds,
  });

  Map<String, dynamic> toJson() => _$InviteToGroupRequestToJson(this);

}


@JsonSerializable(checked: true)
class InviteToGroupResponse {
  final int count;

  InviteToGroupResponse({required this.count});

  factory InviteToGroupResponse.fromJson(Map<String, dynamic> json) =>
      _$InviteToGroupResponseFromJson(json);

  Map<String, dynamic> toJson() => _$InviteToGroupResponseToJson(this);


  @override
  String toString() => toJson().toString();
}


@JsonSerializable(createFactory: false)
class LeaveGroupRequest {
  final String groupId;

  LeaveGroupRequest({required this.groupId});

  Map<String, dynamic> toJson() => _$LeaveGroupRequestToJson(this);
}


@JsonSerializable(checked: true)
class LeaveGroupResponse {
  final bool success;

  LeaveGroupResponse({required this.success});

  factory LeaveGroupResponse.fromJson(Map<String, dynamic> json) =>
      _$LeaveGroupResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LeaveGroupResponseToJson(this);

  @override
  String toString() => toJson().toString();
}