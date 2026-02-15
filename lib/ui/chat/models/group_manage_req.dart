import 'package:json_annotation/json_annotation.dart';
import 'conversation.dart'; // 确保这里面有 ChatUser 定义

part 'group_manage_req.g.dart';

// ==========================================================================
// 1. REQUESTS (发送给后端的请求参数) -> 只需要 toJson
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
  final int duration; // 秒

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

// 申请入群 Request
@JsonSerializable(createFactory: false)
class ApplyToGroupReq {
  final String conversationId;
  final String? reason;

  ApplyToGroupReq({required this.conversationId, this.reason});
  Map<String, dynamic> toJson() => _$ApplyToGroupReqToJson(this);
}

// 审批处理 Request
@JsonSerializable(createFactory: false)
class HandleGroupJoinReq {
  final String requestId;
  final String action; // 'accept' | 'reject'

  HandleGroupJoinReq({required this.requestId, required this.action});
  Map<String, dynamic> toJson() => _$HandleGroupJoinReqToJson(this);
}

// ==========================================================================
// 2. RESPONSES (后端返回的操作结果) -> 只需要 fromJson
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

  // 刚才后端的 DTO 似乎没返回这两个，以防万一设为可选
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
  final String role; // "ADMIN" | "MEMBER"

  SetAdminRes({required this.success, required this.role});
  factory SetAdminRes.fromJson(Map<String, dynamic> json) => _$SetAdminResFromJson(json);
}

@JsonSerializable(createToJson: false)
class ApplyToGroupRes {
  final String status; // 'PENDING' | 'ACCEPTED'
  final String? requestId;
  final String? message;

  ApplyToGroupRes({required this.status, this.requestId, this.message});
  factory ApplyToGroupRes.fromJson(Map<String, dynamic> json) => _$ApplyToGroupResFromJson(json);
}

// 通用 Boolean 响应 (用于 Leave, Disband, TransferOwner 等只返回 success 的接口)
@JsonSerializable(createToJson: false)
class SimpleSuccessRes {
  final bool success;
  SimpleSuccessRes({required this.success});
  factory SimpleSuccessRes.fromJson(Map<String, dynamic> json) => _$SimpleSuccessResFromJson(json);
}

// ==========================================================================
// 3. ENTITIES (列表数据项) -> 只需要 fromJson
// ==========================================================================

enum GroupRequestStatus {
  @JsonValue(0) pending,
  @JsonValue(1) accepted,
  @JsonValue(2) rejected;
}

@JsonSerializable(createToJson: false)
class GroupJoinRequestItem { // 改名 Item 避免和“发送请求”混淆
  final String id;

  final String reason;
  final GroupRequestStatus status;

  final int createdAt;

  // 嵌套对象
  final ChatUser applicant;

  GroupJoinRequestItem({
    required this.id,
    // required this.groupId,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.applicant,
  });

  factory GroupJoinRequestItem.fromJson(Map<String, dynamic> json) =>
      _$GroupJoinRequestItemFromJson(json);
}