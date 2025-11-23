import 'package:json_annotation/json_annotation.dart';

import 'clickable_resource.dart';

part 'ad_res.g.dart';

@JsonSerializable(checked: true)
class AdRes implements ClickableResource {
  final int? bannerCate;
  final String? img;
  @override
  final String? videoUrl; // 视频地址
  final int? gridId;
  final String id;
  final int fileType;
  @override
  final int? jumpCate; // 1 | 2 | 3 | 4; // 跳转类型: 1 - 无跳转 2 - 外部链接 3 - 跳转夺宝
  @override
  final String? jumpUrl;
  final int? position; //1 | 2 | 3; // 1 左侧 2右上 3右下
  @override
  final String? relatedTitleId;
  final int sortOrder;
  final int sortType; // 1 | 2; // 1:焦点排版 2:网格排版
  final int status; // 1 | 2; // 1开启,2关闭,
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
  final int? gridId;
  final String img;
  final int imgStyleType;
  final String? videoUrl; // 视频地址
  final int jumpCate; // 1 | 2 | 3 | 4;
  final String jumpUrl;
  final String? relatedTitleId;
  final int? sortOrder;
  final int? sortType; // 1 | 2; // 1:焦点排版 2:网格排版
  final int? position; // 1 | 2 | 3; // 1 左侧 2右上 3右下
  final int? status; // 1 | 2; // 1开启,2关闭,
  final String title;
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
