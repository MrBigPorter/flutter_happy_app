import 'package:json_annotation/json_annotation.dart';

part 'friend_request.g.dart';

@JsonSerializable()
class FriendRequest {
  final String id; // UserID of the applicant
  final String nickname;
  final String? avatar;

  // Unix timestamp (milliseconds) from the backend
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

  /// Helper getter to convert raw timestamp into a Dart DateTime object
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(requestTime);
}

// ==========================================
// 1. Friend Request Initiation
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
// 2. Friend Request Handling (Accept/Reject)
// ==========================================

/// Defines available actions for responding to a friend request
enum FriendRequestAction {
  pending(0),  // Default placeholder state
  accepted(1), // Approve request
  rejected(2); // Decline request

  final int value;
  const FriendRequestAction(this.value);
}

class HandleFriendRequest {
  final String targetId;
  final FriendRequestAction action; // Use enum to ensure type safety for API calls

  HandleFriendRequest({
    required this.targetId,
    required this.action,
  });

  /// Manual mapping to match the backend's HandleContactDto requirements
  Map<String, dynamic> toJson() {
    return {
      'targetId': targetId,
      'accept': action.value, // Backend 'accept' field expects an integer
    };
  }
}