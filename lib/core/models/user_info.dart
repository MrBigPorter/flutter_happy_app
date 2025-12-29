import 'package:json_annotation/json_annotation.dart';
part 'user_info.g.dart';

@JsonSerializable(checked: true)
class UserInfo {
  final String id;
  final String nickname;
  final String avatar;
  final String phoneMd5;
  final String phone;
  final String inviteCode;
  final int vipLevel;
  final int? kycStatus;
  final int deliveryAddressId;
  final int selfExclusionExpireAt;

  UserInfo({
    required this.id,
    required this.nickname,
    required this.avatar,
    required this.phoneMd5,
    required this.phone,
    required this.inviteCode,
    required this.vipLevel,
    this.kycStatus,
    required this.deliveryAddressId,
    required this.selfExclusionExpireAt,
  });

  // automatically generated json serialization code
  factory UserInfo.fromJson(Map<String, dynamic> json)  => _$UserInfoFromJson(json);
  Map<String, dynamic> toJson() => _$UserInfoToJson(this);
}