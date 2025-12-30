import 'package:json_annotation/json_annotation.dart';
import '../json/json_num_converters.dart';

part 'product_list_item.g.dart';


@JsonSerializable(checked: true)
class ProductListItem {
  // --- 核心字段 ---
  final String treasureId;
  final String treasureName;

  // ✨ 后端返回的是 0~100 的保留两位小数的 double
  final double buyQuantityRate;

  @JsonKey(name: 'unitAmount', fromJson: JsonNumConverter.toDouble, toJson: JsonNumConverter.doubleToString)
  final double unitAmount;

  // --- 业务字段 ---
  final int? shippingType;    // 1-实物, 2-电子券
  final int? groupSize;       // 团购人数
  final int? groupTimeLimit;
  final int? salesStartAt;    // 时间戳 (ms)
  final int? salesEndAt;      // 时间戳 (ms)

  // ✨ 列表接口返回的拍平后的分类信息
  final List<CategoryItem>? categories;

  final Map<String, dynamic>? bonusConfig;

  // --- 详情/可选字段 ---
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
  final String? maxUnitCoins;
  final String? maxUnitAmount;
  final int? maxPerBuyQuantity;
  final String? charityAmount;
  final String? treasureSeq;
  final int? cashState;

  ProductListItem({
    required this.treasureId,
    required this.treasureName,
    required this.buyQuantityRate,
    required this.unitAmount,
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
  });

  factory ProductListItem.fromJson(Map<String, dynamic> json) =>
      _$ProductListItemFromJson(json);

  Map<String, dynamic> toJson() => _$ProductListItemToJson(this);
}

// ✨ 新增：分类简单模型
@JsonSerializable(checked: true)
class CategoryItem {
  final String id;
  final String name;

  CategoryItem({required this.id, required this.name});

  factory CategoryItem.fromJson(Map<String, dynamic> json) =>
      _$CategoryItemFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryItemToJson(this);
}

// --- 分页包装类 (建议加上，方便接口解析) ---
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