
import 'package:json_annotation/json_annotation.dart';

part 'address_res.g.dart';

@JsonSerializable(checked: true)
class AddressRes {
  final String addressId;
  final String phone;
  final String city;
  final String postalCode;
  final String fullAddress;
  final String isDefault;
  final String firstName;
  final String middleName;
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