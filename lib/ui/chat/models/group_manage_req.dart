
import 'package:json_annotation/json_annotation.dart';

import 'conversation.dart';

part 'group_manage_req.g.dart';

@JsonSerializable(checked: true)
class KickMemberReq {
  final String conversationId;
  final String targetUserId;

  KickMemberReq({
    required this.conversationId,
    required this.targetUserId,
  });

  Map<String, dynamic> toJson() => _$KickMemberReqToJson(this);
}

@JsonSerializable(checked: true)
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

@JsonSerializable(checked: true)
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

@JsonSerializable(checked: true)
class SetAdminRes {
  final bool success;

  // 后端返回的是字符串 "ADMIN" 或 "MEMBER"
  final String role;

  SetAdminRes({
    required this.success,
    required this.role,
  });

  factory SetAdminRes.fromJson(Map<String, dynamic> json) =>
      _$SetAdminResFromJson(json);

  Map<String, dynamic> toJson() => _$SetAdminResToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}


@JsonSerializable(checked: true)
class TransferOwnerRes {
  final bool success;

  TransferOwnerRes({required this.success});

  factory TransferOwnerRes.fromJson(Map<String, dynamic> json) =>
      _$TransferOwnerResFromJson(json);

  Map<String, dynamic> toJson() => _$TransferOwnerResToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}


@JsonSerializable(checked: true)
class LeaveGroupRes {
  final bool success;

  LeaveGroupRes({required this.success});

  factory LeaveGroupRes.fromJson(Map<String, dynamic> json) =>
      _$LeaveGroupResFromJson(json);

  Map <String, dynamic> toJson() => _$LeaveGroupResToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}


@JsonSerializable(checked: true)
class DisbandGroupRes {
  final bool success;

  DisbandGroupRes({required this.success});

  factory DisbandGroupRes.fromJson(Map<String, dynamic> json) =>
      _$DisbandGroupResFromJson(json);

  Map <String, dynamic> toJson() => _$DisbandGroupResToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

@JsonSerializable()
class KickMemberRes {
  final bool success;
  final String kickedUserId;

  KickMemberRes({required this.success, required this.kickedUserId});

  factory KickMemberRes.fromJson(Map<String, dynamic> json) => _$KickMemberResFromJson(json);
}

@JsonSerializable()
class MuteMemberRes {
  final bool success;
  final int? mutedUntil;

  MuteMemberRes({required this.success, this.mutedUntil});

  factory MuteMemberRes.fromJson(Map<String, dynamic> json) => _$MuteMemberResFromJson(json);
}

@JsonSerializable()
class UpdateGroupRes {
  final String id;
  final String name;
  final String? announcement;
  final bool isMuteAll;
  final String? avatar;
  final bool? joinNeedApproval;

  UpdateGroupRes({required this.id, required this.name, this.announcement, required this.isMuteAll, this.avatar, this.joinNeedApproval});

  factory UpdateGroupRes.fromJson(Map<String, dynamic> json) => _$UpdateGroupResFromJson(json);
}

// 1. 提交申请 Payload
@JsonSerializable(createFactory: false)
class ApplyToGroupReq {
  final String conversationId; // 对应后端的 groupId
  final String? reason;

  ApplyToGroupReq({required this.conversationId, this.reason});

  Map<String, dynamic> toJson() => _$ApplyToGroupReqToJson(this);
}

// 2. 提交申请后的 Response (对应后端的 ApplyToGroupResDto)
@JsonSerializable(createFactory: true)
class ApplyToGroupRes {
  final String status; // 'PENDING' | 'ACCEPTED'
  final String? requestId;
  final String? message;

  ApplyToGroupRes({required this.status, this.requestId, this.message});

  factory ApplyToGroupRes.fromJson(Map<String, dynamic> json) =>
      _$ApplyToGroupResFromJson(json);
}

// 3. 审批操作 Payload
@JsonSerializable(createFactory: false)
class HandleGroupJoinReq {
  final String requestId;
  final String action; // 'accept' | 'reject'

  HandleGroupJoinReq({required this.requestId, required this.action});

  Map<String, dynamic> toJson() => _$HandleGroupJoinReqToJson(this);
}

enum GroupRequestStatus {
  @JsonValue(0) pending,
  @JsonValue(1) accepted,
  @JsonValue(2) rejected;
}

@JsonSerializable()
class GroupJoinRequest {
  final String id;
  final String groupId;
  final ChatUser applicant; // 包含申请人的头像、昵称和 ID
  final String reason;
  final GroupRequestStatus status;
  final int createdAt;

  GroupJoinRequest({
    required this.id,
    required this.groupId,
    required this.applicant,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory GroupJoinRequest.fromJson(Map<String, dynamic> json) =>
      _$GroupJoinRequestFromJson(json);
}

