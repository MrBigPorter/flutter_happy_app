
import 'package:json_annotation/json_annotation.dart';

part 'address_res.g.dart';

@JsonSerializable(checked: true)
class AddressRes {
  @JsonKey(name: 'address_id')
  final String addressId;
  @JsonKey(name: 'phone')
  final String phone;
  @JsonKey(name: 'city')
  final String city;
  @JsonKey(name: 'postal_code')
  final String postalCode;
  @JsonKey(name: 'full_address')
  final String fullAddress;
  @JsonKey(name: 'is_default')
  final String isDefault;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'middle_name')
  final String middleName;
  @JsonKey(name: 'last_name')
  final String lastName;


  const AddressRes({
    required this.addressId,
    required this.phone,
    required this.city,
    required this.postalCode,
    required this.fullAddress,
    required this.isDefault,
    required this.firstName,
    required this.middleName,
    required this.lastName,
  });

  factory AddressRes.fromJson(Map<String, dynamic> json) => _$AddressResFromJson(json);
  Map<String, dynamic> toJson() => _$AddressResToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}