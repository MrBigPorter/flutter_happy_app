// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserInfo _$UserInfoFromJson(Map<String, dynamic> json) => $checkedCreate(
      'UserInfo',
      json,
      ($checkedConvert) {
        final val = UserInfo(
          id: $checkedConvert('id', (v) => v as String),
          nickname: $checkedConvert('nickname', (v) => v as String),
          avatar: $checkedConvert('avatar', (v) => v as String?),
          phoneMd5: $checkedConvert('phoneMd5', (v) => v as String),
          phone: $checkedConvert('phone', (v) => v as String),
          inviteCode: $checkedConvert('inviteCode', (v) => v as String?),
          vipLevel: $checkedConvert('vipLevel', (v) => (v as num).toInt()),
          kycStatus: $checkedConvert('kycStatus', (v) => (v as num).toInt()),
          deliveryAddressId:
              $checkedConvert('deliveryAddressId', (v) => (v as num).toInt()),
          selfExclusionExpireAt: $checkedConvert(
              'selfExclusionExpireAt', (v) => (v as num).toInt()),
          lastLoginAt:
              $checkedConvert('lastLoginAt', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$UserInfoToJson(UserInfo instance) => <String, dynamic>{
      'id': instance.id,
      'nickname': instance.nickname,
      'avatar': instance.avatar,
      'phoneMd5': instance.phoneMd5,
      'phone': instance.phone,
      'inviteCode': instance.inviteCode,
      'vipLevel': instance.vipLevel,
      'kycStatus': instance.kycStatus,
      'deliveryAddressId': instance.deliveryAddressId,
      'selfExclusionExpireAt': instance.selfExclusionExpireAt,
      'lastLoginAt': instance.lastLoginAt,
    };
