import 'package:json_annotation/json_annotation.dart';

part 'auth.g.dart';

@JsonSerializable(checked: true)
class AuthLoginOtp {
  @JsonKey(name: 'id')
  final String id;
  @JsonKey(name: 'phone')
  final String phone;
  @JsonKey(name: 'phone_md5')
  final String phoneMd5;
  @JsonKey(name: 'nickname')
  final String nickname;
  @JsonKey(name: 'username')
  final String username;
  @JsonKey(name: 'avartar')
  final String? avartar;
  @JsonKey(name: 'country_code')
  final int? countryCode;
  @JsonKey(name: 'tokens')
  final Tokens tokens;

  AuthLoginOtp({
    required this.id,
    required this.phone,
    required this.phoneMd5,
    required this.nickname,
    required this.username,
    this.avartar,
    this.countryCode,
    required this.tokens,
  });


  factory AuthLoginOtp.fromJson(Map<String, dynamic> json) =>
      _$AuthLoginOtpFromJson(json);

  Map<String, dynamic> toJson() => _$AuthLoginOtpToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

@JsonSerializable(checked: true)
class Tokens {
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  Tokens({
    required this.accessToken,
    required this.refreshToken,
  });

  factory Tokens.fromJson(Map<String, dynamic> json) =>
      _$TokensFromJson(json);

  Map<String, dynamic> toJson() => _$TokensToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}


@JsonSerializable(checked: true)
class OtpRequest {
  @JsonKey(name: 'DevCode')
  final String? devCode;

  OtpRequest({
     this.devCode,
  });

  factory OtpRequest.fromJson(Map<String, dynamic> json) =>
      _$OtpRequestFromJson(json);
  Map<String, dynamic> toJson() => _$OtpRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

@JsonSerializable(checked: true)
class Profile {
  @JsonKey(name: 'id')
  final String id;
  @JsonKey(name: 'nickname')
  final String nickname;
  @JsonKey(name: 'avatar')
  final String? avatar;
  @JsonKey(name: 'phone_md5')
  final String phoneMd5;
  @JsonKey(name: 'phone')
  final String phone;
  @JsonKey(name: 'invite_code')
  final String? inviteCode;
  @JsonKey(name: 'vip_level')
  final int? vipLevel;
  @JsonKey(name: 'last_login_at')
  final String lastLoginAt;
  @JsonKey(name: 'kyc_status')
  final int kycStatus;
  @JsonKey(name: 'delivery_address_id')
  final int? deliveryAddressId;
  @JsonKey(name: 'self_exclusion_expire_at')
  final int? selfExclusionExpireAt;

  Profile({
    required this.id,
    required this.nickname,
    this.avatar,
    required this.phoneMd5,
    required this.phone,
    this.inviteCode,
    this.vipLevel,
    required this.lastLoginAt,
    required this.kycStatus,
    this.deliveryAddressId,
    this.selfExclusionExpireAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

class OtpVerifyParams {
  final int phone;
  final String code;

  OtpVerifyParams({
    required this.phone,
    required this.code,
  });
}


