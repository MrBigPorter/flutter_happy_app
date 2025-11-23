import 'package:json_annotation/json_annotation.dart';

part 'winners_lasts_item.g.dart';

@JsonSerializable()
class WinnersLastsItem {
  final List<String>? mainImageList;
  final int treasureId;
  final String treasureName;
  final String? winnerName;
  final String? treasureCoverImg;

  const WinnersLastsItem({
    required this.mainImageList,
    required this.treasureId,
    required this.treasureName,
     this.winnerName,
    required this.treasureCoverImg,
  });

  factory WinnersLastsItem.fromJson(Map<String, dynamic> json) => _$WinnersLastsItemFromJson(json);

  Map<String, dynamic> toJson() => _$WinnersLastsItemToJson(this);

  @override
  String toString ()=> toJson().toString();

}