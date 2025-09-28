import 'package:flutter_app/core/models/clickable_resource.dart';
import 'package:json_annotation/json_annotation.dart';
part 'banners.g.dart';

@JsonSerializable(checked: true)
class Banners implements ClickableResource {
  final int id;
  @JsonKey(name: "banner_cate")
  final int? bannerCate;
  @JsonKey(name: "banner_img_url")
  final String bannerImgUrl;
  @override
  @JsonKey(name: "video_url")
  final String? videoUrl;
  @override
  @JsonKey(name: "jump_cate")
  final int jumpCate;
  @override
  @JsonKey(name: "related_title_id")
  final int relatedTitleId;
  final int state;
  @JsonKey(name: "sort_order")
  final int sortOrder;
  @override
  @JsonKey(name: "jump_url")
  final String jumpUrl;

   Banners({
    required this.id,
     this.bannerCate,
    required this.bannerImgUrl,
    this.videoUrl,
    required this.jumpCate,
    required this.relatedTitleId,
    required this.state,
    required this.sortOrder,
    required this.jumpUrl,
  });

   factory Banners.fromJson(Map<String, dynamic> json) => _$BannersFromJson(json);
   Map<String, dynamic> toJson() => _$BannersToJson(this);
}