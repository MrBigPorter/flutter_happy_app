// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_list_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductListItem _$ProductListItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ProductListItem',
      json,
      ($checkedConvert) {
        final val = ProductListItem(
          treasureId: $checkedConvert('treasureId', (v) => v as String),
          treasureName: $checkedConvert('treasureName', (v) => v as String?),
          buyQuantityRate: $checkedConvert(
              'buyQuantityRate', (v) => (v as num?)?.toDouble()),
          unitAmount: $checkedConvert(
              'unitAmount', (v) => JsonNumConverter.toDouble(v)),
          marketAmount: $checkedConvert(
              'marketAmount', (v) => JsonNumConverter.toDouble(v)),
          soloAmount: $checkedConvert(
              'soloAmount', (v) => JsonNumConverter.toDouble(v)),
          enableRobot: $checkedConvert('enableRobot', (v) => v as bool?),
          leaderBonusType:
              $checkedConvert('leaderBonusType', (v) => (v as num?)?.toInt()),
          state: $checkedConvert('state', (v) => (v as num?)?.toInt() ?? 1),
          statusTag: $checkedConvert('statusTag', (v) => v as String?),
          categories: $checkedConvert(
              'categories',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
                  .toList()),
          shippingType:
              $checkedConvert('shippingType', (v) => (v as num?)?.toInt()),
          groupSize: $checkedConvert('groupSize', (v) => (v as num?)?.toInt()),
          groupTimeLimit:
              $checkedConvert('groupTimeLimit', (v) => (v as num?)?.toInt()),
          salesStartAt:
              $checkedConvert('salesStartAt', (v) => (v as num?)?.toInt()),
          salesEndAt:
              $checkedConvert('salesEndAt', (v) => (v as num?)?.toInt()),
          bonusConfig:
              $checkedConvert('bonusConfig', (v) => v as Map<String, dynamic>?),
          costAmount: $checkedConvert(
              'costAmount', (v) => JsonNumConverter.toStringOrNull(v)),
          imgStyleType:
              $checkedConvert('imgStyleType', (v) => (v as num?)?.toInt()),
          lotteryMode:
              $checkedConvert('lotteryMode', (v) => (v as num?)?.toInt()),
          lotteryTime:
              $checkedConvert('lotteryTime', (v) => (v as num?)?.toInt()),
          mainImageList: $checkedConvert('mainImageList',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          minBuyQuantity:
              $checkedConvert('minBuyQuantity', (v) => (v as num?)?.toInt()),
          productName: $checkedConvert('productName', (v) => v as String?),
          seqBuyQuantity:
              $checkedConvert('seqBuyQuantity', (v) => (v as num?)?.toInt()),
          seqShelvesQuantity: $checkedConvert(
              'seqShelvesQuantity', (v) => (v as num?)?.toInt()),
          treasureCoverImg:
              $checkedConvert('treasureCoverImg', (v) => v as String?),
          ruleContent: $checkedConvert('ruleContent', (v) => v as String?),
          desc: $checkedConvert('desc', (v) => v as String?),
          maxUnitCoins: $checkedConvert(
              'maxUnitCoins', (v) => JsonNumConverter.toStringOrNull(v)),
          maxUnitAmount: $checkedConvert(
              'maxUnitAmount', (v) => JsonNumConverter.toStringOrNull(v)),
          maxPerBuyQuantity:
              $checkedConvert('maxPerBuyQuantity', (v) => (v as num?)?.toInt()),
          charityAmount: $checkedConvert(
              'charityAmount', (v) => JsonNumConverter.toStringOrNull(v)),
          treasureSeq: $checkedConvert('treasureSeq', (v) => v as String?),
          cashState: $checkedConvert('cashState', (v) => (v as num?)?.toInt()),
          recentJoinAvatars: $checkedConvert('recentJoinAvatars',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          isJoined: $checkedConvert('isJoined', (v) => v as bool?),
        );
        return val;
      },
    );

Map<String, dynamic> _$ProductListItemToJson(ProductListItem instance) =>
    <String, dynamic>{
      'treasureId': instance.treasureId,
      'treasureName': instance.treasureName,
      'isJoined': instance.isJoined,
      'buyQuantityRate': instance.buyQuantityRate,
      'unitAmount': JsonNumConverter.doubleToString(instance.unitAmount),
      'marketAmount': JsonNumConverter.doubleToString(instance.marketAmount),
      'soloAmount': JsonNumConverter.doubleToString(instance.soloAmount),
      'enableRobot': instance.enableRobot,
      'leaderBonusType': instance.leaderBonusType,
      'state': instance.state,
      'statusTag': instance.statusTag,
      'shippingType': instance.shippingType,
      'groupSize': instance.groupSize,
      'groupTimeLimit': instance.groupTimeLimit,
      'salesStartAt': instance.salesStartAt,
      'salesEndAt': instance.salesEndAt,
      'categories': instance.categories,
      'bonusConfig': instance.bonusConfig,
      'costAmount': instance.costAmount,
      'imgStyleType': instance.imgStyleType,
      'lotteryMode': instance.lotteryMode,
      'lotteryTime': instance.lotteryTime,
      'mainImageList': instance.mainImageList,
      'minBuyQuantity': instance.minBuyQuantity,
      'productName': instance.productName,
      'seqBuyQuantity': instance.seqBuyQuantity,
      'seqShelvesQuantity': instance.seqShelvesQuantity,
      'treasureCoverImg': instance.treasureCoverImg,
      'ruleContent': instance.ruleContent,
      'desc': instance.desc,
      'recentJoinAvatars': instance.recentJoinAvatars,
      'maxUnitCoins': instance.maxUnitCoins,
      'maxUnitAmount': instance.maxUnitAmount,
      'maxPerBuyQuantity': instance.maxPerBuyQuantity,
      'charityAmount': instance.charityAmount,
      'treasureSeq': instance.treasureSeq,
      'cashState': instance.cashState,
    };

CategoryItem _$CategoryItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CategoryItem',
      json,
      ($checkedConvert) {
        final val = CategoryItem(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          name: $checkedConvert('name', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$CategoryItemToJson(CategoryItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

TreasureStatusModel _$TreasureStatusModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'TreasureStatusModel',
      json,
      ($checkedConvert) {
        final val = TreasureStatusModel(
          id: $checkedConvert('id', (v) => v as String),
          stock: $checkedConvert('stock', (v) => (v as num).toInt()),
          price: $checkedConvert('price', (v) => JsonNumConverter.toDouble(v)),
          soloPrice:
              $checkedConvert('soloPrice', (v) => JsonNumConverter.toDouble(v)),
          isSoldOut: $checkedConvert('isSoldOut', (v) => v as bool),
          state: $checkedConvert('state', (v) => (v as num).toInt()),
          isExpired: $checkedConvert('isExpired', (v) => v as bool),
          seqBuyQuantity:
              $checkedConvert('seqBuyQuantity', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$TreasureStatusModelToJson(
        TreasureStatusModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'stock': instance.stock,
      'price': JsonNumConverter.doubleToString(instance.price),
      'soloPrice': JsonNumConverter.doubleToString(instance.soloPrice),
      'isSoldOut': instance.isSoldOut,
      'state': instance.state,
      'isExpired': instance.isExpired,
      'seqBuyQuantity': instance.seqBuyQuantity,
    };

GroupItem _$GroupItemFromJson(Map<String, dynamic> json) => $checkedCreate(
      'GroupItem',
      json,
      ($checkedConvert) {
        final val = GroupItem(
          groupId: $checkedConvert('groupId', (v) => v as String),
          joinedNum: $checkedConvert('joinedNum', (v) => (v as num).toInt()),
          leaderUsername: $checkedConvert('leaderUsername', (v) => v as String),
          leaderAvatar: $checkedConvert('leaderAvatar', (v) => v as String),
          luckyWinnersCount:
              $checkedConvert('luckyWinnersCount', (v) => (v as num).toInt()),
          totalWinningTimes:
              $checkedConvert('totalWinningTimes', (v) => (v as num).toInt()),
          users: $checkedConvert(
              'users',
              (v) => (v as List<dynamic>)
                  .map((e) => GroupUser.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$GroupItemToJson(GroupItem instance) => <String, dynamic>{
      'groupId': instance.groupId,
      'joinedNum': instance.joinedNum,
      'leaderUsername': instance.leaderUsername,
      'leaderAvatar': instance.leaderAvatar,
      'luckyWinnersCount': instance.luckyWinnersCount,
      'totalWinningTimes': instance.totalWinningTimes,
      'users': instance.users,
    };

GroupUser _$GroupUserFromJson(Map<String, dynamic> json) => $checkedCreate(
      'GroupUser',
      json,
      ($checkedConvert) {
        final val = GroupUser(
          userId: $checkedConvert('userId', (v) => v as String),
          username: $checkedConvert('username', (v) => v as String),
          avatar: $checkedConvert('avatar', (v) => v as String),
          createdAt: $checkedConvert('createdAt', (v) => (v as num?)?.toInt()),
          leaderUserId: $checkedConvert('leaderUserId', (v) => v as String?),
          leaderUsername:
              $checkedConvert('leaderUsername', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$GroupUserToJson(GroupUser instance) => <String, dynamic>{
      'userId': instance.userId,
      'username': instance.username,
      'avatar': instance.avatar,
      'createdAt': instance.createdAt,
      'leaderUserId': instance.leaderUserId,
      'leaderUsername': instance.leaderUsername,
    };
