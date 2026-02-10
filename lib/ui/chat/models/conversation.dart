import 'package:json_annotation/json_annotation.dart';
import 'chat_ui_model.dart';
import 'group_role.dart';

part 'conversation.g.dart';

// 1. 优化：统一枚举命名风格
enum ConversationType {
  @JsonValue('DIRECT') direct,
  @JsonValue('GROUP') group,
  @JsonValue('BUSINESS') business,
  @JsonValue('SUPPORT') support,
}

// relationship :0=Stranger, 1=Friend, 2=RequestSent
enum RelationshipStatus {
  @JsonValue(0) stranger,
  @JsonValue(1) friend,
  @JsonValue(2) sent;

  bool get isFriend => this == RelationshipStatus.friend;
  bool get isStranger => this == RelationshipStatus.stranger;
  bool get isSent => this == RelationshipStatus.sent;
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

  final String? announcement; // 群公告
  final bool isMuteAll; // 全员禁言开关
  final bool joinNeedApproval; // 加群是否需要审批

  // 同步断点字段
  @JsonKey(defaultValue: 0)
  final int lastMsgSeqId;

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
    this.lastMsgSeqId = 0,
    this.lastMsgStatus = MessageStatus.success,

    this.announcement,
    this.isMuteAll = false,
    this.joinNeedApproval = false,
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
    int? lastMsgSeqId,
    MessageStatus? lastMsgStatus,

      String? announcement,
      bool? isMuteAll,
      bool? joinNeedApproval,
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
      lastMsgSeqId: lastMsgSeqId ?? this.lastMsgSeqId,
      lastMsgStatus: lastMsgStatus ?? this.lastMsgStatus,

      announcement: announcement ?? this.announcement,
      isMuteAll: isMuteAll ?? this.isMuteAll,
      joinNeedApproval: joinNeedApproval ?? this.joinNeedApproval,
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
  final String? phone;

  ChatSender({required this.id, required this.nickname, this.avatar, this.phone});

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

  final Map<String, dynamic>? meta;

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
  final GroupRole role;
  final int? mutedUntil;

  ChatMember({
    required this.userId,
    required this.nickname,
    this.avatar,
    required this.role,
    this.mutedUntil,
  });

  // computed property to check if currently muted
  bool get isMuted {
    if (mutedUntil == null) return false;
    final until = DateTime.fromMillisecondsSinceEpoch(mutedUntil!);
    return DateTime.now().isBefore(until);
  }

  // return seconds left to unmute, or 0 if not muted
  Duration get muteRemaining {
    if (mutedUntil == null) return Duration.zero;
    final until = DateTime.fromMillisecondsSinceEpoch(mutedUntil!);
    final diff = until.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  factory ChatMember.fromJson(Map<String, dynamic> json) =>
      _$ChatMemberFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMemberToJson(this);

  ChatMember copyWith({
    String? userId,
    String? nickname,
    String? avatar,
    GroupRole? role,
    int? mutedUntil,
  }) {
    return ChatMember(
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      mutedUntil: mutedUntil ?? this.mutedUntil,
    );
  }
}

// 详情模型 (ConversationDetail)
@JsonSerializable(checked: true)
class ConversationDetail {
  final String id;
  final String name;
  final String? avatar;
  final int unreadCount;
  final ConversationType type;
  final List<ChatMember> members;
  final String ownerId;

  // [NEW] v6.0 群设置补充字段
  final String? announcement;      // 群公告
  final bool isMuteAll;            // 全员禁言开关
  final bool joinNeedApproval;    // 加群是否需要审批

  // [NEW] 详情页补充字段
  final int lastMsgSeqId;
  final int myLastReadSeqId;
  final bool isPinned;
  final bool isMuted;

  ConversationDetail({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.members,
    required this.type,


    this.avatar,
    this.unreadCount = 0,
    this.lastMsgSeqId = 0,
    this.myLastReadSeqId = 0,
    this.isPinned = false,
    this.isMuted = false,

    this.announcement,
    this.isMuteAll = false,
    this.joinNeedApproval = false,
  });

  ConversationDetail copyWith({
    String? id,
    String? name,
    String? avatar,
    int? unreadCount,
    ConversationType? type,
    List<ChatMember>? members,
    int? lastMsgSeqId,
    int? myLastReadSeqId,
    bool? isPinned,
    bool? isMuted,

    String? announcement,
    bool? isMuteAll,
    bool? joinNeedApproval,
  }) {
    return ConversationDetail(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      unreadCount: unreadCount ?? this.unreadCount,
      type: type ?? this.type,
      members: members ?? this.members,
      lastMsgSeqId: lastMsgSeqId ?? this.lastMsgSeqId,
      myLastReadSeqId: myLastReadSeqId ?? this.myLastReadSeqId,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      announcement: announcement ?? this.announcement,
      isMuteAll: isMuteAll ?? this.isMuteAll,
      joinNeedApproval: joinNeedApproval ?? this.joinNeedApproval,
      ownerId: ownerId,
    );
  }

  factory ConversationDetail.fromJson(Map<String, dynamic> json) {
    // 后端返回的是 "GROUP", "DIRECT" 等字符串
    final typeStr = json['type']?.toString().toUpperCase() ?? 'GROUP';

    final typeEnum = ConversationType.values.firstWhere(
          (e) => e.name.toUpperCase() == typeStr,
      orElse: () => ConversationType.group,
    );

    return ConversationDetail(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      unreadCount: json['unreadCount'] ?? 0,
      type: typeEnum,
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => ChatMember.fromJson(e))
          .toList() ?? [],

      lastMsgSeqId: json['lastMsgSeqId'] ?? 0,
      myLastReadSeqId: json['myLastReadSeqId'] ?? 0,
      isPinned: json['isPinned'] ?? false,
      isMuted: json['isMuted'] ?? false,
      announcement: json['announcement'],
      isMuteAll: json['isMuteAll'] ?? false,
      joinNeedApproval: json['joinNeedApproval'] ?? false,
      ownerId: json['ownerId']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'unreadCount': unreadCount,
      'type': type.name.toUpperCase(),
      'members': members.map((m) => m.toJson()).toList(),
      'lastMsgSeqId': lastMsgSeqId,
      'myLastReadSeqId': myLastReadSeqId,
      'isPinned': isPinned,
      'isMuted': isMuted,
    };
  }

  int get memberCount => members.length;
}

// ==========================================
//  其他 API 请求/响应模型 (保持不变)
// ==========================================

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

@JsonSerializable(createFactory: false)
class MessageHistoryRequest {
  final String conversationId;
  final int? cursor;
  final int pageSize;

  MessageHistoryRequest({
    required this.conversationId,
    this.pageSize = 20,
    this.cursor,
  });

  Map<String, dynamic> toJson() => _$MessageHistoryRequestToJson(this);
}

@JsonSerializable(checked: true)
class MessageListResponse {
  @JsonKey(defaultValue: [])
  final List<ChatMessage> list;

  final int? nextCursor;
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
  @JsonKey(name: 'unreadCount', defaultValue: 0)
  final int unreadCount;
  final int lastReadSeqId;

  MessageMarkReadResponse({
    this.unreadCount = 0,
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

@JsonSerializable(checked: true)
class ChatUser {
  final String id;
  final String nickname;
  final String? avatar;
  final String? phone;
  @JsonKey(unknownEnumValue: RelationshipStatus.stranger)
  final RelationshipStatus status;

  ChatUser({
    required this.id,
    required this.nickname,
    this.avatar,
    this.phone,
    this.status = RelationshipStatus.stranger,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) => _$ChatUserFromJson(json);
  Map<String, dynamic> toJson() => _$ChatUserToJson(this);
}

@JsonSerializable(createFactory: false)
class CreateGroupRequest {
  final String name;
  final List<String> memberIds;

  CreateGroupRequest({
    required this.name,
    required this.memberIds,
  });

  Map<String, dynamic> toJson() => _$CreateGroupRequestToJson(this);
}

@JsonSerializable(checked: true)
class CreateGroupResponse {
  final String id;
  final String name;
  final String type;
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