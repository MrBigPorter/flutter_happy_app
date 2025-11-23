import 'package:json_annotation/json_annotation.dart';

part 'auth.g.dart';

@JsonSerializable(checked: true)
class AuthLoginOtp {
  final String id;
  final String phone;
  final String phoneMd5;
  final String nickname;
  final String username;
  final String? avartar;
  final int? countryCode;
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
  final String accessToken;
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
  final String id;
  final String nickname;
  final String? avatar;
  final String phoneMd5;
  final String phone;
  final String? inviteCode;
  final int? vipLevel;
  final String lastLoginAt;
  final int kycStatus;
  final int? deliveryAddressId;
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
  final String phone;
  final String code;

  OtpVerifyParams({
    required this.phone,
    required this.code,
  });
}


