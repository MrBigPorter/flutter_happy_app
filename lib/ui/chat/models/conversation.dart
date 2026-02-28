import 'package:json_annotation/json_annotation.dart';
import 'chat_ui_model.dart';
import 'group_manage_req.dart';
import 'group_role.dart';

part 'conversation.g.dart';

// =================================================================
// 1. Enums Definitions
// =================================================================

enum ConversationType {
  @JsonValue('DIRECT') direct,
  @JsonValue('GROUP') group,
  @JsonValue('BUSINESS') business,
  @JsonValue('SUPPORT') support,
}

/// Relationship status codes: 0=Stranger, 1=Friend, 2=RequestSent
enum RelationshipStatus {
  @JsonValue(0) stranger,
  @JsonValue(1) friend,
  @JsonValue(2) sent;

  bool get isFriend => this == RelationshipStatus.friend;
  bool get isStranger => this == RelationshipStatus.stranger;
  bool get isSent => this == RelationshipStatus.sent;
}

// =================================================================
// 2. Conversation List Item Model
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

  final String? announcement; // Group announcement text
  final bool isMuteAll; // Global mute switch for the group
  final bool joinNeedApproval; // Whether new members require admin approval

  @JsonKey(defaultValue: 0)
  final int lastMsgSeqId;

  // unknownEnumValue: Prevents crashes if backend returns an unrecognized status
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
// 3. Socket Payload & Event Models
// =================================================================

@JsonSerializable(createToJson: false)
class ChatSocketPayload {
  // Core identifiers: Context, Subject, Object
  final String conversationId;
  final String? operatorId;
  final String? targetId;

  // Fields specific to the group application and approval workflow
  final bool? approved;
  final String? applicantId;
  final String? groupName;
  final String? reason;
  final String? nickname;
  final String? avatar;
  final String? requestId;
  final int? status;
  final String? handlerName;

  // Operational details
  final Map<String, dynamic> updates;
  final int? mutedUntil;
  final String? newRole;
  final int? timestamp;
  final String? syncType;

  // Complex relational data
  final ChatMember? member;
  final List<ChatMember>? members;

  @JsonKey(includeFromJson: false)
  final String? kickedUserId;

  ChatSocketPayload({
    required this.conversationId,
    this.operatorId,
    this.targetId,

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

  /// Hand-written factory to handle complex legacy field mappings and type safety
  factory ChatSocketPayload.fromJson(Map<String, dynamic> json) {
    return ChatSocketPayload(
      conversationId: json['conversationId']?.toString() ?? '',
      operatorId: json['operatorId']?.toString(),

      // Unified targetId mapping: Handles various ID keys from different backend event types
      targetId: json['targetId']?.toString()
          ?? json['memberId']?.toString()
          ?? json['userId']?.toString()
          ?? json['kickedUserId']?.toString()
          ?? json['newOwnerId']?.toString()
          ?? json['applicantId']?.toString(),

      updates: (json['updates'] is Map)
          ? Map<String, dynamic>.from(json['updates'])
          : {},

      mutedUntil: json['mutedUntil'] is int ? json['mutedUntil'] : null,
      newRole: json['newRole']?.toString(),
      timestamp: json['timestamp'] is int ? json['timestamp'] : null,
      syncType: json['syncType']?.toString(),

      approved: json['approved'] is bool ? json['approved'] : null,
      applicantId: json['applicantId']?.toString(),
      groupName: json['groupName']?.toString(),
      reason: json['reason']?.toString(),
      nickname: json['nickname']?.toString(),
      avatar: json['avatar']?.toString(),
      requestId: json['requestId']?.toString(),
      status: json['status'] is int ? json['status'] : null,
      handlerName: json['handlerName']?.toString(),

      member: json['member'] != null
          ? ChatMember.fromJson(json['member'])
          : null,

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
  final String type;                 // Event type string (e.g., 'member_kicked')
  final Map<String, dynamic> rawData; // Original raw JSON data
  late final ChatSocketPayload payload; // Strongly typed payload

  String get groupId => payload.conversationId;

  SocketGroupEvent({
    required this.type,
    required this.rawData,
  }) {
    payload = ChatSocketPayload.fromJson(rawData);
  }

  factory SocketGroupEvent.fromJson(String type, Map<String, dynamic> json) {
    return SocketGroupEvent(
      type: type,
      rawData: json,
    );
  }
}

// =================================================================
// 4. Detailed Conversation Model
// =================================================================

class ConversationDetail {
  final String id;
  final String name;
  final String? avatar;
  final int unreadCount;
  final ConversationType type;
  final List<ChatMember> members;
  final String ownerId;

  // Administrative and Metadata fields
  final String? announcement;
  final bool isMuteAll;
  final bool joinNeedApproval;
  final String? applicationStatus; // Application state: 'NONE' | 'PENDING'
  final int pendingRequestCount;
  final int memberCount;

  // Pagination and User-specific state
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

  /// Retrieves the peer member object (applicable to Direct messages only)
  ChatMember? getOtherMember(String? myUserId) {
    if(type != ConversationType.direct) return null;
    if(myUserId == null || members.isEmpty) return null;
    try {
      return members.firstWhere((m) => m.userId != myUserId);
    } catch (e) {
      // Fallback for self-conversations or data anomalies
      return members.isNotEmpty ? members.first : null;
    }
  }

  String? getTargetId(String? myUserId) {
    return getOtherMember(myUserId)?.userId;
  }

  /// Resolves the UI display name (Target nickname for Direct, Group name for Group)
  String getDisplayName(String? myUserId) {
    if (type == ConversationType.group) {
      return name;
    }
    return getOtherMember(myUserId)?.nickname ?? name;
  }

  /// Resolves the UI display avatar
  String? getDisplayAvatar(String? myUserId) {
    if (type == ConversationType.group) {
      return avatar;
    }
    return getOtherMember(myUserId)?.avatar ?? avatar;
  }

  factory ConversationDetail.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type']?.toString().toUpperCase() ?? 'GROUP';
    final typeEnum = ConversationType.values.firstWhere(
          (e) => e.name.toUpperCase() == typeStr,
      orElse: () => ConversationType.group,
    );

    return ConversationDetail(
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
// 5. Supporting Models: Sender, Member, Message
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

  /// Permissions comparison logic based on hierarchical roles
  bool canManage(ChatMember target) {
    if (userId == target.userId) return false;
    return role.canManageMembers(target.role);
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
  final int type; // 0:Text, 1:Image, etc.
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
// 6. API Interaction Models
// =================================================================

@JsonSerializable(checked: true)
class ConversationIdResponse {
  final String conversationId;
  ConversationIdResponse({required this.conversationId});
  factory ConversationIdResponse.fromJson(Map<String, dynamic> json) => _$ConversationIdResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationIdResponseToJson(this);
}

@JsonSerializable(createFactory: false)
class MessageHistoryRequest {
  final String conversationId;
  final int? cursor;
  final int pageSize;
  MessageHistoryRequest({required this.conversationId, this.pageSize = 20, this.cursor});
  Map<String, dynamic> toJson() => _$MessageHistoryRequestToJson(this);
}

@JsonSerializable(checked: true)
class MessageListResponse {
  @JsonKey(defaultValue: [])
  final List<ChatMessage> list;
  final int? nextCursor;
  final int partnerLastReadSeqId;
  MessageListResponse({required this.list, required this.partnerLastReadSeqId, this.nextCursor});
  factory MessageListResponse.fromJson(Map<String, dynamic> json) => _$MessageListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MessageListResponseToJson(this);
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
  @JsonKey(defaultValue: false)
  final bool? isRecalled;
  final int? seqId;
  final Map<String, dynamic>? meta;

  SocketMessage({
    required this.id, required this.conversationId, required this.senderId, required this.content,
    required this.type, required this.createdAt, this.sender, this.tempId, this.isSelf, this.seqId, this.meta, this.isRecalled
  });
  factory SocketMessage.fromJson(Map<String, dynamic> json) => _$SocketMessageFromJson(json);
  Map<String, dynamic> toJson() => _$SocketMessageToJson(this);
}

@JsonSerializable(checked: true)
class SocketSender {
  final String id;
  final String nickname;
  final String? avatar;
  SocketSender({required this.id, this.nickname = 'Unknown', this.avatar});
  factory SocketSender.fromJson(Map<String, dynamic> json) => _$SocketSenderFromJson(json);
  Map<String, dynamic> toJson() => _$SocketSenderToJson(this);
}

@JsonSerializable(checked: true)
class MessageMarkReadRequest {
  final String conversationId;
  final int? maxSeqId;
  MessageMarkReadRequest({required this.conversationId, this.maxSeqId});
  Map<String, dynamic> toJson() => _$MessageMarkReadRequestToJson(this);
}

@JsonSerializable(checked: true)
class MessageMarkReadResponse {
  @JsonKey(name: 'unreadCount', defaultValue: 0)
  final int unreadCount;
  final int lastReadSeqId;
  MessageMarkReadResponse({this.unreadCount = 0, required this.lastReadSeqId});
  factory MessageMarkReadResponse.fromJson(Map<String, dynamic> json) => _$MessageMarkReadResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MessageMarkReadResponseToJson(this);
}

@JsonSerializable(checked: true)
class SocketReadEvent {
  final String conversationId;
  final String readerId;
  final bool? isSelf;
  @JsonKey(defaultValue: 0)
  final int lastReadSeqId;
  SocketReadEvent({required this.conversationId, required this.readerId, required this.lastReadSeqId, this.isSelf});
  factory SocketReadEvent.fromJson(Map<String, dynamic> json) => _$SocketReadEventFromJson(json);
}

@JsonSerializable(checked: true)
class MessageRecallRequest {
  final String conversationId;
  final String messageId;
  MessageRecallRequest({required this.conversationId, required this.messageId});
  Map<String, dynamic> toJson() => _$MessageRecallRequestToJson(this);
}

@JsonSerializable(checked: true)
class MessageRecallResponse {
  final String messageId;
  final String tip;
  MessageRecallResponse({required this.messageId, required this.tip});
  factory MessageRecallResponse.fromJson(Map<String, dynamic> json) => _$MessageRecallResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MessageRecallResponseToJson(this);
}

@JsonSerializable(checked: true)
class SocketRecallEvent {
  final String conversationId;
  final String messageId;
  final String tip;
  final String operatorId;
  final int? seqId;
  final bool isSelf;
  SocketRecallEvent({required this.conversationId, required this.messageId, required this.tip, required this.isSelf, required this.operatorId, this.seqId});
  factory SocketRecallEvent.fromJson(Map<String, dynamic> json) => _$SocketRecallEventFromJson(json);
}

@JsonSerializable(checked: true)
class MessageDeleteRequest {
  final String messageId;
  final String conversationId;
  MessageDeleteRequest({required this.messageId, required this.conversationId});
  Map<String, dynamic> toJson() => _$MessageDeleteRequestToJson(this);
}

@JsonSerializable(checked: true)
class MessageDeleteResponse {
  final String messageId;
  MessageDeleteResponse({required this.messageId});
  factory MessageDeleteResponse.fromJson(Map<String, dynamic> json) => _$MessageDeleteResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MessageDeleteResponseToJson(this);
}

@JsonSerializable(checked: true)
class ChatUser {
  final String id;
  final String nickname;
  final String? avatar;
  final String? phone;
  @JsonKey(unknownEnumValue: RelationshipStatus.stranger)
  final RelationshipStatus status;
  ChatUser({required this.id, required this.nickname, this.avatar, this.phone, this.status = RelationshipStatus.stranger});
  factory ChatUser.fromJson(Map<String, dynamic> json) => _$ChatUserFromJson(json);
  Map<String, dynamic> toJson() => _$ChatUserToJson(this);
}

@JsonSerializable(createFactory: false)
class CreateGroupRequest {
  final String name;
  final List<String> memberIds;
  CreateGroupRequest({required this.name, required this.memberIds});
  Map<String, dynamic> toJson() => _$CreateGroupRequestToJson(this);
}

@JsonSerializable(checked: true)
class CreateGroupResponse {
  final String id;
  final String name;
  final String type;
  final String ownerId;
  final int? createdAt;
  CreateGroupResponse({required this.id, required this.name, required this.type, required this.ownerId, this.createdAt});
  factory CreateGroupResponse.fromJson(Map<String, dynamic> json) => _$CreateGroupResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CreateGroupResponseToJson(this);
}

@JsonSerializable(createFactory: true)
class InviteToGroupRequest {
  final String groupId;
  final List<String> memberIds;
  InviteToGroupRequest({required this.groupId, required this.memberIds});
  Map<String, dynamic> toJson() => _$InviteToGroupRequestToJson(this);
}

@JsonSerializable(checked: true)
class InviteToGroupResponse {
  final int count;
  InviteToGroupResponse({required this.count});
  factory InviteToGroupResponse.fromJson(Map<String, dynamic> json) => _$InviteToGroupResponseFromJson(json);
  Map<String, dynamic> toJson() => _$InviteToGroupResponseToJson(this);
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
  factory LeaveGroupResponse.fromJson(Map<String, dynamic> json) => _$LeaveGroupResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LeaveGroupResponseToJson(this);
}

@JsonSerializable(checked: true)
class GroupSearchResult {
  final String id;
  final String name;
  final String? avatar;
  final int memberCount;
  final bool joinNeedApproval;
  final bool isMember;
  GroupSearchResult({required this.id, required this.name, this.avatar, required this.memberCount, required this.joinNeedApproval, required this.isMember});
  factory GroupSearchResult.fromJson(Map<String, dynamic> json) => _$GroupSearchResultFromJson(json);
  Map<String, dynamic> toJson() => _$GroupSearchResultToJson(this);
}