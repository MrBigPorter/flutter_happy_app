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
          addressId: $checkedConvert('addressId', (v) => v as String),
          contactName: $checkedConvert('contactName', (v) => v as String?),
          phone: $checkedConvert('phone', (v) => v as String),
          province: $checkedConvert('province', (v) => v as String),
          city: $checkedConvert('city', (v) => v as String),
          barangay: $checkedConvert('barangay', (v) => v as String),
          provinceId: $checkedConvert('provinceId', (v) => (v as num).toInt()),
          cityId: $checkedConvert('cityId', (v) => (v as num).toInt()),
          barangayId: $checkedConvert('barangayId', (v) => (v as num).toInt()),
          fullAddress: $checkedConvert('fullAddress', (v) => v as String),
          postalCode: $checkedConvert('postalCode', (v) => v as String),
          label: $checkedConvert('label', (v) => v as String?),
          isDefault: $checkedConvert('isDefault', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$AddressResToJson(AddressRes instance) =>
    <String, dynamic>{
      'addressId': instance.addressId,
      'contactName': instance.contactName,
      'phone': instance.phone,
      'province': instance.province,
      'city': instance.city,
      'barangay': instance.barangay,
      'provinceId': instance.provinceId,
      'cityId': instance.cityId,
      'barangayId': instance.barangayId,
      'fullAddress': instance.fullAddress,
      'postalCode': instance.postalCode,
      'label': instance.label,
      'isDefault': instance.isDefault,
    };

AddressCreateDto _$AddressCreateDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AddressCreateDto',
      json,
      ($checkedConvert) {
        final val = AddressCreateDto(
          contactName: $checkedConvert('contactName', (v) => v as String),
          phone: $checkedConvert('phone', (v) => v as String),
          provinceId: $checkedConvert('provinceId', (v) => (v as num).toInt()),
          cityId: $checkedConvert('cityId', (v) => (v as num).toInt()),
          barangayId: $checkedConvert('barangayId', (v) => (v as num).toInt()),
          fullAddress: $checkedConvert('fullAddress', (v) => v as String),
          postalCode: $checkedConvert('postalCode', (v) => v as String? ?? ''),
          label: $checkedConvert('label', (v) => v as String?),
          isDefault: $checkedConvert('isDefault', (v) => (v as num).toInt()),
          firstName: $checkedConvert('firstName', (v) => v as String?),
          lastName: $checkedConvert('lastName', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$AddressCreateDtoToJson(AddressCreateDto instance) =>
    <String, dynamic>{
      'contactName': instance.contactName,
      'phone': instance.phone,
      'provinceId': instance.provinceId,
      'cityId': instance.cityId,
      'barangayId': instance.barangayId,
      'fullAddress': instance.fullAddress,
      'postalCode': instance.postalCode,
      'label': instance.label,
      'isDefault': instance.isDefault,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
    };
