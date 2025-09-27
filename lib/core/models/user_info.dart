import 'package:json_annotation/json_annotation.dart';
part 'user_info.g.dart';

@JsonSerializable(checked: true)
class UserInfo {
  final String id;
  final String nickname;
  final String avatar;
  @JsonKey(name: 'phone_md5')
  final String phoneMd5;
  final String phone;
  @JsonKey(name: 'invite_code')
  final String inviteCode;
  final int vipLevel;
  @JsonKey(name: 'last_login_at')
  final int lastLoginAt;
  @JsonKey(name: 'kyc_status')
  final int? kycStatus;
  @JsonKey(name: 'delivery_address_id')
  final int deliveryAddressId;
  @JsonKey(name: 'self_exclusion_expire_at')
  final int selfExclusionExpireAt;

  UserInfo({
    required this.id,
    required this.nickname,
    required this.avatar,
    required this.phoneMd5,
    required this.phone,
    required this.inviteCode,
    required this.vipLevel,
    required this.lastLoginAt,
    this.kycStatus,
    required this.deliveryAddressId,
    required this.selfExclusionExpireAt,
  });

  // automatically generated json serialization code
  factory UserInfo.fromJson(Map<String, dynamic> json)  => _$UserInfoFromJson(json);
  Map<String, dynamic> toJson() => _$UserInfoToJson(this);
}