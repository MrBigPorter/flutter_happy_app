import 'package:json_annotation/json_annotation.dart';

part 'index_statistics.g.dart';

@JsonSerializable(checked: true)
class IndexStatistics {
  @JsonKey(name:"charity_fund_num")
  final int charityFundNum;
  @JsonKey(name:"total_amount")
  final int totalAmount;
  @JsonKey(name:"total_user_amount")
  final int totalUserAmount;

  IndexStatistics({
    required this.charityFundNum,
    required this.totalAmount,
    required this.totalUserAmount,
  });

  factory IndexStatistics.fromJson(Map<String, dynamic> json) => _$IndexStatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$IndexStatisticsToJson(this);
}