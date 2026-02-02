// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FriendRequest _$FriendRequestFromJson(Map<String, dynamic> json) =>
    FriendRequest(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      avatar: json['avatar'] as String?,
      requestTime: (json['requestTime'] as num).toInt(),
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$FriendRequestToJson(FriendRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nickname': instance.nickname,
      'avatar': instance.avatar,
      'requestTime': instance.requestTime,
      'reason': instance.reason,
    };

AddFriendRequest _$AddFriendRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AddFriendRequest',
      json,
      ($checkedConvert) {
        final val = AddFriendRequest(
          friendId: $checkedConvert('friendId', (v) => v as String),
          reason: $checkedConvert('reason', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$AddFriendRequestToJson(AddFriendRequest instance) =>
    <String, dynamic>{
      'friendId': instance.friendId,
      'reason': instance.reason,
    };
