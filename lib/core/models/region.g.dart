// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'region.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Province _$ProvinceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Province', json, ($checkedConvert) {
      final val = Province(
        provinceId: $checkedConvert('provinceId', (v) => (v as num).toInt()),
        provinceName: $checkedConvert('provinceName', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ProvinceToJson(Province instance) => <String, dynamic>{
  'provinceId': instance.provinceId,
  'provinceName': instance.provinceName,
};

City _$CityFromJson(Map<String, dynamic> json) =>
    $checkedCreate('City', json, ($checkedConvert) {
      final val = City(
        cityId: $checkedConvert('cityId', (v) => (v as num).toInt()),
        cityName: $checkedConvert('cityName', (v) => v as String),
        postalCode: $checkedConvert('postalCode', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$CityToJson(City instance) => <String, dynamic>{
  'cityId': instance.cityId,
  'cityName': instance.cityName,
  'postalCode': instance.postalCode,
};

Barangay _$BarangayFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Barangay', json, ($checkedConvert) {
      final val = Barangay(
        barangayId: $checkedConvert('barangayId', (v) => (v as num).toInt()),
        barangayName: $checkedConvert('barangayName', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$BarangayToJson(Barangay instance) => <String, dynamic>{
  'barangayId': instance.barangayId,
  'barangayName': instance.barangayName,
};
