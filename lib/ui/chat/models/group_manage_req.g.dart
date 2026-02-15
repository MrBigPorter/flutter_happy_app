// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_manage_req.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$KickMemberReqToJson(KickMemberReq instance) =>
    <String, dynamic>{
      'conversationId': instance.conversationId,
      'targetUserId': instance.targetUserId,
    };

Map<String, dynamic> _$MuteMemberReqToJson(MuteMemberReq instance) =>
    <String, dynamic>{
      'conversationId': instance.conversationId,
      'targetUserId': instance.targetUserId,
      'duration': instance.duration,
    };

Map<String, dynamic> _$UpdateGroupInfoReqToJson(UpdateGroupInfoReq instance) =>
    <String, dynamic>{
      'conversationId': instance.conversationId,
      'name': instance.name,
      'announcement': instance.announcement,
      'isMuteAll': instance.isMuteAll,
      'joinNeedApproval': instance.joinNeedApproval,
      'avatar': instance.avatar,
    };

Map<String, dynamic> _$TransferOwnerReqToJson(TransferOwnerReq instance) =>
    <String, dynamic>{
      'conversationId': instance.conversationId,
      'newOwnerId': instance.newOwnerId,
    };

Map<String, dynamic> _$SetAdminReqToJson(SetAdminReq instance) =>
    <String, dynamic>{
      'conversationId': instance.conversationId,
      'targetUserId': instance.targetUserId,
      'isAdmin': instance.isAdmin,
    };

Map<String, dynamic> _$ApplyToGroupReqToJson(ApplyToGroupReq instance) =>
    <String, dynamic>{
      'conversationId': instance.conversationId,
      'reason': instance.reason,
    };

Map<String, dynamic> _$HandleGroupJoinReqToJson(HandleGroupJoinReq instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'action': instance.action,
    };

KickMemberRes _$KickMemberResFromJson(Map<String, dynamic> json) =>
    KickMemberRes(
      success: json['success'] as bool,
      kickedUserId: json['kickedUserId'] as String,
    );

MuteMemberRes _$MuteMemberResFromJson(Map<String, dynamic> json) =>
    MuteMemberRes(
      success: json['success'] as bool,
      mutedUntil: (json['mutedUntil'] as num?)?.toInt(),
    );

UpdateGroupRes _$UpdateGroupResFromJson(Map<String, dynamic> json) =>
    UpdateGroupRes(
      id: json['id'] as String,
      name: json['name'] as String,
      announcement: json['announcement'] as String?,
      isMuteAll: json['isMuteAll'] as bool,
      avatar: json['avatar'] as String?,
      joinNeedApproval: json['joinNeedApproval'] as bool?,
    );

SetAdminRes _$SetAdminResFromJson(Map<String, dynamic> json) => SetAdminRes(
      success: json['success'] as bool,
      role: json['role'] as String,
    );

ApplyToGroupRes _$ApplyToGroupResFromJson(Map<String, dynamic> json) =>
    ApplyToGroupRes(
      status: json['status'] as String,
      requestId: json['requestId'] as String?,
      message: json['message'] as String?,
    );

SimpleSuccessRes _$SimpleSuccessResFromJson(Map<String, dynamic> json) =>
    SimpleSuccessRes(
      success: json['success'] as bool,
    );

GroupJoinRequestItem _$GroupJoinRequestItemFromJson(
        Map<String, dynamic> json) =>
    GroupJoinRequestItem(
      id: json['id'] as String,
      reason: json['reason'] as String,
      status: $enumDecode(_$GroupRequestStatusEnumMap, json['status']),
      createdAt: (json['createdAt'] as num).toInt(),
      applicant: ChatUser.fromJson(json['applicant'] as Map<String, dynamic>),
    );

const _$GroupRequestStatusEnumMap = {
  GroupRequestStatus.pending: 0,
  GroupRequestStatus.accepted: 1,
  GroupRequestStatus.rejected: 2,
};
