import 'package:json_annotation/json_annotation.dart';

part 'act_winners_month.g.dart';

@JsonSerializable()
class ActWinnersMonth {
  @JsonKey(name: "treasure_id")
  final int treasureId;
  @JsonKey(name: 'treasure_name')
  final String treasureName;
  @JsonKey(name: 'main_image_list')
  final List<String>? mainImageList;
  @JsonKey(name: 'winner_name')
  final String winnerName;
  @JsonKey(name: 'award_number')
  final int awardNumber;
  @JsonKey(name: 'month')
  final int month;
  @JsonKey(name: 'lottery_time')
  final int lotteryTime;

  /// The following fields are not included in JSON serialization/deserialization
  /// and are used for UI purposes only
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool? firstOfDay;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool? lastOfDay;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? dateTitle;

  const ActWinnersMonth({
    required this.treasureId,
    required this.treasureName,
    this.mainImageList,
    required this.winnerName,
    required this.awardNumber,
    required this.month,
    required this.lotteryTime,
    this.firstOfDay,
    this.lastOfDay,
    this.dateTitle,
  });

  ActWinnersMonth copyWith({
    int? treasureId,
    String? treasureName,
    List<String>? mainImageList,
    String? winnerName,
    int? awardNumber,
    int? month,
    int? lotteryTime,
    bool? firstOfDay,
    bool? lastOfDay,
    String? dateTitle,
  }) {
    return ActWinnersMonth(
      treasureId: treasureId ?? this.treasureId,
      treasureName: treasureName ?? this.treasureName,
      mainImageList: mainImageList ?? this.mainImageList,
      winnerName: winnerName ?? this.winnerName,
      awardNumber: awardNumber ?? this.awardNumber,
      month: month ?? this.month,
      lotteryTime: lotteryTime ?? this.lotteryTime,
      firstOfDay: firstOfDay ?? this.firstOfDay,
      lastOfDay: lastOfDay ?? this.lastOfDay,
      dateTitle: dateTitle ?? this.dateTitle,
    );
  }

  factory ActWinnersMonth.fromJson(Map<String, dynamic> json) => _$ActWinnersMonthFromJson(json);

  Map<String, dynamic> toJson() => _$ActWinnersMonthToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// Parameters for fetching monthly activity winners
/// month: Month (1-12)
/// current: Current page number
/// size: Number of items per page
class ActWinnersMonthParams {
  final int month;
  final int current;
  final int size;

  const ActWinnersMonthParams({
    required this.month,
    required this.current,
    required this.size,
  });
}