// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_manage_req.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KickMemberReq _$KickMemberReqFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'KickMemberReq',
      json,
      ($checkedConvert) {
        final val = KickMemberReq(
          conversationId: $checkedConvert('conversationId', (v) => v as String),
          targetUserId: $checkedConvert('targetUserId', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$KickMemberReqToJson(KickMemberReq instance) =>
    <String, dynamic>{
      'conversationId': instance.conversationId,
      'targetUserId': instance.targetUserId,
    };

MuteMemberReq _$MuteMemberReqFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'MuteMemberReq',
      json,
      ($checkedConvert) {
        final val = MuteMemberReq(
          conversationId: $checkedConvert('conversationId', (v) => v as String),
          targetUserId: $checkedConvert('targetUserId', (v) => v as String),
          duration: $checkedConvert('duration', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$MuteMemberReqToJson(MuteMemberReq instance) =>
    <String, dynamic>{
      'conversationId': instance.conversationId,
      'targetUserId': instance.targetUserId,
      'duration': instance.duration,
    };

UpdateGroupInfoReq _$UpdateGroupInfoReqFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'UpdateGroupInfoReq',
      json,
      ($checkedConvert) {
        final val = UpdateGroupInfoReq(
          conversationId: $checkedConvert('conversationId', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String?),
          announcement: $checkedConvert('announcement', (v) => v as String?),
          isMuteAll: $checkedConvert('isMuteAll', (v) => v as bool?),
        );
        return val;
      },
    );

Map<String, dynamic> _$UpdateGroupInfoReqToJson(UpdateGroupInfoReq instance) =>
    <String, dynamic>{
      'conversationId': instance.conversationId,
      'name': instance.name,
      'announcement': instance.announcement,
      'isMuteAll': instance.isMuteAll,
    };

SetAdminRes _$SetAdminResFromJson(Map<String, dynamic> json) => $checkedCreate(
      'SetAdminRes',
      json,
      ($checkedConvert) {
        final val = SetAdminRes(
          success: $checkedConvert('success', (v) => v as bool),
          role: $checkedConvert('role', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$SetAdminResToJson(SetAdminRes instance) =>
    <String, dynamic>{
      'success': instance.success,
      'role': instance.role,
    };

TransferOwnerRes _$TransferOwnerResFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'TransferOwnerRes',
      json,
      ($checkedConvert) {
        final val = TransferOwnerRes(
          success: $checkedConvert('success', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$TransferOwnerResToJson(TransferOwnerRes instance) =>
    <String, dynamic>{
      'success': instance.success,
    };

LeaveGroupRes _$LeaveGroupResFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LeaveGroupRes',
      json,
      ($checkedConvert) {
        final val = LeaveGroupRes(
          success: $checkedConvert('success', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$LeaveGroupResToJson(LeaveGroupRes instance) =>
    <String, dynamic>{
      'success': instance.success,
    };

DisbandGroupRes _$DisbandGroupResFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DisbandGroupRes',
      json,
      ($checkedConvert) {
        final val = DisbandGroupRes(
          success: $checkedConvert('success', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$DisbandGroupResToJson(DisbandGroupRes instance) =>
    <String, dynamic>{
      'success': instance.success,
    };

KickMemberRes _$KickMemberResFromJson(Map<String, dynamic> json) =>
    KickMemberRes(
      success: json['success'] as bool,
      kickedUserId: json['kickedUserId'] as String,
    );

Map<String, dynamic> _$KickMemberResToJson(KickMemberRes instance) =>
    <String, dynamic>{
      'success': instance.success,
      'kickedUserId': instance.kickedUserId,
    };

MuteMemberRes _$MuteMemberResFromJson(Map<String, dynamic> json) =>
    MuteMemberRes(
      success: json['success'] as bool,
      mutedUntil: (json['mutedUntil'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MuteMemberResToJson(MuteMemberRes instance) =>
    <String, dynamic>{
      'success': instance.success,
      'mutedUntil': instance.mutedUntil,
    };

UpdateGroupRes _$UpdateGroupResFromJson(Map<String, dynamic> json) =>
    UpdateGroupRes(
      id: json['id'] as String,
      name: json['name'] as String,
      announcement: json['announcement'] as String?,
      isMuteAll: json['isMuteAll'] as bool,
    );

Map<String, dynamic> _$UpdateGroupResToJson(UpdateGroupRes instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'announcement': instance.announcement,
      'isMuteAll': instance.isMuteAll,
    };
