
import 'package:json_annotation/json_annotation.dart';

part 'sys_config.g.dart';
@JsonSerializable(checked: true)
class SysConfig {
  final String kycAndPhoneVerification;
  final String webBaseUrl;
  final double exChangeRate;

  SysConfig({required this.kycAndPhoneVerification, required this.webBaseUrl, required this.exChangeRate});

  factory SysConfig.fromJson(Map<String, dynamic> json) => _$SysConfigFromJson(json);
  Map<String, dynamic> toJson() => _$SysConfigToJson(this);
  @override
  String toString() {
    return toJson().toString();
  }

}