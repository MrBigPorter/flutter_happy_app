import 'package:json_annotation/json_annotation.dart';

part 'address_res.g.dart';

@JsonSerializable(checked: true)
class AddressRes {
  final String addressId;
  final String? contactName;
  final String phone;

  // --- 区域名称 (列表展示用) ---
  final String province;
  final String city;
  final String barangay;

  // --- 区域 ID (编辑回填用) ---
  final int provinceId;
  final int cityId;
  final int barangayId;

  final String fullAddress;
  final String postalCode;

  final String? label;
  final int isDefault;

  const AddressRes({
    required this.addressId,
    this.contactName,
    required this.phone,
    required this.province,
    required this.city,
    required this.barangay,
    required this.provinceId,
    required this.cityId,
    required this.barangayId,
    required this.fullAddress,
    required this.postalCode,
    this.label,
    required this.isDefault,
  });

  factory AddressRes.fromJson(Map<String, dynamic> json) => _$AddressResFromJson(json);
  Map<String, dynamic> toJson() => _$AddressResToJson(this);
}

/// 用于提交表单
@JsonSerializable(checked: true)
class AddressCreateDto {
  // 核心字段
  final String contactName;
  final String phone;

  final int provinceId;
  final int cityId;
  final int barangayId;

  final String fullAddress;
  final String? postalCode;
  final String? label;
  final int isDefault;

  // 这里的 firstName/lastName 如果后端完全废弃了，前端也可以不传
  // 如果后端 DTO 里是 Optional，这里留着也没事
  final String? firstName;
  final String? lastName;

  const AddressCreateDto({
    required this.contactName,
    required this.phone,
    required this.provinceId,
    required this.cityId,
    required this.barangayId,
    required this.fullAddress,
    this.postalCode = '',
    this.label,
    required this.isDefault,
    this.firstName,
    this.lastName,
  });

  factory AddressCreateDto.fromJson(Map<String, dynamic> json) => _$AddressCreateDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AddressCreateDtoToJson(this);
}

