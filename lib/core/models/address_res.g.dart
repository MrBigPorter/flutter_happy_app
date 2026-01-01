// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_res.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressRes _$AddressResFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AddressRes', json, ($checkedConvert) {
      final val = AddressRes(
        addressId: $checkedConvert('addressId', (v) => v as String),
        phone: $checkedConvert('phone', (v) => v as String),
        city: $checkedConvert('city', (v) => v as String),
        postalCode: $checkedConvert('postalCode', (v) => v as String),
        fullAddress: $checkedConvert('fullAddress', (v) => v as String),
        isDefault: $checkedConvert('isDefault', (v) => (v as num).toInt()),
        firstName: $checkedConvert('firstName', (v) => v as String?),
        middleName: $checkedConvert('middleName', (v) => v as String?),
        lastName: $checkedConvert('lastName', (v) => v as String?),
        contactName: $checkedConvert('contactName', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AddressResToJson(AddressRes instance) =>
    <String, dynamic>{
      'addressId': instance.addressId,
      'phone': instance.phone,
      'city': instance.city,
      'postalCode': instance.postalCode,
      'fullAddress': instance.fullAddress,
      'isDefault': instance.isDefault,
      'firstName': instance.firstName,
      'middleName': instance.middleName,
      'contactName': instance.contactName,
      'lastName': instance.lastName,
    };
