import 'package:json_annotation/json_annotation.dart';

part 'region.g.dart';

@JsonSerializable(checked: true)
class Province {
  final int provinceId;
  final String provinceName;

  Province({
    required this.provinceId,
    required this.provinceName,
  });

  factory Province.fromJson(Map<String, dynamic> json) =>
      _$ProvinceFromJson(json);

  Map<String, dynamic> toJson() => _$ProvinceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

@JsonSerializable(checked: true)
class City {
  final int cityId;
  final String cityName;
  final String postalCode;
  City({
    required this.cityId,
    required this.cityName,
    required this.postalCode,
  });
  factory City.fromJson(Map<String, dynamic> json) => _$CityFromJson(json);
  Map<String, dynamic> toJson() => _$CityToJson(this);
  @override
  String toString() {
    return toJson().toString();
  }
}

@JsonSerializable(checked: true)
class Barangay{
  final int barangayId;
  final String barangayName;
  Barangay({
    required this.barangayId,
    required this.barangayName,
  });
  factory Barangay.fromJson(Map<String, dynamic> json) => _$BarangayFromJson(json);
  Map<String, dynamic> toJson() => _$BarangayToJson(this);
  @override
  String toString() {
    return toJson().toString();
  }
}