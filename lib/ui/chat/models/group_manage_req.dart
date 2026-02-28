import 'package:json_annotation/json_annotation.dart';
import 'conversation.dart'; // Ensure ChatUser is defined here

part 'group_manage_req.g.dart';

// ==========================================================================
// 1. REQUESTS (Parameters sent to backend) -> toJson only
// ==========================================================================

@JsonSerializable(createFactory: false)
class KickMemberReq {
  final String conversationId;
  final String targetUserId;

  KickMemberReq({required this.conversationId, required this.targetUserId});
  Map<String, dynamic> toJson() => _$KickMemberReqToJson(this);
}

@JsonSerializable(createFactory: false)
class MuteMemberReq {
  final String conversationId;
  final String targetUserId;
  final int duration; // In seconds

  MuteMemberReq({
    required this.conversationId,
    required this.targetUserId,
    required this.duration,
  });
  Map<String, dynamic> toJson() => _$MuteMemberReqToJson(this);
}

@JsonSerializable(createFactory: false)
class UpdateGroupInfoReq {
  final String conversationId;
  final String? name;
  final String? announcement;
  final bool? isMuteAll;
  final bool? joinNeedApproval;
  final String? avatar;

  UpdateGroupInfoReq({
    required this.conversationId,
    this.name,
    this.announcement,
    this.isMuteAll,
    this.joinNeedApproval,
    this.avatar,
  });
  Map<String, dynamic> toJson() => _$UpdateGroupInfoReqToJson(this);
}

@JsonSerializable(createFactory: false)
class TransferOwnerReq {
  final String conversationId;
  final String newOwnerId;

  TransferOwnerReq({required this.conversationId, required this.newOwnerId});
  Map<String, dynamic> toJson() => _$TransferOwnerReqToJson(this);
}

@JsonSerializable(createFactory: false)
class SetAdminReq {
  final String conversationId;
  final String targetUserId;
  final bool isAdmin;

  SetAdminReq({
    required this.conversationId,
    required this.targetUserId,
    required this.isAdmin,
  });
  Map<String, dynamic> toJson() => _$SetAdminReqToJson(this);
}

@JsonSerializable(createFactory: false)
class ApplyToGroupReq {
  final String conversationId;
  final String? reason;

  ApplyToGroupReq({required this.conversationId, this.reason});
  Map<String, dynamic> toJson() => _$ApplyToGroupReqToJson(this);
}

@JsonSerializable(createFactory: false)
class HandleGroupJoinReq {
  final String requestId;
  final String action; // Expected values: 'accept' | 'reject'

  HandleGroupJoinReq({required this.requestId, required this.action});
  Map<String, dynamic> toJson() => _$HandleGroupJoinReqToJson(this);
}

// ==========================================================================
// 2. RESPONSES (Data returned by backend) -> fromJson only
// ==========================================================================

@JsonSerializable(createToJson: false)
class KickMemberRes {
  final bool success;
  final String kickedUserId;

  KickMemberRes({required this.success, required this.kickedUserId});
  factory KickMemberRes.fromJson(Map<String, dynamic> json) => _$KickMemberResFromJson(json);
}

@JsonSerializable(createToJson: false)
class MuteMemberRes {
  final bool success;
  final int? mutedUntil;

  MuteMemberRes({required this.success, this.mutedUntil});
  factory MuteMemberRes.fromJson(Map<String, dynamic> json) => _$MuteMemberResFromJson(json);
}

@JsonSerializable(createToJson: false)
class UpdateGroupRes {
  final String id;
  final String name;
  final String? announcement;
  final bool isMuteAll;
  final String? avatar;
  final bool? joinNeedApproval;

  UpdateGroupRes({
    required this.id,
    required this.name,
    this.announcement,
    required this.isMuteAll,
    this.avatar,
    this.joinNeedApproval,
  });
  factory UpdateGroupRes.fromJson(Map<String, dynamic> json) => _$UpdateGroupResFromJson(json);
}

@JsonSerializable(createToJson: false)
class SetAdminRes {
  final bool success;
  final String role; // Standard values: "ADMIN" | "MEMBER"

  SetAdminRes({required this.success, required this.role});
  factory SetAdminRes.fromJson(Map<String, dynamic> json) => _$SetAdminResFromJson(json);
}

@JsonSerializable(createToJson: false)
class ApplyToGroupRes {
  final String status; // Expected states: 'PENDING' | 'ACCEPTED'
  final String? requestId;
  final String? message;

  ApplyToGroupRes({required this.status, this.requestId, this.message});
  factory ApplyToGroupRes.fromJson(Map<String, dynamic> json) => _$ApplyToGroupResFromJson(json);
}

@JsonSerializable(createToJson: false)
class SimpleSuccessRes {
  final bool success;
  SimpleSuccessRes({required this.success});
  factory SimpleSuccessRes.fromJson(Map<String, dynamic> json) => _$SimpleSuccessResFromJson(json);
}

// ==========================================================================
// 3. ENTITIES (List items and data objects) -> fromJson only
// ==========================================================================

enum GroupRequestStatus {
  @JsonValue(0) pending,
  @JsonValue(1) accepted,
  @JsonValue(2) rejected;
}

@JsonSerializable(createToJson: false)
class GroupJoinRequestItem {
  final String id;
  final String reason;
  final GroupRequestStatus status;
  final int createdAt;

  // Nested user entity for the applicant
  final ChatUser applicant;

  GroupJoinRequestItem({
    required this.id,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.applicant,
  });

  factory GroupJoinRequestItem.fromJson(Map<String, dynamic> json) =>
      _$GroupJoinRequestItemFromJson(json);
}