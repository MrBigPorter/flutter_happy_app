
import 'package:json_annotation/json_annotation.dart';

part 'fcm_notification.g.dart';

@JsonSerializable(checked: true)
class FcmNotificationDeviceRegisterDto {
  final String token;
  final String platform; // 'android', 'ios', 'web'

  FcmNotificationDeviceRegisterDto({
    required this.token,
    required this.platform,
  });

  factory FcmNotificationDeviceRegisterDto.fromJson(Map<String, dynamic> json) =>
      _$FcmNotificationDeviceRegisterDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FcmNotificationDeviceRegisterDtoToJson(this);
}