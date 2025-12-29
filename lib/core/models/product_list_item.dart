import 'package:json_annotation/json_annotation.dart';
import '../json/json_num_converters.dart';

part 'product_list_item.g.dart';

@JsonSerializable(checked: true)
class ProductListItem {
  // --- 核心字段 (建议保持必填) ---
  final String treasureId;
  final String treasureName;
  final double buyQuantityRate;

  @JsonKey(name: 'unitAmount', fromJson: JsonNumConverter.toDouble, toJson: JsonNumConverter.doubleToString)
  final double unitAmount;

  // --- 详情/可选字段 (建议全部设为可空，防止后端数据不完整导致崩溃) ---
  final String? costAmount;
  final int? imgStyleType;
  final int? lotteryMode;
  final int? lotteryTime;
  final List<String>? mainImageList;
  final int? minBuyQuantity;
  final String? productName;
  final int? seqBuyQuantity;
  final int? seqShelvesQuantity;
  final String? treasureCoverImg;
  final int? rate;
  final String? ruleContent;
  final String? desc;
  final String? maxUnitCoins;
  final String? maxUnitAmount;
  final int? maxPerBuyQuantity;
  final String? charityAmount;
  final String? treasureSeq;
  final int? cashState; // 1 普通, 2 现金

  ProductListItem({
    required this.treasureId,
    required this.treasureName,
    required this.buyQuantityRate,
    required this.unitAmount,
    this.costAmount,
    this.imgStyleType,
    this.lotteryMode,
    this.lotteryTime,
    this.mainImageList,
    this.minBuyQuantity,
    this.productName,
    this.seqBuyQuantity,
    this.seqShelvesQuantity,
    this.treasureCoverImg,
    this.rate,
    this.ruleContent,
    this.desc,
    this.maxUnitCoins,
    this.maxUnitAmount,
    this.maxPerBuyQuantity,
    this.charityAmount,
    this.treasureSeq,
    this.cashState,
  });

  factory ProductListItem.fromJson(Map<String, dynamic> json) =>
      _$ProductListItemFromJson(json);

  Map<String, dynamic> toJson() => _$ProductListItemToJson(this);

  @override
  String toString() => toJson().toString();
}

// 分页参数保持不变
class ProductListParams {
  final int categoryId;
  final int page;
  final int pageSize;

  ProductListParams({
    required this.categoryId,
    required this.page,
    required this.pageSize,
  });
}

@JsonSerializable(checked: true)
class GroupItem {
  final String groupId;
  final int joinedNum;
  final String leaderUsername;
  final String leaderAvatar;
  final int luckyWinnersCount;
  final int totalWinningTimes;
  final List<GroupUser> users;

  GroupItem({
    required this.groupId,
    required this.joinedNum,
    required this.leaderUsername,
    required this.leaderAvatar,
    required this.luckyWinnersCount,
    required this.totalWinningTimes,
    required this.users,
  });

  factory GroupItem.fromJson(Map<String, dynamic> json) =>
      _$GroupItemFromJson(json);

  Map<String, dynamic> toJson() => _$GroupItemToJson(this);
}

@JsonSerializable(checked: true)
class GroupUser {
  final String userId;
  final String username;
  final String avatar;

  final int? createdAt;

  final String? leaderUserId; // 增加可空标识，防止非团员查询时报错
  final String? leaderUsername;

  GroupUser({
    required this.userId,
    required this.username,
    required this.avatar,
    this.createdAt,
    this.leaderUserId,
    this.leaderUsername,
  });

  factory GroupUser.fromJson(Map<String, dynamic> json) =>
      _$GroupUserFromJson(json);

  Map<String, dynamic> toJson() => _$GroupUserToJson(this);

  @override
  String toString() => toJson().toString();
}