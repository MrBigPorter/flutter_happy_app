import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'groups.g.dart';

// ==========================================
// 1. 团购列表项 (用于首页/详情页 "正在拼团" 列表)
// ==========================================
@JsonSerializable(checked: true)
class GroupForTreasureItem {
  final String groupId;
  final String treasureId;

  // 状态: 1-进行中, 2-成功, 3-失败
  final int groupStatus;

  final int currentMembers;
  final int maxMembers;

  // 新增：过期时间戳 (毫秒)，倒计时全靠它
  final int expireAt;

  final num updatedAt;
  final num createdAt;

  final GroupUser creator;

  // 预览成员列表 (后端只返回前几个)
  final List<GroupMemberItem>? members;

  GroupForTreasureItem({
    required this.groupId,
    required this.treasureId,
    required this.groupStatus,
    required this.currentMembers,
    required this.maxMembers,
    required this.expireAt, // 必填
    required this.updatedAt,
    required this.createdAt,
    required this.creator,
    this.members,
  });

  factory GroupForTreasureItem.fromJson(Map<String, dynamic> json) => _$GroupForTreasureItemFromJson(json);
  Map<String, dynamic> toJson() => _$GroupForTreasureItemToJson(this);

  // --- UI 辅助方法 ---

  // 是否已满
  bool get isFull => currentMembers >= maxMembers;

  // 是否拼团成功
  bool get isSuccess => groupStatus == 2;

  // 剩余毫秒数 (用于倒计时组件初始化)
  int get remainingMillis {
    final now = DateTime.now().millisecondsSinceEpoch;
    final left = expireAt - now;
    return left > 0 ? left : 0;
  }
}

// ==========================================
// 2. 基础用户对象 (嵌套在团或成员里)
// ==========================================
@JsonSerializable(checked: true)
class GroupUser {
  // 🔥 映射修正：Prisma 返回的是 id，这里映射给 userId
  @JsonKey(name: 'id')
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
}

// ==========================================
// 3. 团成员详情 (用于团购等待室/成员列表)
// ==========================================
@JsonSerializable(checked: true)
class GroupMemberItem {
  final String id; // 成员记录ID
  final num joinedAt;

  // 注意：有些轻量级接口可能不返回 groupId/userId 冗余字段，标记为可空更安全
  final String? groupId;
  final String? userId;
  final String? orderId;

  // 1=是团长, 0=不是
  final int isOwner;

  // 后端 Decimal 转成了 String
  final String? shareCoin;
  final String? shareAmount;

  final GroupUser? user;

  GroupMemberItem({
    required this.id,
    required this.joinedAt,
    this.groupId,
    this.userId,
    this.orderId,
    required this.isOwner,
    this.shareCoin,
    this.shareAmount,
    this.user,
  });

  factory GroupMemberItem.fromJson(Map<String, dynamic> json) => _$GroupMemberItemFromJson(json);
  Map<String, dynamic> toJson() => _$GroupMemberItemToJson(this);

  // --- UI 辅助 ---
  bool get isLeader => isOwner == 1;
}

// ==========================================
// 4. 请求参数 (Request Params)
// ==========================================

// 获取正在拼团列表的参数
class GroupsListRequestParams extends Equatable {
  final int page;
  final int pageSize; // 修改为必填，给个默认值逻辑在 Service 层处理
  final String treasureId;

  const GroupsListRequestParams({
    required this.page,
    required this.treasureId,
    this.pageSize = 10,
  });

  // 转成 Map 给 Dio 用
  Map<String, dynamic> toJson() => {
    'page': page,
    'pageSize': pageSize,
    'treasureId': treasureId,
  };

  @override
  List<Object?> get props => [page, pageSize, treasureId];
}

// 获取团成员列表的参数
class GroupMemberListRequestParams extends Equatable {
  final String groupId;
  final int page;
  final int pageSize;

  const GroupMemberListRequestParams({
    required this.groupId,
    required this.page,
    required this.pageSize,
  });

  Map<String, dynamic> toJson() => {
    'page': page,
    'pageSize': pageSize,
    // groupId 通常放在 path 里 (/groups/:id/members)，不放在 query 参数里
    // 如果你的 API 设计是放在 query 里，则保留
  };

  @override
  List<Object?> get props => [groupId, page, pageSize];
}