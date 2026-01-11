import 'package:equatable/equatable.dart';
import 'package:flutter_app/core/models/product_list_item.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../utils/helper.dart';

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
  @JsonKey(defaultValue: 0)
  final int expireAt;

  @JsonKey(defaultValue: 0)
  final num updatedAt;
  @JsonKey(defaultValue: 0)
  final num createdAt;

  final GroupUser creator;

  final GroupTreasure? treasure;

  // 预览成员列表 (后端只返回前几个)
  @JsonKey(defaultValue: [])
  final List<GroupMemberItem> members;

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
    required this.members,
    this.treasure,
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
  @JsonKey(defaultValue: '')
  final String id; // 成员记录ID
  final num joinedAt;

  // 注意：有些轻量级接口可能不返回 groupId/userId 冗余字段，标记为可空更安全
  final String? groupId;
  final String? userId;
  final String? orderId;

  // 1=是团长, 0=不是
  @JsonKey(defaultValue: 0)
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


// ==========================================
// 5. 团详情 (用于 GroupRoomPage 轮询)
// 对应后端接口: GET /groups/:id
// ==========================================
@JsonSerializable(checked: true)
class GroupDetailModel {
  final String groupId;

  // 1-进行中 2-成功 3-失败
  final int groupStatus;

  final int currentMembers;
  final int maxMembers;

  // 后端如果是 Date 对象，Json通常是 ISO String，这里用 DateTime 自动转换
  // 如果后端发的是毫秒时间戳，这里改回 int 即可
  final int? expireAt;

  final GroupTreasure? treasure;

  // 复用上面的 GroupMemberItem，不需要重新定义 GroupMember
  @JsonKey(defaultValue: [])
  final List<GroupMemberItem> members;

  GroupDetailModel({
    required this.groupId,
    required this.groupStatus,
    required this.currentMembers,
    required this.maxMembers,
    this.expireAt,
    required this.treasure,
    required this.members,
  });

  factory GroupDetailModel.fromJson(Map<String, dynamic> json) => _$GroupDetailModelFromJson(json);
  Map<String, dynamic> toJson() => _$GroupDetailModelToJson(this);
}

// ==========================================
// 6. 团详情里的简略商品信息
// ==========================================
@JsonSerializable(checked: true)
class GroupTreasure {
  final String treasureId;
  final String treasureName;
  final String treasureCoverImg;
  @JsonKey(defaultValue: 0.0, fromJson: JsonNumConverter.toDouble)
  final double unitAmount;

  GroupTreasure({
    required this.treasureId,
    required this.treasureName,
    required this.treasureCoverImg,
    required this.unitAmount, // 必填或默认0
  });

  factory GroupTreasure.fromJson(Map<String, dynamic> json) => _$GroupTreasureFromJson(json);
  Map<String, dynamic> toJson() => _$GroupTreasureToJson(this);
}

@JsonSerializable()
class HotGroupItem {
  final String treasureId;
  final String treasureName;
  final String treasureCoverImg;

  // 价格相关
  @JsonKey(fromJson: JsonNumConverter.toDouble)
  final double unitAmount;
  @JsonKey(fromJson: JsonNumConverter.toDouble)
  final double? marketAmount;

  // 进度 & 库存
  final double buyQuantityRate; // 0.0 ~ 1.0
  final int stockLeft;
  final int joinCount;

  // 头像列表，默认为空数组防崩
  @JsonKey(defaultValue: [])
  final List<String> recentJoinAvatars;

  // 倒计时用
  final int? salesEndAt;

  HotGroupItem({
    required this.treasureId,
    required this.treasureName,
    required this.treasureCoverImg,
    required this.unitAmount,
    this.marketAmount,
    required this.buyQuantityRate,
    required this.stockLeft,
    required this.joinCount,
    required this.recentJoinAvatars,
    this.salesEndAt,
  });

  factory HotGroupItem.fromJson(Map<String, dynamic> json) =>
      _$HotGroupItemFromJson(json);

  Map<String, dynamic> toJson() => _$HotGroupItemToJson(this);

  ///  核心适配方法：转成 ProductListItem
  /// 这样你的 GroupBuyingSection 组件就可以直接用了，不用改类型
  ProductListItem toProductListItem() {
    return ProductListItem(
      treasureId: treasureId,
      treasureName: treasureName,
      treasureCoverImg: treasureCoverImg,
      unitAmount: unitAmount,
      marketAmount: marketAmount,

      // 这里的字段名需要根据 ProductListItem 的实际定义来
      // 如果 ProductListItem 里叫 buyQuantityRate 就直接赋值
      buyQuantityRate: buyQuantityRate,

      // 用 stockLeft 和 joinCount 去填充相关字段
      // 如果 ProductListItem 没有 stockLeft，可以用 seqShelvesQuantity 模拟
      seqBuyQuantity: joinCount,

      // 倒计时
      salesEndAt: salesEndAt,
    );
  }
}

