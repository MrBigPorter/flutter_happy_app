import 'package:json_annotation/json_annotation.dart';
import '../json/json_num_converters.dart';

part 'product_list_item.g.dart';

@JsonSerializable(checked: true)
class ProductListItem {
  // --- 核心字段 ---
  final String treasureId;
  final String? treasureName; // 改为可空更稳妥
  final bool? isJoined; // 新增字段：当前用户是否已参与

  // 0~100 保留两位小数
  final double? buyQuantityRate;

  @JsonKey(name: 'unitAmount', fromJson: JsonNumConverter.toDouble, toJson: JsonNumConverter.doubleToString)
  final double? unitAmount; // 拼团价

  //  [新增] 价格体系字段
  @JsonKey(name: 'marketAmount', fromJson: JsonNumConverter.toDouble, toJson: JsonNumConverter.doubleToString)
  final double? marketAmount; // 划线价

  @JsonKey(name: 'soloAmount', fromJson: JsonNumConverter.toDouble, toJson: JsonNumConverter.doubleToString)
  final double? soloAmount;   // 单买价

  //  [新增] 自动化与奖励
  final bool? enableRobot;
  final int? leaderBonusType;

  // 🚨 详情页用它判断是否下架
  @JsonKey(defaultValue: 1)
  final int state;

  final String? statusTag;

  // --- 业务字段 ---
  final int? shippingType;
  final int? groupSize;
  final int? groupTimeLimit;
  final int? salesStartAt;
  final int? salesEndAt;

  final List<CategoryItem>? categories;
  final Map<String, dynamic>? bonusConfig;

  // --- 详情/可选字段 ---
  @JsonKey(fromJson: JsonNumConverter.toStringOrNull)
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
  final String? ruleContent;
  final String? desc;
  final List<String>? recentJoinAvatars;

  @JsonKey(fromJson: JsonNumConverter.toStringOrNull)
  final String? maxUnitCoins;

  @JsonKey(fromJson: JsonNumConverter.toStringOrNull)
  final String? maxUnitAmount;

  final int? maxPerBuyQuantity;

  @JsonKey(fromJson: JsonNumConverter.toStringOrNull)
  final String? charityAmount;

  final String? treasureSeq;
  final int? cashState;

  ProductListItem({
    required this.treasureId,
    this.treasureName,
    this.buyQuantityRate,
    this.unitAmount,

    this.marketAmount, // New
    this.soloAmount,   // New
    this.enableRobot,  // New
    this.leaderBonusType, // New

    this.state = 1,
    this.statusTag,
    this.categories,
    this.shippingType,
    this.groupSize,
    this.groupTimeLimit,
    this.salesStartAt,
    this.salesEndAt,
    this.bonusConfig,
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
    this.ruleContent,
    this.desc,
    this.maxUnitCoins,
    this.maxUnitAmount,
    this.maxPerBuyQuantity,
    this.charityAmount,
    this.treasureSeq,
    this.cashState,
    this.recentJoinAvatars,
    this.isJoined,
  });

  factory ProductListItem.fromJson(Map<String, dynamic> json) =>
      _$ProductListItemFromJson(json);

  Map<String, dynamic> toJson() => _$ProductListItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

// 分类模型
@JsonSerializable(checked: true)
class CategoryItem {
  final int id;
  final String name;

  CategoryItem({required this.id, required this.name});

  factory CategoryItem.fromJson(Map<String, dynamic> json) =>
      _$CategoryItemFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryItemToJson(this);
}

// 分页包装类
class TreasureListResponse {
  final int page;
  final int pageSize;
  final int total;
  final List<ProductListItem> list;

  TreasureListResponse({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.list,
  });

  factory TreasureListResponse.fromJson(Map<String, dynamic> json) {
    return TreasureListResponse(
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      total: json['total'] as int,
      list: (json['list'] as List<dynamic>)
          .map((e) => ProductListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// 查询参数
class ProductListParams {
  final int? categoryId;
  final int page;
  final int pageSize;
  final String? q;
  final String? filterType;

  ProductListParams({
    this.categoryId,
    required this.page,
    required this.pageSize,
    this.q,
    this.filterType,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'page': page,
      'pageSize': pageSize,
    };
    if (categoryId != null) data['categoryId'] = categoryId;
    if (q != null) data['q'] = q;
    if (filterType != null) data['filterType'] = filterType;
    return data;
  }
}

// 实时状态模型 (下单页轮询用)
@JsonSerializable(checked: true)
class TreasureStatusModel {
  final String id;
  final int stock;

  @JsonKey(fromJson: JsonNumConverter.toDouble, toJson: JsonNumConverter.doubleToString)
  final double price; // 拼团价

  @JsonKey(fromJson: JsonNumConverter.toDouble, toJson: JsonNumConverter.doubleToString)
  final double? soloPrice;

  final bool isSoldOut;
  final int state;
  final bool isExpired;
  final int? seqBuyQuantity;

  TreasureStatusModel({
    required this.id,
    required this.stock,
    required this.price,
    this.soloPrice, // New
    required this.isSoldOut,
    required this.state,
    required this.isExpired,
    this.seqBuyQuantity,
  });

  factory TreasureStatusModel.fromJson(Map<String, dynamic> json) =>
      _$TreasureStatusModelFromJson(json);

  Map<String, dynamic> toJson() => _$TreasureStatusModelToJson(this);

  @override
  String toString() => toJson().toString();
}

// GroupItem 和 GroupUser 保持不变
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
  final String? leaderUserId;
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
}