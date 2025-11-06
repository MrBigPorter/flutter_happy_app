import 'package:json_annotation/json_annotation.dart';

part 'product_list_item.g.dart';

@JsonSerializable(checked: true)
class ProductListItem {
  @JsonKey(name: 'buy_quantity_rate')
  final double buyQuantityRate;
  @JsonKey(name: 'cost_amount')
  final int? costAmount;
  @JsonKey(name: 'img_style_type')
  final int? imgStyleType;
  @JsonKey(name: 'lottery_mode')
  final int? lotteryMode;
  @JsonKey(name: 'lottery_time')
  final int? lotteryTime;
  @JsonKey(name: 'main_image_list')
  final List<String>? mainImageList;
  @JsonKey(name: 'min_buy_quantity')
  final int? minBuyQuantity;
  @JsonKey(name: 'product_name')
  final String productName;
  @JsonKey(name: 'seq_buy_quantity')
  final int? seqBuyQuantity;
  @JsonKey(name: 'seq_shelves_quantity')
  final int? seqShelvesQuantity;
  @JsonKey(name: 'treasure_id')
  final String treasureId;
  @JsonKey(name: 'treasure_name')
  final String treasureName;
  @JsonKey(name: 'unit_amount')
  final int unitAmount;
  @JsonKey(name: 'treasure_cover_img')
  final String? treasureCoverImg;
  @JsonKey(name: 'rate')
  final int? rate;

  @JsonKey(name: 'rule_content')
  final String? ruleContent;

  @JsonKey(name: 'desc')
  final String? desc;

  @JsonKey(name: 'max_unit_coins')
  final int? maxUnitCoins;

  @JsonKey(name: 'max_unit_amount')
  final int? maxUnitAmount;

  @JsonKey(name: 'max_per_buy_quantity')
  final int? maxPerBuyQuantity;

  @JsonKey(name: 'charity_amount')
  final String? charityAmount;

  @JsonKey(name: 'treasure_seq')
  final String? treasureSeq;

  @JsonKey(name: 'cash_state')
  final int? cashState; // 1 普通, 2 现金

  ProductListItem({
    required this.buyQuantityRate,
    required this.costAmount,
    required this.imgStyleType,
    required this.lotteryMode,
    required this.lotteryTime,
    this.mainImageList,
    required this.minBuyQuantity,
    required this.productName,
    required this.seqBuyQuantity,
    required this.seqShelvesQuantity,
    required this.treasureId,
    required this.treasureName,
    required this.unitAmount,
    required this.treasureCoverImg,
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
  String toString() {
    return toJson().toString();
  }
}

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
  @JsonKey(name: 'group_id')
  final String groupId;
  @JsonKey(name: 'joined_num')
  final int joinedNum;
  @JsonKey(name: 'leader_username')
  final String leaderUsername;
  @JsonKey(name: 'leader_avatar')
  final String leaderAvatar;
  @JsonKey(name: 'lucky_winners_count')
  final int luckyWinnersCount;
  @JsonKey(name: 'total_winning_times')
  final int totalWinningTimes;
  @JsonKey(name: 'users')
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
}

@JsonSerializable(checked: true)
class GroupUser {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'username')
  final String username;
  @JsonKey(name: 'avatar')
  final String avatar;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'leader_user_id')
  final String leaderUserId;
  @JsonKey(name: 'leader_username')
  final String leaderUsername;


  GroupUser({
    required this.userId,
    required this.username,
    required this.avatar,
    required this.createdAt,
    required this.leaderUserId,
    required this.leaderUsername,
  });

  factory GroupUser.fromJson(Map<String, dynamic> json) =>
      _$GroupUserFromJson(json);

  Map<String, dynamic> toJson() => _$GroupUserToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
