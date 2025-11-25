import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'groups.g.dart';

@JsonSerializable(checked: true)
class GroupForTreasureItem {
  final String groupId;
  final String treasureId;
  final int groupStatus;
  final int currentMembers;
  final int maxMembers;
  final num updatedAt;

  final GroupUser creator;
  final List<GroupMemberPreview>? members;

  GroupForTreasureItem({
    required this.groupId,
    required this.treasureId,
    required this.groupStatus,
    required this.currentMembers,
    required this.maxMembers,
    required this.updatedAt,
    required this.creator,
     this.members,
  });

  factory GroupForTreasureItem.fromJson(Map<String, dynamic> json) => _$GroupForTreasureItemFromJson(json);
  Map<String, dynamic> toJson() => _$GroupForTreasureItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

@JsonSerializable(checked: true)
class GroupMemberPreview {
  final int isOwner;
  final num joinedAt;
  final GroupUser? user;
  GroupMemberPreview({
    required this.isOwner,
    required this.joinedAt,
     this.user,
  });

  factory GroupMemberPreview.fromJson(Map<String, dynamic> json) => _$GroupMemberPreviewFromJson(json);
  Map<String, dynamic> toJson() => _$GroupMemberPreviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

@JsonSerializable(checked: true)
class GroupUser {
  final String? userId;
  final String? nickname;
  final String? avatar;

  GroupUser({
     this.userId,
    this.nickname,
    this.avatar,
  });

  factory GroupUser.fromJson(Map<String, dynamic> json) => _$GroupUserFromJson(json);
  Map<String, dynamic> toJson() => _$GroupUserToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

@JsonSerializable(checked: true)
class GroupMemberItem {
  final String id;
  final num joinedAt;
  final num createdAt;
  final String groupId;
  final String userId;
  final String? orderId;

  final int isOwner;
  final String shareCoin;
  final String shareAmount;

  final GroupUser? user;

  GroupMemberItem({
    required this.id,
    required this.joinedAt,
    required this.createdAt,
    required this.groupId,
    required this.userId,
    this.orderId,
    required this.isOwner,
    required this.shareCoin,
    required this.shareAmount,
    this.user,
  });

  factory GroupMemberItem.fromJson(Map<String, dynamic> json) => _$GroupMemberItemFromJson(json);
  Map<String, dynamic> toJson() => _$GroupMemberItemToJson(this);
  @override
  String toString() {
    return toJson().toString();
  }
}


class GroupsListRequestParams extends Equatable {
  final int page;
  final int? pageSize;
  final String treasureId;

  const GroupsListRequestParams({
    required this.page,
    required this.treasureId,
    this.pageSize =6
  });

  @override
  List<Object?> get props => [page, pageSize, treasureId];
}

