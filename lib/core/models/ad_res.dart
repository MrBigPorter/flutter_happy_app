import 'package:json_annotation/json_annotation.dart';

import 'clickable_resource.dart';

part 'ad_res.g.dart';

@JsonSerializable(checked: true)
class AdRes implements ClickableResource {
  @JsonKey(name: 'banner_cate')
  final int? bannerCate;
  @JsonKey(name: 'img')
  final String? img;
  @override
  @JsonKey(name: 'video_url')
  final String? videoUrl; // 视频地址
  @JsonKey(name: 'grid_id')
  final int? gridId;
  @JsonKey(name: 'id')
  final String id;
  @JsonKey(name: 'file_type')
  final int fileType;
  @override
  @JsonKey(name: 'jump_cate')
  final int? jumpCate; // 1 | 2 | 3 | 4; // 跳转类型: 1 - 无跳转 2 - 外部链接 3 - 跳转夺宝
  @override
  @JsonKey(name: 'jump_url')
  final String? jumpUrl;
  @JsonKey(name: 'position')
  final int? position; //1 | 2 | 3; // 1 左侧 2右上 3右下
  @override
  @JsonKey(name: 'related_title_id')
  final String? relatedTitleId;
  @JsonKey(name: 'sort_order')
  final int sortOrder;
  @JsonKey(name: 'sort_type')
  final int sortType; // 1 | 2; // 1:焦点排版 2:网格排版
  @JsonKey(name: 'status')
  final int status; // 1 | 2; // 1开启,2关闭,
  @JsonKey(name: 'banner_array')
  final List<BannerItem>? bannerArray;

  AdRes({
    this.bannerCate,
    required this.img,
    required this.videoUrl,
    required this.gridId,
    required this.id,
    required this.jumpCate,
    required this.jumpUrl,
    this.position,
    required this.relatedTitleId,
    required this.sortOrder,
    required this.sortType,
    required this.status,
    this.bannerArray,
    required this.fileType,
  });

  factory AdRes.fromJson(Map<String, dynamic> json) => _$AdResFromJson(json);

  Map<String, dynamic> toJson() => _$AdResToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

@JsonSerializable(checked: true)
class BannerItem {
  @JsonKey(name: 'grid_id')
  final int? gridId;
  @JsonKey(name: 'img')
  final String img;
  @JsonKey(name: 'img_style_type')
  final int imgStyleType;
  @JsonKey(name: 'video_url')
  final String? videoUrl; // 视频地址
  @JsonKey(name: 'jump_cate')
  final int jumpCate; // 1 | 2 | 3 | 4;
  @JsonKey(name: 'jump_url')
  final String jumpUrl;
  @JsonKey(name: 'related_title_id')
  final String? relatedTitleId;
  @JsonKey(name: 'sort_order')
  final int? sortOrder;
  @JsonKey(name: 'sort_type')
  final int? sortType; // 1 | 2; // 1:焦点排版 2:网格排版
  @JsonKey(name: 'position')
  final int? position; // 1 | 2 | 3; // 1 左侧 2右上 3右下
  @JsonKey(name: 'status')
  final int? status; // 1 | 2; // 1开启,2关闭,
  @JsonKey(name: 'title')
  final String title;
  @JsonKey(name: 'valid_state')
  final int? validState;

  BannerItem({
    this.gridId,
    required this.img,
    required this.imgStyleType,
    this.videoUrl,
    required this.jumpCate,
    required this.jumpUrl,
    this.relatedTitleId,
    this.sortOrder,
    this.sortType,
    this.position,
    this.status,
    required this.title,
    this.validState,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) =>
      _$BannerItemFromJson(json);

  Map<String, dynamic> toJson() => _$BannerItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
