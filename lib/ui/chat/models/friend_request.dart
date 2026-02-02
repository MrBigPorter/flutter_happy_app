import 'package:json_annotation/json_annotation.dart';

part 'friend_request.g.dart';

@JsonSerializable()
class FriendRequest {
  final String id; // 申请人的 UserID
  final String nickname;
  final String? avatar;

  // 后端返回的是 timestamp (number)，Dart 转为 int
  final int requestTime;

  final String? reason;

  FriendRequest({
    required this.id,
    required this.nickname,
    this.avatar,
    required this.requestTime,
    this.reason,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) => _$FriendRequestFromJson(json);
  Map<String, dynamic> toJson() => _$FriendRequestToJson(this);

  // 辅助 getter：格式化时间
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(requestTime);
}

// ==========================================
// 1. 发起好友申请
// ==========================================
@JsonSerializable(checked: true)
class AddFriendRequest {
  final String friendId;
  final String? reason;

  AddFriendRequest({
    required this.friendId,
    this.reason,
  });

  factory AddFriendRequest.fromJson(Map<String, dynamic> json) => _$AddFriendRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AddFriendRequestToJson(this);

}

// ==========================================
// 2. 处理好友申请 (同意/拒绝)
// ==========================================

// 定义枚举，防止传错数字
enum FriendRequestAction {
  pending(0),  // 占位，通常不用传
  accepted(1), // 同意
  rejected(2); // 拒绝

  final int value;
  const FriendRequestAction(this.value);
}

class HandleFriendRequest {
  final String targetId;
  final FriendRequestAction action; // 使用枚举保证安全

  HandleFriendRequest({
    required this.targetId,
    required this.action,
  });

  Map<String, dynamic> toJson() {
    return {
      'targetId': targetId,
      'accept': action.value, // 后端 HandleContactDto 里的 accept 是 int
    };
  }
}