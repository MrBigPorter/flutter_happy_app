import 'package:json_annotation/json_annotation.dart';

part 'winners_lasts_item.g.dart';

@JsonSerializable()
class WinnersLastsItem {
  @JsonKey(name: 'main_image_list',defaultValue: [])
  final List<String>? mainImageList;
  @JsonKey(name: 'treasure_id',defaultValue: 0)
  final int treasureId;
  @JsonKey(name: 'treasure_name',defaultValue: '')
  final String treasureName;
  @JsonKey(name: 'winner_name',defaultValue: '')
  final String? winnerName;
  @JsonKey(name: 'treasure_cover_img',defaultValue: '')
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