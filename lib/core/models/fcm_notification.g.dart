// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fcm_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FcmNotificationDeviceRegisterDto _$FcmNotificationDeviceRegisterDtoFromJson(
  Map<String, dynamic> json,
) =>
    $checkedCreate('FcmNotificationDeviceRegisterDto', json, ($checkedConvert) {
      final val = FcmNotificationDeviceRegisterDto(
        token: $checkedConvert('token', (v) => v as String),
        platform: $checkedConvert('platform', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$FcmNotificationDeviceRegisterDtoToJson(
  FcmNotificationDeviceRegisterDto instance,
) => <String, dynamic>{'token': instance.token, 'platform': instance.platform};
