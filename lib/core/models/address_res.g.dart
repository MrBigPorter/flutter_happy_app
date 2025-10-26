// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_res.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressRes _$AddressResFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AddressRes',
  json,
  ($checkedConvert) {
    final val = AddressRes(
      addressId: $checkedConvert('address_id', (v) => v as String),
      phone: $checkedConvert('phone', (v) => v as String),
      city: $checkedConvert('city', (v) => v as String),
      postalCode: $checkedConvert('postal_code', (v) => v as String),
      fullAddress: $checkedConvert('full_address', (v) => v as String),
      isDefault: $checkedConvert('is_default', (v) => v as String),
      firstName: $checkedConvert('first_name', (v) => v as String),
      middleName: $checkedConvert('middle_name', (v) => v as String),
      lastName: $checkedConvert('last_name', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'addressId': 'address_id',
    'postalCode': 'postal_code',
    'fullAddress': 'full_address',
    'isDefault': 'is_default',
    'firstName': 'first_name',
    'middleName': 'middle_name',
    'lastName': 'last_name',
  },
);

Map<String, dynamic> _$AddressResToJson(AddressRes instance) =>
    <String, dynamic>{
      'address_id': instance.addressId,
      'phone': instance.phone,
      'city': instance.city,
      'postal_code': instance.postalCode,
      'full_address': instance.fullAddress,
      'is_default': instance.isDefault,
      'first_name': instance.firstName,
      'middle_name': instance.middleName,
      'last_name': instance.lastName,
    };
