import 'package:json_annotation/json_annotation.dart';

import 'clickable_resource.dart';

part 'ad_res.g.dart';

@JsonSerializable(checked: true)
class AdRes implements ClickableResource {
  @JsonKey(name: 'banner_cate')
  final int? bannerCate;
  final String img;
  @override
  @JsonKey(name: 'video_url')
  final String? videoUrl; // 视频地址
  @JsonKey(name: 'grid_id')
  final int gridId;
  @JsonKey(name: 'id')
  final int id;
  @override
  @JsonKey(name: 'jump_cate')
  final int jumpCate; // 1 | 2 | 3 | 4; // 跳转类型: 1 - 无跳转 2 - 外部链接 3 - 跳转夺宝
  @override
  @JsonKey(name: 'jump_url')
  final String jumpUrl;
  @JsonKey(name: 'position')
  final int? position; //1 | 2 | 3; // 1 左侧 2右上 3右下
  @override
  @JsonKey(name: 'related_title_id')
  final int relatedTitleId;
  @JsonKey(name: 'sort_order')
  final int sortOrder;
  @JsonKey(name: 'sort_type')
  @JsonKey(name: 'sort_type')
  final int sortType; // 1 | 2; // 1:焦点排版 2:网格排版
  @JsonKey(name: 'state')
  final int state; // 1 | 2; // 1开启,2关闭,
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
    required this.state,
     this.bannerArray,
  });

  factory AdRes.fromJson(Map<String, dynamic> json) => _$AdResFromJson(json);
  Map<String, dynamic> toJson() => _$AdResToJson(this);
}

@JsonSerializable(checked: true)
class BannerItem {
  @JsonKey(name: 'activity_at_start')
  final int activityAtStart;
  @JsonKey(name: 'activity_at_end')
  final int activityAtEnd;
  @JsonKey(name: 'created_at')
  final int createdAt;
  @JsonKey(name: 'created_by')
  final String createdBy;
  @JsonKey(name: 'grid_id')
  final int gridId;
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
  final int relatedTitleId;
  @JsonKey(name: 'sort_order')
  final int sortOrder;
  @JsonKey(name: 'sort_type')
  final int sortType; // 1 | 2; // 1:焦点排版 2:网格排版
  @JsonKey(name: 'start_at')
  final int startAt;
  @JsonKey(name: 'position')
  final int? position; // 1 | 2 | 3; // 1 左侧 2右上 3右下
  @JsonKey(name: 'state')
  final int state; // 1 | 2; // 1开启,2关闭,
  @JsonKey(name: 'title')
  final String title;
  @JsonKey(name: 'updated_at')
  final int updatedAt;
  @JsonKey(name: 'updated_by')
  final String updatedBy;
  @JsonKey(name: 'valid_state')
  final int validState;

  BannerItem({
    required this.activityAtStart,
    required this.activityAtEnd,
    required this.createdAt,
    required this.createdBy,
    required this.gridId,
    required this.img,
    required this.imgStyleType,
    required this.videoUrl,
    required this.jumpCate,
    required this.jumpUrl,
    required this.relatedTitleId,
    required this.sortOrder,
    required this.sortType,
    required this.startAt,
     this.position,
    required this.state,
    required this.title,
    required this.updatedAt,
    required this.updatedBy,
    required this.validState,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) => _$BannerItemFromJson(json);
  Map<String, dynamic> toJson() => _$BannerItemToJson(this);

}