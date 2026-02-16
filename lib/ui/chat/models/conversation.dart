import 'package:json_annotation/json_annotation.dart';
import 'chat_ui_model.dart';
import 'group_manage_req.dart';
import 'group_role.dart';

part 'conversation.g.dart';

// =================================================================
// 1. 枚举定义 (Enums)
// =================================================================

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

// =================================================================
// 2. Conversation 列表项模型
// =================================================================

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

// =================================================================
// 3. Socket Payload & Event (核心修复区)
// =================================================================

@JsonSerializable(createToJson: false) // 只需反序列化
class ChatSocketPayload {
  // 3.1 核心三要素 (Context, Subject, Object)
  final String conversationId;
  final String? operatorId; // 操作人
  final String? targetId;   // 目标人 (标准化后，兼容所有ID字段)

  // 3.2 [新增] 入群审批系统专用字段
  final bool? approved;      // 对应 GroupApplyResultEvent.approved
  final String? applicantId; // 对应 GroupApplyResultEvent.applicantId
  final String? groupName;   // 对应 GroupApplyResultEvent.groupName
  final String? reason;      // 对应 GroupApplyNewEvent.reason
  final String? nickname;    // 对应 GroupApplyNewEvent.nickname
  final String? avatar;      // 对应 GroupApplyNewEvent.avatar
  final String? requestId;   // 对应 GroupRequestHandledEvent.requestId
  final int? status;         // 对应 GroupRequestHandledEvent.status
  final String? handlerName; // 对应 GroupRequestHandledEvent.handlerName

  // 3.3 原有业务字段 (Details)
  final Map<String, dynamic> updates; // 群信息更新内容
  final int? mutedUntil;              // 禁言截止时间
  final String? newRole;              // 新角色
  final int? timestamp;               // 时间戳
  final String? syncType;            // 同步类型

  // 3.4 复杂对象 (Complex Objects)
  final ChatMember? member; // 单个成员信息
  final List<ChatMember>? members; // [新增] 批量成员信息

  // 3.5 兼容旧字段 (不参与构造，逻辑辅助)
  @JsonKey(includeFromJson: false)
  final String? kickedUserId;

  ChatSocketPayload({
    required this.conversationId,
    this.operatorId,
    this.targetId,

    // 新增字段
    this.approved,
    this.applicantId,
    this.groupName,
    this.reason,
    this.nickname,
    this.avatar,
    this.requestId,
    this.status,
    this.handlerName,

    this.updates = const {},
    this.mutedUntil,
    this.newRole,
    this.timestamp,
    this.member,
    this.members,
    this.kickedUserId,
    this.syncType
  });

  /// 万能解析工厂 (手动实现以处理复杂的兼容逻辑)
  factory ChatSocketPayload.fromJson(Map<String, dynamic> json) {
    return ChatSocketPayload(
      conversationId: json['conversationId']?.toString() ?? '',

      //  统一读取 operatorId
      operatorId: json['operatorId']?.toString(),

      //  统一读取 targetId (强力兼容后端旧字段 + 新增的 applicantId)
      targetId: json['targetId']?.toString()
          ?? json['memberId']?.toString()
          ?? json['userId']?.toString()
          ?? json['kickedUserId']?.toString()
          ?? json['newOwnerId']?.toString()
          ?? json['applicantId']?.toString(), //  兼容申请人ID

      //  解析 updates (防空、防嵌套)
      updates: (json['updates'] is Map)
          ? Map<String, dynamic>.from(json['updates'])
          : {},

      //  解析具体业务字段
      mutedUntil: json['mutedUntil'] is int ? json['mutedUntil'] : null,
      newRole: json['newRole']?.toString(),
      timestamp: json['timestamp'] is int ? json['timestamp'] : null,
      syncType: json['syncType']?.toString(),

      //   解析审批流新字段 (防止类型错误导致 Crash)
      approved: json['approved'] is bool ? json['approved'] : null,
      applicantId: json['applicantId']?.toString(),
      groupName: json['groupName']?.toString(),
      reason: json['reason']?.toString(),
      nickname: json['nickname']?.toString(),
      avatar: json['avatar']?.toString(),
      requestId: json['requestId']?.toString(),
      status: json['status'] is int ? json['status'] : null,
      handlerName: json['handlerName']?.toString(),

      //  直接解析为 ChatMember 对象
      member: json['member'] != null
          ? ChatMember.fromJson(json['member'])
          : null,

      //   解析批量成员列表
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => ChatMember.fromJson(e))
          .toList(),
    );
  }

  @override
  String toString() {
    return 'ChatSocketPayload(targetId: $targetId, operatorId: $operatorId, syncType: $syncType)';
  }
}

class SocketGroupEvent {
  final String type;                 // 事件类型 (e.g. member_kicked)
  final Map<String, dynamic> rawData; // 原始数据
  late final ChatSocketPayload payload; // 解析后的强类型数据

  //  [修复] 补回 groupId getter，供 Provider 使用
  String get groupId => payload.conversationId;

  SocketGroupEvent({
    required this.type,
    required this.rawData,
  }) {
    // 初始化时自动解析 Payload
    payload = ChatSocketPayload.fromJson(rawData);
  }

  //  [修复] 补回 factory，供 chat_extension.dart 使用
  factory SocketGroupEvent.fromJson(String type, Map<String, dynamic> json) {
    return SocketGroupEvent(
      type: type,
      rawData: json,
    );
  }
}

// =================================================================
// 4. ConversationDetail 详情模型
// =================================================================

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
  //  [新增] 申请状态: 'NONE' | 'PENDING'
  // 注意：后端如果返回 null，默认视为 'NONE'
  final String? applicationStatus;
  final int pendingRequestCount;
  final int memberCount;

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
    this.applicationStatus,
    this.pendingRequestCount = 0,
    required this.memberCount,
  });

  ConversationDetail copyWith({
    String? id,
    String? name,
    String? avatar,
    int? unreadCount,
    ConversationType? type,
    List<ChatMember>? members,
    String? ownerId,
    int? lastMsgSeqId,
    int? myLastReadSeqId,
    bool? isPinned,
    bool? isMuted,
    String? announcement,
    bool? isMuteAll,
    bool? joinNeedApproval,
    String? applicationStatus,
    int? pendingRequestCount,
    int? memberCount,
  }) {
    return ConversationDetail(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      unreadCount: unreadCount ?? this.unreadCount,
      type: type ?? this.type,
      members: members ?? this.members,
      ownerId: ownerId ?? this.ownerId,
      lastMsgSeqId: lastMsgSeqId ?? this.lastMsgSeqId,
      myLastReadSeqId: myLastReadSeqId ?? this.myLastReadSeqId,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      announcement: announcement ?? this.announcement,
      isMuteAll: isMuteAll ?? this.isMuteAll,
      joinNeedApproval: joinNeedApproval ?? this.joinNeedApproval,
      applicationStatus:  applicationStatus?? this.applicationStatus,
      pendingRequestCount: pendingRequestCount ?? this.pendingRequestCount,
      memberCount: memberCount ?? this.memberCount,
    );

  }

  /// 获取对方成员对象 (仅限单聊)
  /// [myUserId]: 当前登录用户的 ID
  ChatMember? getOtherMember(String? myUserId) {
    if(type != ConversationType.direct) return null; // 仅单聊适用
    if(myUserId == null) return null; // 无法确定对方
    if(members.isEmpty) return null; // 没有成员数据
    try {
      // 找到第一个 ID 不等于我的成员
      return members.firstWhere((m) => m.userId != myUserId);
    } catch (e) {
      // 如果只有我自己 (比如自己跟自己发消息)，或者数据异常
      // 兜底返回第一个人，或者 null
      return members.isNotEmpty ? members.first : null;
    }

  }

  // 获取对方 UserID (快捷方式)
  String? getTargetId(String? myUserId) {
    return getOtherMember(myUserId)?.userId;
  }

  /// 获取显示名称 (如果是单聊显示对方名，群聊显示群名)
  String getDisplayName(String? myUserId) {
    if (type == ConversationType.group) {
      return name; // 群聊直接返回群名
    }
    // 单聊返回对方昵称，找不到就返回默认 name
    return getOtherMember(myUserId)?.nickname ?? name;
  }

  /// 获取显示头像 (如果是单聊显示对方头像，群聊显示群头像)
  String? getDisplayAvatar(String? myUserId) {
    if (type == ConversationType.group) {
      return avatar;
    }
    // 单聊返回对方头像，如果对方没头像，再看 detail.avatar
    return getOtherMember(myUserId)?.avatar ?? avatar;
  }

  factory ConversationDetail.fromJson(Map<String, dynamic> json) {
    // 处理枚举
    final typeStr = json['type']?.toString().toUpperCase() ?? 'GROUP';
    final typeEnum = ConversationType.values.firstWhere(
          (e) => e.name.toUpperCase() == typeStr,
      orElse: () => ConversationType.group,
    );
    

    return ConversationDetail(
      // 关键修复：必填 String 字段必须给默认值，防止数据库脏数据导致 Crash
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Group',
      ownerId: json['ownerId']?.toString() ?? '',

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
      applicationStatus: json['applicationStatus']?.toString(),
      pendingRequestCount: json['pendingRequestCount'] ?? 0,
      memberCount: json['memberCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'avatar': avatar,
      'unreadCount': unreadCount,
      'type': type.name.toUpperCase(),
      'members': members.map((m) => m.toJson()).toList(),

      'lastMsgSeqId': lastMsgSeqId,
      'myLastReadSeqId': myLastReadSeqId,
      'isPinned': isPinned,
      'isMuted': isMuted,

      'announcement': announcement,
      'isMuteAll': isMuteAll,
      'joinNeedApproval': joinNeedApproval,
      'applicationStatus': applicationStatus,
      'pendingRequestCount': pendingRequestCount,
    };
  }

  @override
  String toString() => toJson().toString();

}

// =================================================================
// 5. 辅助模型 (Sender, Member, Message)
// =================================================================

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

  bool get isOwner => role == GroupRole.owner;
  bool get isAdmin => role == GroupRole.admin;
  bool get isManagement => isOwner || isAdmin;

  //  2. 权限比较
  bool canManage(ChatMember target) {
    if (userId == target.userId) return false; // 不能动自己
    return role.canManageMembers(target.role); // 依赖 Enum 里的逻辑
  }

  bool get isMuted {
    if (mutedUntil == null) return false;
    final until = DateTime.fromMillisecondsSinceEpoch(mutedUntil!);
    return DateTime.now().isBefore(until);
  }

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

@JsonSerializable(checked: true)
class ChatMessage {
  final String id;
  final int type; // 0:Text, 1:Image
  final String content;
  final int createdAt;
  final ChatSender? sender;
  final int? seqId;
  @JsonKey(defaultValue: false)
  final bool? isRecalled;

  final Map<String, dynamic>? meta;

  @JsonKey(defaultValue: false)
  final bool isSelf;

  ChatMessage({
    required this.id,
    required this.type,
    required this.content,
    required this.createdAt,
     this.isRecalled,
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

// =================================================================
// 6. 其他 API 请求/响应模型 (保持不变)
// =================================================================

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
  @JsonKey(defaultValue: false) // 显式告诉解析器：没传就是 false
  final bool? isRecalled;

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
    this.isRecalled
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

@JsonSerializable(checked: true)
class GroupSearchResult {
  final String id;
  final String name;
  final String? avatar;
  final int memberCount; // 后端通过 _count 计算出来的
  final bool joinNeedApproval;
  final bool isMember;   // 核心字段：前端据此判断显示 "Join" 还是 "Enter"

  GroupSearchResult({
    required this.id,
    required this.name,
    this.avatar,
    required this.memberCount,
    required this.joinNeedApproval,
    required this.isMember,
  });

  factory GroupSearchResult.fromJson(Map<String, dynamic> json) =>
      _$GroupSearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$GroupSearchResultToJson(this);
}
