// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthLoginOtp _$AuthLoginOtpFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'AuthLoginOtp',
  json,
  ($checkedConvert) {
    final val = AuthLoginOtp(
      id: $checkedConvert('id', (v) => v as String),
      phone: $checkedConvert('phone', (v) => v as String),
      phoneMd5: $checkedConvert('phone_md5', (v) => v as String),
      nickname: $checkedConvert('nickname', (v) => v as String),
      username: $checkedConvert('username', (v) => v as String),
      avartar: $checkedConvert('avartar', (v) => v as String?),
      countryCode: $checkedConvert('country_code', (v) => (v as num?)?.toInt()),
      tokens: $checkedConvert(
        'tokens',
        (v) => Tokens.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'phoneMd5': 'phone_md5', 'countryCode': 'country_code'},
);

Map<String, dynamic> _$AuthLoginOtpToJson(AuthLoginOtp instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phone': instance.phone,
      'phone_md5': instance.phoneMd5,
      'nickname': instance.nickname,
      'username': instance.username,
      'avartar': instance.avartar,
      'country_code': instance.countryCode,
      'tokens': instance.tokens,
    };

Tokens _$TokensFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Tokens',
  json,
  ($checkedConvert) {
    final val = Tokens(
      accessToken: $checkedConvert('access_token', (v) => v as String),
      refreshToken: $checkedConvert('refresh_token', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'accessToken': 'access_token',
    'refreshToken': 'refresh_token',
  },
);

Map<String, dynamic> _$TokensToJson(Tokens instance) => <String, dynamic>{
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
};

OtpRequest _$OtpRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OtpRequest', json, ($checkedConvert) {
      final val = OtpRequest(
        devCode: $checkedConvert('DevCode', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'devCode': 'DevCode'});

Map<String, dynamic> _$OtpRequestToJson(OtpRequest instance) =>
    <String, dynamic>{'DevCode': instance.devCode};

Profile _$ProfileFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Profile',
  json,
  ($checkedConvert) {
    final val = Profile(
      id: $checkedConvert('id', (v) => v as String),
      nickname: $checkedConvert('nickname', (v) => v as String),
      avatar: $checkedConvert('avatar', (v) => v as String?),
      phoneMd5: $checkedConvert('phone_md5', (v) => v as String),
      phone: $checkedConvert('phone', (v) => v as String),
      inviteCode: $checkedConvert('invite_code', (v) => v as String?),
      vipLevel: $checkedConvert('vip_level', (v) => (v as num?)?.toInt()),
      lastLoginAt: $checkedConvert('last_login_at', (v) => v as String),
      kycStatus: $checkedConvert('kyc_status', (v) => (v as num).toInt()),
      deliveryAddressId: $checkedConvert(
        'delivery_address_id',
        (v) => (v as num?)?.toInt(),
      ),
      selfExclusionExpireAt: $checkedConvert(
        'self_exclusion_expire_at',
        (v) => (v as num?)?.toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'phoneMd5': 'phone_md5',
    'inviteCode': 'invite_code',
    'vipLevel': 'vip_level',
    'lastLoginAt': 'last_login_at',
    'kycStatus': 'kyc_status',
    'deliveryAddressId': 'delivery_address_id',
    'selfExclusionExpireAt': 'self_exclusion_expire_at',
  },
);

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
  'id': instance.id,
  'nickname': instance.nickname,
  'avatar': instance.avatar,
  'phone_md5': instance.phoneMd5,
  'phone': instance.phone,
  'invite_code': instance.inviteCode,
  'vip_level': instance.vipLevel,
  'last_login_at': instance.lastLoginAt,
  'kyc_status': instance.kycStatus,
  'delivery_address_id': instance.deliveryAddressId,
  'self_exclusion_expire_at': instance.selfExclusionExpireAt,
};
