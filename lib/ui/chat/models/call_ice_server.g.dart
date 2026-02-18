// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_ice_server.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CallIceServer _$CallIceServerFromJson(Map<String, dynamic> json) =>
    CallIceServer(
      urls: json['urls'] as String,
      username: json['username'] as String?,
      credential: json['credential'] as String?,
    );

Map<String, dynamic> _$CallIceServerToJson(CallIceServer instance) =>
    <String, dynamic>{
      'urls': instance.urls,
      'username': instance.username,
      'credential': instance.credential,
    };
