// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_list_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductListItem _$ProductListItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ProductListItem',
  json,
  ($checkedConvert) {
    final val = ProductListItem(
      buyQuantityRate: $checkedConvert(
        'buy_quantity_rate',
        (v) => (v as num).toDouble(),
      ),
      costAmount: $checkedConvert('cost_amount', (v) => (v as num?)?.toInt()),
      imgStyleType: $checkedConvert(
        'img_style_type',
        (v) => (v as num?)?.toInt(),
      ),
      lotteryMode: $checkedConvert('lottery_mode', (v) => (v as num?)?.toInt()),
      lotteryTime: $checkedConvert('lottery_time', (v) => (v as num?)?.toInt()),
      mainImageList: $checkedConvert(
        'main_image_list',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      minBuyQuantity: $checkedConvert(
        'min_buy_quantity',
        (v) => (v as num?)?.toInt(),
      ),
      productName: $checkedConvert('product_name', (v) => v as String),
      seqBuyQuantity: $checkedConvert(
        'seq_buy_quantity',
        (v) => (v as num?)?.toInt(),
      ),
      seqShelvesQuantity: $checkedConvert(
        'seq_shelves_quantity',
        (v) => (v as num?)?.toInt(),
      ),
      treasureId: $checkedConvert('treasure_id', (v) => v as String),
      treasureName: $checkedConvert('treasure_name', (v) => v as String),
      unitAmount: $checkedConvert('unit_amount', (v) => (v as num).toDouble()),
      treasureCoverImg: $checkedConvert(
        'treasure_cover_img',
        (v) => v as String?,
      ),
      rate: $checkedConvert('rate', (v) => (v as num?)?.toInt()),
      ruleContent: $checkedConvert('rule_content', (v) => v as String?),
      desc: $checkedConvert('desc', (v) => v as String?),
      maxUnitCoins: $checkedConvert(
        'max_unit_coins',
        (v) => (v as num?)?.toDouble(),
      ),
      maxUnitAmount: $checkedConvert(
        'max_unit_amount',
        (v) => (v as num?)?.toInt(),
      ),
      maxPerBuyQuantity: $checkedConvert(
        'max_per_buy_quantity',
        (v) => (v as num?)?.toInt(),
      ),
      charityAmount: $checkedConvert(
        'charity_amount',
        (v) => (v as num?)?.toDouble(),
      ),
      treasureSeq: $checkedConvert('treasure_seq', (v) => v as String?),
      cashState: $checkedConvert('cash_state', (v) => (v as num?)?.toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'buyQuantityRate': 'buy_quantity_rate',
    'costAmount': 'cost_amount',
    'imgStyleType': 'img_style_type',
    'lotteryMode': 'lottery_mode',
    'lotteryTime': 'lottery_time',
    'mainImageList': 'main_image_list',
    'minBuyQuantity': 'min_buy_quantity',
    'productName': 'product_name',
    'seqBuyQuantity': 'seq_buy_quantity',
    'seqShelvesQuantity': 'seq_shelves_quantity',
    'treasureId': 'treasure_id',
    'treasureName': 'treasure_name',
    'unitAmount': 'unit_amount',
    'treasureCoverImg': 'treasure_cover_img',
    'ruleContent': 'rule_content',
    'maxUnitCoins': 'max_unit_coins',
    'maxUnitAmount': 'max_unit_amount',
    'maxPerBuyQuantity': 'max_per_buy_quantity',
    'charityAmount': 'charity_amount',
    'treasureSeq': 'treasure_seq',
    'cashState': 'cash_state',
  },
);

Map<String, dynamic> _$ProductListItemToJson(ProductListItem instance) =>
    <String, dynamic>{
      'buy_quantity_rate': instance.buyQuantityRate,
      'cost_amount': instance.costAmount,
      'img_style_type': instance.imgStyleType,
      'lottery_mode': instance.lotteryMode,
      'lottery_time': instance.lotteryTime,
      'main_image_list': instance.mainImageList,
      'min_buy_quantity': instance.minBuyQuantity,
      'product_name': instance.productName,
      'seq_buy_quantity': instance.seqBuyQuantity,
      'seq_shelves_quantity': instance.seqShelvesQuantity,
      'treasure_id': instance.treasureId,
      'treasure_name': instance.treasureName,
      'unit_amount': instance.unitAmount,
      'treasure_cover_img': instance.treasureCoverImg,
      'rate': instance.rate,
      'rule_content': instance.ruleContent,
      'desc': instance.desc,
      'max_unit_coins': instance.maxUnitCoins,
      'max_unit_amount': instance.maxUnitAmount,
      'max_per_buy_quantity': instance.maxPerBuyQuantity,
      'charity_amount': instance.charityAmount,
      'treasure_seq': instance.treasureSeq,
      'cash_state': instance.cashState,
    };

GroupItem _$GroupItemFromJson(Map<String, dynamic> json) => $checkedCreate(
  'GroupItem',
  json,
  ($checkedConvert) {
    final val = GroupItem(
      groupId: $checkedConvert('group_id', (v) => v as String),
      joinedNum: $checkedConvert('joined_num', (v) => (v as num).toInt()),
      leaderUsername: $checkedConvert('leader_username', (v) => v as String),
      leaderAvatar: $checkedConvert('leader_avatar', (v) => v as String),
      luckyWinnersCount: $checkedConvert(
        'lucky_winners_count',
        (v) => (v as num).toInt(),
      ),
      totalWinningTimes: $checkedConvert(
        'total_winning_times',
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
  },
  fieldKeyMap: const {
    'groupId': 'group_id',
    'joinedNum': 'joined_num',
    'leaderUsername': 'leader_username',
    'leaderAvatar': 'leader_avatar',
    'luckyWinnersCount': 'lucky_winners_count',
    'totalWinningTimes': 'total_winning_times',
  },
);

Map<String, dynamic> _$GroupItemToJson(GroupItem instance) => <String, dynamic>{
  'group_id': instance.groupId,
  'joined_num': instance.joinedNum,
  'leader_username': instance.leaderUsername,
  'leader_avatar': instance.leaderAvatar,
  'lucky_winners_count': instance.luckyWinnersCount,
  'total_winning_times': instance.totalWinningTimes,
  'users': instance.users,
};

GroupUser _$GroupUserFromJson(Map<String, dynamic> json) => $checkedCreate(
  'GroupUser',
  json,
  ($checkedConvert) {
    final val = GroupUser(
      userId: $checkedConvert('user_id', (v) => v as String),
      username: $checkedConvert('username', (v) => v as String),
      avatar: $checkedConvert('avatar', (v) => v as String),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      leaderUserId: $checkedConvert('leader_user_id', (v) => v as String),
      leaderUsername: $checkedConvert('leader_username', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'userId': 'user_id',
    'createdAt': 'created_at',
    'leaderUserId': 'leader_user_id',
    'leaderUsername': 'leader_username',
  },
);

Map<String, dynamic> _$GroupUserToJson(GroupUser instance) => <String, dynamic>{
  'user_id': instance.userId,
  'username': instance.username,
  'avatar': instance.avatar,
  'created_at': instance.createdAt.toIso8601String(),
  'leader_user_id': instance.leaderUserId,
  'leader_username': instance.leaderUsername,
};
