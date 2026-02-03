import 'package:json_annotation/json_annotation.dart';

part 'user_info.g.dart';

@JsonSerializable(checked: true) // 关键：自动处理 snake_case 转 camelCase
class UserInfo {
  final String id;

  // 后端有兜底逻辑 `ms${id}`，所以这里定义为非空
  final String nickname;

  final String? avatar;

  final String phoneMd5;

  final String phone;

  // 数据库和后端代码显示 inviteCode 可能为 null
  final String? inviteCode;

  final int vipLevel;

  // 对应 Prisma 的 kycStatus，默认 0
  final int kycStatus;

  // 注意：后端返回的是 deliveryAddress_id (带下划线且是 int 0)
  // Prisma 定义的是 String? 类型的 deliveryAddressId，这里建议按照后端 API 返回的来
  final int deliveryAddressId;

  // 时间戳在 Flutter 中通常用 int 接收
  final int selfExclusionExpireAt;

  // 新增：后端返回了 lastLoginAt 时间戳
  final int? lastLoginAt;

  UserInfo({
    required this.id,
    required this.nickname,
    this.avatar,
    required this.phoneMd5,
    required this.phone,
    this.inviteCode,
    required this.vipLevel,
    required this.kycStatus,
    required this.deliveryAddressId,
    required this.selfExclusionExpireAt,
    this.lastLoginAt,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => _$UserInfoFromJson(json);
  Map<String, dynamic> toJson() => _$UserInfoToJson(this);

  @override
  String toString() {
     return toJson().toString();
  }
}