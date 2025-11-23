import 'package:flutter_app/core/models/clickable_resource.dart';
import 'package:json_annotation/json_annotation.dart';
part 'banners.g.dart';

@JsonSerializable(checked: true)
class Banners implements ClickableResource {
  final String id;
  final int? bannerCate;
  final String bannerImgUrl;
  @override
  final String? videoUrl;
  @override
  final int jumpCate;
  @override
  final String? relatedTitleId;
  final int state;
  final int sortOrder;
  @override
  final String? jumpUrl;

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

   @override
    String toString() {
     return toJson().toString();
   }
}