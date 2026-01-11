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
    expireAt: $checkedConvert('expireAt', (v) => (v as num?)?.toInt() ?? 0),
    updatedAt: $checkedConvert('updatedAt', (v) => v as num? ?? 0),
    createdAt: $checkedConvert('createdAt', (v) => v as num? ?? 0),
    creator: $checkedConvert(
      'creator',
      (v) => GroupUser.fromJson(v as Map<String, dynamic>),
    ),
    members: $checkedConvert(
      'members',
      (v) =>
          (v as List<dynamic>?)
              ?.map((e) => GroupMemberItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
  'expireAt': instance.expireAt,
  'updatedAt': instance.updatedAt,
  'createdAt': instance.createdAt,
  'creator': instance.creator,
  'members': instance.members,
};

GroupUser _$GroupUserFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GroupUser', json, ($checkedConvert) {
      final val = GroupUser(
        userId: $checkedConvert('id', (v) => v as String?),
        nickname: $checkedConvert('nickname', (v) => v as String?),
        avatar: $checkedConvert('avatar', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'userId': 'id'});

Map<String, dynamic> _$GroupUserToJson(GroupUser instance) => <String, dynamic>{
  'id': instance.userId,
  'nickname': instance.nickname,
  'avatar': instance.avatar,
};

GroupMemberItem _$GroupMemberItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GroupMemberItem', json, ($checkedConvert) {
      final val = GroupMemberItem(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        joinedAt: $checkedConvert('joinedAt', (v) => v as num),
        groupId: $checkedConvert('groupId', (v) => v as String?),
        userId: $checkedConvert('userId', (v) => v as String?),
        orderId: $checkedConvert('orderId', (v) => v as String?),
        isOwner: $checkedConvert('isOwner', (v) => (v as num?)?.toInt() ?? 0),
        shareCoin: $checkedConvert('shareCoin', (v) => v as String?),
        shareAmount: $checkedConvert('shareAmount', (v) => v as String?),
        user: $checkedConvert(
          'user',
          (v) =>
              v == null ? null : GroupUser.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GroupMemberItemToJson(GroupMemberItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'joinedAt': instance.joinedAt,
      'groupId': instance.groupId,
      'userId': instance.userId,
      'orderId': instance.orderId,
      'isOwner': instance.isOwner,
      'shareCoin': instance.shareCoin,
      'shareAmount': instance.shareAmount,
      'user': instance.user,
    };

GroupDetailModel _$GroupDetailModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GroupDetailModel', json, ($checkedConvert) {
  final val = GroupDetailModel(
    groupId: $checkedConvert('groupId', (v) => v as String),
    groupStatus: $checkedConvert('groupStatus', (v) => (v as num).toInt()),
    currentMembers: $checkedConvert(
      'currentMembers',
      (v) => (v as num).toInt(),
    ),
    maxMembers: $checkedConvert('maxMembers', (v) => (v as num).toInt()),
    expireAt: $checkedConvert('expireAt', (v) => (v as num?)?.toInt()),
    treasure: $checkedConvert(
      'treasure',
      (v) =>
          v == null ? null : GroupTreasure.fromJson(v as Map<String, dynamic>),
    ),
    members: $checkedConvert(
      'members',
      (v) =>
          (v as List<dynamic>?)
              ?.map((e) => GroupMemberItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    ),
  );
  return val;
});

Map<String, dynamic> _$GroupDetailModelToJson(GroupDetailModel instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'groupStatus': instance.groupStatus,
      'currentMembers': instance.currentMembers,
      'maxMembers': instance.maxMembers,
      'expireAt': instance.expireAt,
      'treasure': instance.treasure,
      'members': instance.members,
    };

GroupTreasure _$GroupTreasureFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GroupTreasure', json, ($checkedConvert) {
      final val = GroupTreasure(
        treasureId: $checkedConvert('treasureId', (v) => v as String),
        treasureName: $checkedConvert('treasureName', (v) => v as String),
        treasureCoverImg: $checkedConvert(
          'treasureCoverImg',
          (v) => v as String,
        ),
      );
      return val;
    });

Map<String, dynamic> _$GroupTreasureToJson(GroupTreasure instance) =>
    <String, dynamic>{
      'treasureId': instance.treasureId,
      'treasureName': instance.treasureName,
      'treasureCoverImg': instance.treasureCoverImg,
    };

HotGroupItem _$HotGroupItemFromJson(Map<String, dynamic> json) => HotGroupItem(
  treasureId: json['treasureId'] as String,
  treasureName: json['treasureName'] as String,
  treasureCoverImg: json['treasureCoverImg'] as String,
  unitAmount: JsonNumConverter.toDouble(json['unitAmount']),
  marketAmount: JsonNumConverter.toDouble(json['marketAmount']),
  buyQuantityRate: (json['buyQuantityRate'] as num).toDouble(),
  stockLeft: (json['stockLeft'] as num).toInt(),
  joinCount: (json['joinCount'] as num).toInt(),
  recentJoinAvatars:
      (json['recentJoinAvatars'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  salesEndAt: (json['salesEndAt'] as num?)?.toInt(),
);

Map<String, dynamic> _$HotGroupItemToJson(HotGroupItem instance) =>
    <String, dynamic>{
      'treasureId': instance.treasureId,
      'treasureName': instance.treasureName,
      'treasureCoverImg': instance.treasureCoverImg,
      'unitAmount': instance.unitAmount,
      'marketAmount': instance.marketAmount,
      'buyQuantityRate': instance.buyQuantityRate,
      'stockLeft': instance.stockLeft,
      'joinCount': instance.joinCount,
      'recentJoinAvatars': instance.recentJoinAvatars,
      'salesEndAt': instance.salesEndAt,
    };
