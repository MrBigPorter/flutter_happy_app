
import 'package:json_annotation/json_annotation.dart';

import '../json/json_num_converters.dart';

part 'product_list_item.g.dart';

@JsonSerializable(checked: true)
class ProductListItem {
  final double buyQuantityRate;
  final String? costAmount;
  final int? imgStyleType;
  final int? lotteryMode;
  final int? lotteryTime;
  final List<String>? mainImageList;
  final int? minBuyQuantity;
  final String? productName;
  final int? seqBuyQuantity;
  final int? seqShelvesQuantity;
  final String treasureId;
  final String treasureName;

  @JsonKey(name: 'unitAmount', fromJson:JsonNumConverter.toDouble , toJson: JsonNumConverter.doubleToString)
  final double unitAmount;
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
}

@JsonSerializable(checked: true)
class GroupUser {
  final String userId;
  final String username;
  final String avatar;
  final DateTime createdAt;
  final String leaderUserId;
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
