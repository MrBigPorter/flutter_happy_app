// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'groups.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupForTreasureItem _$GroupForTreasureItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GroupForTreasureItem', json, ($checkedConvert) {
  final val = GroupForTreasureItem(
    groupId: $checkedConvert('groupId', (v) => v as String),
    treasureId: $checkedConvert('treasureId', (v) => v as String),
    groupStatus: $checkedConvert('groupStatus', (v) => (v as num).toInt()),
    currentMembers: $checkedConvert(
      'currentMembers',
      (v) => (v as num).toInt(),
    ),
    maxMembers: $checkedConvert('maxMembers', (v) => (v as num).toInt()),
    updatedAt: $checkedConvert('updatedAt', (v) => v as String),
    creator: $checkedConvert(
      'creator',
      (v) => GroupUser.fromJson(v as Map<String, dynamic>),
    ),
    members: $checkedConvert(
      'members',
      (v) => (v as List<dynamic>?)
          ?.map((e) => GroupMemberPreview.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$GroupForTreasureItemToJson(
  GroupForTreasureItem instance,
) => <String, dynamic>{
  'groupId': instance.groupId,
  'treasureId': instance.treasureId,
  'groupStatus': instance.groupStatus,
  'currentMembers': instance.currentMembers,
  'maxMembers': instance.maxMembers,
  'updatedAt': instance.updatedAt,
  'creator': instance.creator,
  'members': instance.members,
};

GroupMemberPreview _$GroupMemberPreviewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GroupMemberPreview', json, ($checkedConvert) {
      final val = GroupMemberPreview(
        isOwner: $checkedConvert('isOwner', (v) => (v as num).toInt()),
        joinedAt: $checkedConvert('joinedAt', (v) => v as String),
        user: $checkedConvert(
          'user',
          (v) =>
              v == null ? null : GroupUser.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GroupMemberPreviewToJson(GroupMemberPreview instance) =>
    <String, dynamic>{
      'isOwner': instance.isOwner,
      'joinedAt': instance.joinedAt,
      'user': instance.user,
    };

GroupUser _$GroupUserFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GroupUser', json, ($checkedConvert) {
      final val = GroupUser(
        userId: $checkedConvert('userId', (v) => v as String?),
        nickname: $checkedConvert('nickname', (v) => v as String?),
        avatar: $checkedConvert('avatar', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$GroupUserToJson(GroupUser instance) => <String, dynamic>{
  'userId': instance.userId,
  'nickname': instance.nickname,
  'avatar': instance.avatar,
};
