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
      avatar: $checkedConvert('avatar', (v) => v as String),
      phoneMd5: $checkedConvert('phone_md5', (v) => v as String),
      phone: $checkedConvert('phone', (v) => v as String),
      inviteCode: $checkedConvert('invite_code', (v) => v as String),
      vipLevel: $checkedConvert('vipLevel', (v) => (v as num).toInt()),
      lastLoginAt: $checkedConvert('last_login_at', (v) => (v as num).toInt()),
      kycStatus: $checkedConvert('kyc_status', (v) => (v as num?)?.toInt()),
      deliveryAddressId: $checkedConvert(
        'delivery_address_id',
        (v) => (v as num).toInt(),
      ),
      selfExclusionExpireAt: $checkedConvert(
        'self_exclusion_expire_at',
        (v) => (v as num).toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'phoneMd5': 'phone_md5',
    'inviteCode': 'invite_code',
    'lastLoginAt': 'last_login_at',
    'kycStatus': 'kyc_status',
    'deliveryAddressId': 'delivery_address_id',
    'selfExclusionExpireAt': 'self_exclusion_expire_at',
  },
);

Map<String, dynamic> _$UserInfoToJson(UserInfo instance) => <String, dynamic>{
  'id': instance.id,
  'nickname': instance.nickname,
  'avatar': instance.avatar,
  'phone_md5': instance.phoneMd5,
  'phone': instance.phone,
  'invite_code': instance.inviteCode,
  'vipLevel': instance.vipLevel,
  'last_login_at': instance.lastLoginAt,
  'kyc_status': instance.kycStatus,
  'delivery_address_id': instance.deliveryAddressId,
  'self_exclusion_expire_at': instance.selfExclusionExpireAt,
};
