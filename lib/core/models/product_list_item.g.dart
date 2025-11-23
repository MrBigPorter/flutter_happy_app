// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_list_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductListItem _$ProductListItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ProductListItem', json, ($checkedConvert) {
  final val = ProductListItem(
    buyQuantityRate: $checkedConvert(
      'buyQuantityRate',
      (v) => (v as num).toDouble(),
    ),
    costAmount: $checkedConvert('costAmount', (v) => v as String?),
    imgStyleType: $checkedConvert('imgStyleType', (v) => (v as num?)?.toInt()),
    lotteryMode: $checkedConvert('lotteryMode', (v) => (v as num?)?.toInt()),
    lotteryTime: $checkedConvert('lotteryTime', (v) => (v as num?)?.toInt()),
    mainImageList: $checkedConvert(
      'mainImageList',
      (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
    ),
    minBuyQuantity: $checkedConvert(
      'minBuyQuantity',
      (v) => (v as num?)?.toInt(),
    ),
    productName: $checkedConvert('productName', (v) => v as String),
    seqBuyQuantity: $checkedConvert(
      'seqBuyQuantity',
      (v) => (v as num?)?.toInt(),
    ),
    seqShelvesQuantity: $checkedConvert(
      'seqShelvesQuantity',
      (v) => (v as num?)?.toInt(),
    ),
    treasureId: $checkedConvert('treasureId', (v) => v as String),
    treasureName: $checkedConvert('treasureName', (v) => v as String),
    unitAmount: $checkedConvert(
      'unitAmount',
      (v) => JsonNumConverter.toDouble(v),
    ),
    treasureCoverImg: $checkedConvert('treasureCoverImg', (v) => v as String?),
    rate: $checkedConvert('rate', (v) => (v as num?)?.toInt()),
    ruleContent: $checkedConvert('ruleContent', (v) => v as String?),
    desc: $checkedConvert('desc', (v) => v as String?),
    maxUnitCoins: $checkedConvert('maxUnitCoins', (v) => v as String?),
    maxUnitAmount: $checkedConvert('maxUnitAmount', (v) => v as String?),
    maxPerBuyQuantity: $checkedConvert(
      'maxPerBuyQuantity',
      (v) => (v as num?)?.toInt(),
    ),
    charityAmount: $checkedConvert('charityAmount', (v) => v as String?),
    treasureSeq: $checkedConvert('treasureSeq', (v) => v as String?),
    cashState: $checkedConvert('cashState', (v) => (v as num?)?.toInt()),
  );
  return val;
});

Map<String, dynamic> _$ProductListItemToJson(ProductListItem instance) =>
    <String, dynamic>{
      'buyQuantityRate': instance.buyQuantityRate,
      'costAmount': instance.costAmount,
      'imgStyleType': instance.imgStyleType,
      'lotteryMode': instance.lotteryMode,
      'lotteryTime': instance.lotteryTime,
      'mainImageList': instance.mainImageList,
      'minBuyQuantity': instance.minBuyQuantity,
      'productName': instance.productName,
      'seqBuyQuantity': instance.seqBuyQuantity,
      'seqShelvesQuantity': instance.seqShelvesQuantity,
      'treasureId': instance.treasureId,
      'treasureName': instance.treasureName,
      'unitAmount': JsonNumConverter.doubleToString(instance.unitAmount),
      'treasureCoverImg': instance.treasureCoverImg,
      'rate': instance.rate,
      'ruleContent': instance.ruleContent,
      'desc': instance.desc,
      'maxUnitCoins': instance.maxUnitCoins,
      'maxUnitAmount': instance.maxUnitAmount,
      'maxPerBuyQuantity': instance.maxPerBuyQuantity,
      'charityAmount': instance.charityAmount,
      'treasureSeq': instance.treasureSeq,
      'cashState': instance.cashState,
    };

GroupItem _$GroupItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GroupItem', json, ($checkedConvert) {
      final val = GroupItem(
        groupId: $checkedConvert('groupId', (v) => v as String),
        joinedNum: $checkedConvert('joinedNum', (v) => (v as num).toInt()),
        leaderUsername: $checkedConvert('leaderUsername', (v) => v as String),
        leaderAvatar: $checkedConvert('leaderAvatar', (v) => v as String),
        luckyWinnersCount: $checkedConvert(
          'luckyWinnersCount',
          (v) => (v as num).toInt(),
        ),
        totalWinningTimes: $checkedConvert(
          'totalWinningTimes',
          (v) => (v as num).toInt(),
        ),
        users: $checkedConvert(
          'users',
          (v) => (v as List<dynamic>)
              .map((e) => GroupUser.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GroupItemToJson(GroupItem instance) => <String, dynamic>{
  'groupId': instance.groupId,
  'joinedNum': instance.joinedNum,
  'leaderUsername': instance.leaderUsername,
  'leaderAvatar': instance.leaderAvatar,
  'luckyWinnersCount': instance.luckyWinnersCount,
  'totalWinningTimes': instance.totalWinningTimes,
  'users': instance.users,
};

GroupUser _$GroupUserFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GroupUser', json, ($checkedConvert) {
      final val = GroupUser(
        userId: $checkedConvert('userId', (v) => v as String),
        username: $checkedConvert('username', (v) => v as String),
        avatar: $checkedConvert('avatar', (v) => v as String),
        createdAt: $checkedConvert(
          'createdAt',
          (v) => DateTime.parse(v as String),
        ),
        leaderUserId: $checkedConvert('leaderUserId', (v) => v as String),
        leaderUsername: $checkedConvert('leaderUsername', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$GroupUserToJson(GroupUser instance) => <String, dynamic>{
  'userId': instance.userId,
  'username': instance.username,
  'avatar': instance.avatar,
  'createdAt': instance.createdAt.toIso8601String(),
  'leaderUserId': instance.leaderUserId,
  'leaderUsername': instance.leaderUsername,
};
