// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserInfo _$UserInfoFromJson(Map<String, dynamic> json) => UserInfo(
  id: json['id'] as String,
  nickname: json['nickname'] as String,
  avatar: json['avatar'] as String,
  phoneMd5: json['phoneMd5'] as String,
  phone: json['phone'] as String,
  inviteCode: json['inviteCode'] as String,
  vipLevel: (json['vipLevel'] as num).toInt(),
  lastLoginAt: (json['lastLoginAt'] as num).toInt(),
  kycStatus: (json['kycStatus'] as num?)?.toInt(),
  deliveryAddressId: (json['deliveryAddressId'] as num).toInt(),
  selfExclusionExpireAt: (json['selfExclusionExpireAt'] as num).toInt(),
);

Map<String, dynamic> _$UserInfoToJson(UserInfo instance) => <String, dynamic>{
  'id': instance.id,
  'nickname': instance.nickname,
  'avatar': instance.avatar,
  'phoneMd5': instance.phoneMd5,
  'phone': instance.phone,
  'inviteCode': instance.inviteCode,
  'vipLevel': instance.vipLevel,
  'lastLoginAt': instance.lastLoginAt,
  'kycStatus': instance.kycStatus,
  'deliveryAddressId': instance.deliveryAddressId,
  'selfExclusionExpireAt': instance.selfExclusionExpireAt,
};
