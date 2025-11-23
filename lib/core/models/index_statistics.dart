import 'package:json_annotation/json_annotation.dart';

part 'index_statistics.g.dart';

@JsonSerializable(checked: true)
class IndexStatistics {
  final int charityFundNum;
  final int totalAmount;
  final int totalUserAmount;

  IndexStatistics({
    required this.charityFundNum,
    required this.totalAmount,
    required this.totalUserAmount,
  });

  factory IndexStatistics.fromJson(Map<String, dynamic> json) => _$IndexStatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$IndexStatisticsToJson(this);
}